//
//
// GetAllAliases.swift
// Proton Pass - Created on 17/04/2024.
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

import Client
import Entities

public struct SuggestedEmail: Sendable {
    public let email: String
    public let count: Int
}

public protocol GetAllAliasesUseCase: Sendable {
    func execute() async throws -> [ItemContent]
}

public extension GetAllAliasesUseCase {
    func callAsFunction() async throws -> [ItemContent] {
        try await execute()
    }
}

public final class GetAllAliases: GetAllAliasesUseCase {
    private let itemRepository: any ItemRepositoryProtocol

    public init(itemRepository: any ItemRepositoryProtocol) {
        self.itemRepository = itemRepository
    }

    public func execute() async throws -> [ItemContent] {
        try await itemRepository.getAllItemContents().filter { $0.contentData == .alias }
    }
}

public struct AliasMonitorInfo: Sendable, Identifiable {
    public let alias: ItemContent
    public let breaches: EmailBreaches?

    public var id: String {
        alias.id
    }
}

public protocol GetAllCustomEmailsUseCase: Sendable {
    func execute() async throws -> [CustomEmail]
}

public extension GetAllCustomEmailsUseCase {
    func callAsFunction() async throws -> [CustomEmail] {
        try await execute()
    }
}

public final class GetAllCustomEmails: GetAllCustomEmailsUseCase {
    private let repository: any BreachRepositoryProtocol

    public init(repository: any BreachRepositoryProtocol) {
        self.repository = repository
    }

    public func execute() async throws -> [CustomEmail] {
        try await repository.getAllCustomEmailForUser()
    }
}

public protocol GetCustomEmailSuggestionUseCase: Sendable {
    func execute(breaches: UserBreaches) async throws -> [SuggestedEmail]
}

public extension GetCustomEmailSuggestionUseCase {
    func callAsFunction(breaches: UserBreaches) async throws -> [SuggestedEmail] {
        try await execute(breaches: breaches)
    }
}

public final class GetCustomEmailSuggestion: GetCustomEmailSuggestionUseCase {
    private let itemRepository: any ItemRepositoryProtocol
    private let symmetricKeyProvider: any SymmetricKeyProvider
    private let validateEmailUseCase: any ValidateEmailUseCase

    public init(itemRepository: any ItemRepositoryProtocol,
                symmetricKeyProvider: any SymmetricKeyProvider,
                validateEmailUseCase: any ValidateEmailUseCase) {
        self.itemRepository = itemRepository
        self.symmetricKeyProvider = symmetricKeyProvider
        self.validateEmailUseCase = validateEmailUseCase
    }

    public func execute(breaches: UserBreaches) async throws -> [SuggestedEmail] {
        let symmetricKey = try symmetricKeyProvider.getSymmetricKey()

        let emails = try await itemRepository.getActiveLogInItems()
            .compactMap { encryptedItem -> String? in
                guard let item = try? encryptedItem.getItemContent(symmetricKey: symmetricKey),
                      let loginItem = item.loginItem,
                      validateEmailUseCase(email: loginItem.username),
                      !loginItem.username.contains("proton."),
                      !breaches.customEmails.map(\.email).contains(loginItem.username)
                else {
                    return nil
                }
                return loginItem.username
            }

        let counts = countOccurrences(of: emails)
        let sortedCounts = counts.sorted { $0.value > $1.value }
            .map { SuggestedEmail(email: $0.key, count: $0.value) }
        return Array(sortedCounts.prefix(3))
    }

    func countOccurrences(of array: [String]) -> [String: Int] {
        var counts = [String: Int]()

        for element in array {
            counts[element, default: 0] += 1
        }

        return counts
    }
}

public extension Int {
    func isFlagActive(_ flag: ItemFlags) -> Bool {
        (self & flag.intValue) != 0
    }

    func areAllFlagsActive(_ flagsToCheck: [ItemFlags]) -> Bool {
        for flag in flagsToCheck where (self & flag.intValue) == 0 {
            return false // If any flag is not set, return false
        }
        return true // All flags are set
    }

    func isAnyFlagActive(_ flagsToCheck: [ItemFlags]) -> Bool {
        for flag in flagsToCheck where (self & flag.intValue) != 0 {
            return true // If any flag is set, return true
        }
        return false // No flags are set
    }
}
