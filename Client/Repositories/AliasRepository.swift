//
// AliasRepository.swift
// Proton Pass - Created on 14/09/2022.
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

import Core
import CoreData
import ProtonCore_Networking
import ProtonCore_Services

public protocol AliasRepositoryProtocol {
    var localAliasDatasource: LocalAliasDatasourceProtocol { get }
    var remoteAliasDatasouce: RemoteAliasDatasourceProtocol { get }

    func getAliasOptions(shareId: String) async throws -> AliasOptions
}

public extension AliasRepositoryProtocol {
    func getAliasOptions(shareId: String) async throws -> AliasOptions {
        try await remoteAliasDatasouce.getAliasOptions(shareId: shareId)
    }
}

public struct AliasRepository: AliasRepositoryProtocol {
    public let localAliasDatasource: LocalAliasDatasourceProtocol
    public let remoteAliasDatasouce: RemoteAliasDatasourceProtocol

    public init(localAliasDatasource: LocalAliasDatasourceProtocol,
                remoteAliasDatasouce: RemoteAliasDatasourceProtocol) {
        self.localAliasDatasource = localAliasDatasource
        self.remoteAliasDatasouce = remoteAliasDatasouce
    }

    public init(container: NSPersistentContainer,
                authCredential: AuthCredential,
                apiService: APIService) {
        self.localAliasDatasource = LocalAliasDatasource(container: container)
        self.remoteAliasDatasouce = RemoteAliasDatasource(authCredential: authCredential,
                                                          apiService: apiService)
    }
}
