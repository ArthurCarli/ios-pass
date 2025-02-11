// Generated using Sourcery 2.2.4 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
// Proton Pass.
// Copyright (c) 2023 Proton Technologies AG
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

public final class LocalDataMigrationDatasourceProtocolMock: @unchecked Sendable, LocalDataMigrationDatasourceProtocol {
    private var currentMigrations = 0
    
    public init(currentMigrations: MigrationStatus = 0) {
        self.currentMigrations = currentMigrations
    }
    
    public func getMigrations() async -> MigrationStatus {
        return currentMigrations
    }

    public func upsert(migrations: MigrationStatus) async {
        currentMigrations = migrations
    }
}
