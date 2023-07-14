//
// CheckBiometryType.swift
// Proton Pass - Created on 13/07/2023.
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

import Factory

@preconcurrency import LocalAuthentication

/// Determine the supported `LABiometryType` of the device
protocol CheckBiometryTypeUseCase: Sendable {
    func execute() throws -> LABiometryType
}

extension CheckBiometryTypeUseCase {
    func callAsFunction() throws -> LABiometryType {
        try execute()
    }
}

final class CheckBiometryType: CheckBiometryTypeUseCase {
    private let context = resolve(\SharedToolingContainer.localAuthenticationContext)
    private let policy = resolve(\SharedToolingContainer.localAuthenticationPolicy)

    init() {}

    func execute() throws -> LABiometryType {
        var error: NSError?
        context.canEvaluatePolicy(policy, error: &error)
        if let error {
            throw error
        } else {
            return context.biometryType
        }
    }
}
