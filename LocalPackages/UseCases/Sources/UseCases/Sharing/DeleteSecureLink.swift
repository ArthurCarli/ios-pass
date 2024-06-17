//
//
// DeleteSecureLink.swift
// Proton Pass - Created on 11/06/2024.
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

public protocol DeleteSecureLinkUseCase: Sendable {
    func execute(linkId: String) async throws
}

public extension DeleteSecureLinkUseCase {
    func callAsFunction(linkId: String) async throws {
        try await execute(linkId: linkId)
    }
}

public final class DeleteSecureLink: DeleteSecureLinkUseCase {
    private let datasource: any RemoteSecureLinkDatasourceProtocol
    private let manager: any SecureLinkManagerProtocol

    public init(datasource: any RemoteSecureLinkDatasourceProtocol,
                manager: any SecureLinkManagerProtocol) {
        self.datasource = datasource
        self.manager = manager
    }

    public func execute(linkId: String) async throws {
        try await datasource.deleteLink(linkId: linkId)
        try await manager.updateSecureLinks()
    }
}
