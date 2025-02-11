//
// LocalOrganizationDatasource.swift
// Proton Pass - Created on 19/03/2024.
// Copyright (c) 2024 Proton Technologies AG
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
//

import CoreData
import Entities
import Foundation

public protocol LocalOrganizationDatasourceProtocol: Sendable {
    func getOrganization(userId: String) async throws -> Organization?
    func upsertOrganization(_ organization: Organization, userId: String) async throws
    // periphery:ignore
    func removeOrganization(userId: String) async throws
}

public final class LocalOrganizationDatasource: LocalDatasource, LocalOrganizationDatasourceProtocol {}

public extension LocalOrganizationDatasource {
    func getOrganization(userId: String) async throws -> Organization? {
        let taskContext = newTaskContext(type: .fetch)
        let fetchRequest = OrganizationEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "userID = %@", userId)
        let entities = try await execute(fetchRequest: fetchRequest, context: taskContext)
        assert(entities.count <= 1, "Can not have more than 1 organization per userId")
        return entities.first?.toOrganization
    }

    func upsertOrganization(_ organization: Organization, userId: String) async throws {
        try await upsert([organization],
                         entityType: OrganizationEntity.self,
                         fetchPredicate: NSPredicate(format: "userID == %@", userId),
                         isEqual: { _, entity in
                             entity.userID == userId
                         },
                         hydrate: { item, entity in
                             entity.hydrate(from: item, userId: userId)
                         })
    }

    func removeOrganization(userId: String) async throws {
        let taskContext = newTaskContext(type: .delete)
        let fetchRequest = NSFetchRequest<any NSFetchRequestResult>(entityName: "OrganizationEntity")
        fetchRequest.predicate = NSPredicate(format: "userID = %@", userId)
        try await execute(batchDeleteRequest: .init(fetchRequest: fetchRequest),
                          context: taskContext)
    }
}
