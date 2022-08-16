//
// BaseLocalDatasource.swift
// Proton Pass - Created on 13/08/2022.
// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of Proton Pass.
//
// Proton Pass is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Pass is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Pass. If not, see https://www.gnu.org/licenses/.

import CoreData

public let kProtonPassContainerName = "ProtonPass"

public enum LocalDatasourceError: Error, CustomDebugStringConvertible {
    case batchInsertError(NSBatchInsertRequest)
    case batchDeleteError(NSBatchDeleteRequest)
    case corruptedShareKeys(shareId: String, itemKeyCount: Int, vaultKeyCount: Int)

    public var debugDescription: String {
        switch self {
        case .batchInsertError(let request):
            return "Failed to batch insert entity \(request.entityName)"
        case .batchDeleteError(let request):
            let entityName = request.fetchRequest.entityName ?? ""
            return "Failed to batch delete entity \(entityName)"
        case let .corruptedShareKeys(shareId, itemKeyCount, vaultKeyCount):
            return """
"Corrupted share keys for share \(shareId).
Item key count (\(itemKeyCount)) not equal to vault key count (\(vaultKeyCount)
"""
        }
    }
}

public class BaseLocalDatasource {
    let container: NSPersistentContainer

    public init(container: NSPersistentContainer) {
        guard container.name == kProtonPassContainerName else {
            fatalError("Unsupported container name \(container.name)")
        }
        self.container = container
    }

    enum TaskContextType: String {
        case insert = "insertContext"
        case delete = "deleteContext"
        case fetch = "fetchContext"
    }

    /// Creates and configures a private queue context.
    func newTaskContext(type: TaskContextType,
                        transactionAuthor: String = #function) -> NSManagedObjectContext {
        let taskContext = container.newBackgroundContext()
        taskContext.name = type.rawValue
        taskContext.transactionAuthor = transactionAuthor
        taskContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        // Set unused undoManager to nil for macOS (it is nil by default on iOS)
        // to reduce resource requirements.
        taskContext.undoManager = nil
        return taskContext
    }

    func newBatchInsertRequest<T>(entity: NSEntityDescription,
                                  sourceItems: [T],
                                  hydrateBlock: @escaping (NSManagedObject, T) -> Void)
    -> NSBatchInsertRequest {
        var index = 0
        let request = NSBatchInsertRequest(entity: entity,
                                           managedObjectHandler: { object in
            guard index < sourceItems.count else { return true }
            let item = sourceItems[index]
            hydrateBlock(object, item)
            index += 1
            return false
        })
        return request
    }
}

// MARK: - Covenience core data methods
extension BaseLocalDatasource {
    func execute(batchInsertRequest request: NSBatchInsertRequest,
                 context: NSManagedObjectContext) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) -> Void in
            context.performAndWait {
                do {
                    let fetchResult = try context.execute(request)
                    if let result = fetchResult as? NSBatchInsertResult,
                       let success = result.result as? Bool, success {
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: LocalDatasourceError.batchInsertError(request))
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func execute(batchDeleteRequest request: NSBatchDeleteRequest,
                 context: NSManagedObjectContext) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) -> Void in
            context.performAndWait {
                do {
                    request.resultType = .resultTypeStatusOnly
                    let deleteResult = try context.execute(request)
                    if let result = deleteResult as? NSBatchDeleteResult,
                       let success = result.result as? Bool, success {
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: LocalDatasourceError.batchDeleteError(request))
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func execute<T>(fetchRequest request: NSFetchRequest<T>,
                    context: NSManagedObjectContext) async throws -> [T] {
        try await withCheckedThrowingContinuation { continuation in
            context.performAndWait {
                do {
                    let result = try context.fetch(request)
                    continuation.resume(with: .success(result))
                } catch {
                    continuation.resume(with: .failure(error))
                }
            }
        }
    }

    func count<T>(fetchRequest request: NSFetchRequest<T>,
                  context: NSManagedObjectContext) async throws -> Int {
        try await withCheckedThrowingContinuation { continuation in
            context.performAndWait {
                do {
                    let result = try context.count(for: request)
                    continuation.resume(with: .success(result))
                } catch {
                    continuation.resume(with: .failure(error))
                }
            }
        }
    }
}

extension NSManagedObject {
    /*
     Such helper function is due to a very strange 🐛 that makes
     unit tests failed out of the blue because `CoreDataEntityName.entity()`
     failed to return a non-null NSEntityDescription.
     `CoreDataEntityName.entity()` used to work for a while until
     it stops working on some machines. Not a reproducible 🐛
     */
    class func entity(context: NSManagedObjectContext) -> NSEntityDescription {
        // swiftlint:disable:next force_unwrapping
        .entity(forEntityName: "\(Self.self)", in: context)!
    }
}
