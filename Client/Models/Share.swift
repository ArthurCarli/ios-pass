//
// Share.swift
// Proton Pass - Created on 11/07/2022.
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
import GoLibs
import ProtonCore_Crypto
import ProtonCore_DataModel
import ProtonCore_KeyManager
import ProtonCore_Login
import ProtonCore_Utilities

public enum ShareType: Int16 {
    case unknown = 0
    case vault = 1
    case item = 2
}

public enum ShareContent {
    case vault(VaultProtocol)
    case item // Not handled yet
}

public struct Share: Decodable {
    /// ID of the share
    public let shareID: String

    /// ID of the vault this share belongs to
    public let vaultID: String

    /// User address ID that has access to this share
    public let addressID: String

    /// Type of share. 1 for vault, 2 for label and 3 for item
    public let targetType: Int16

    /// ID of the top shared object
    public let targetID: String

    /// Permissions for this share
    public let permission: Int16

    /// Base64 encoded encrypted content of the share. Can be null for item shares
    public let content: String?

    public let contentKeyRotation: Int16?

    /// Version of the content's format
    public let contentFormatVersion: Int16?

    /// Expiration time for this share
    public let expireTime: Int64?

    /// Time of creation of this share
    public let createTime: Int64

    public var shareType: ShareType {
        .init(rawValue: targetType) ?? .unknown
    }
}

public extension Share {
    func getShareContent(userData: UserData, shareKeys: [ShareKey]) throws -> ShareContent {
        switch shareType {
        case .unknown:
            throw PPClientError.unknownShareType
        case .vault:
            let vaultContent = try VaultProtobuf(data: Data())
            let vault = Vault(id: vaultID,
                              shareId: shareID,
                              name: vaultContent.name,
                              description: vaultContent.description_p)
            return .vault(vault)
        case .item:
            return .item
        }
    }
}
