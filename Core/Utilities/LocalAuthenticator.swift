//
// LocalAuthenticator.swift
// Proton Pass - Created on 21/10/2022.
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

import LocalAuthentication
import SwiftUI

public extension LocalAuthenticator {
    enum BiometryTypeState {
        case idle
        case initializing
        case initialized(LABiometryType)
        case error(Error)
    }

    enum AuthenticationState {
        case idle
        case authenticating
        case authenticated
        case error(Error)
    }
}

public enum LocalAuthenticatorError: Error {
    case biometryTypeNotInitialized
}

public final class LocalAuthenticator: ObservableObject {
    @Published public private(set) var biometryTypeState: BiometryTypeState = .idle
    @Published public private(set) var authenticationState: AuthenticationState = .idle
    @Published public var enabled = true {
        didSet {
            toggleEnabled()
        }
    }
    private let preferences: Preferences
    private let context = LAContext()
    private let policy = LAPolicy.deviceOwnerAuthentication // Both biometry & passcode
    private var tempEnabled = true

    public init(preferences: Preferences) {
        self.preferences = preferences
        self.tempEnabled = preferences.localAuthenticationEnabled
        self.enabled = preferences.localAuthenticationEnabled
    }

    public func initializeBiometryType() {
        biometryTypeState = .initializing
        var error: NSError?
        context.canEvaluatePolicy(policy, error: &error)
        if let error {
            biometryTypeState = .error(error)
        } else {
            biometryTypeState = .initialized(context.biometryType)
        }
    }

    public func authenticate(reason: String) async throws -> Bool {
        guard case .initialized = biometryTypeState else {
            throw LocalAuthenticatorError.biometryTypeNotInitialized
        }

        return try await context.evaluatePolicy(policy, localizedReason: reason)
    }

    public func toggleEnabled() {
        guard tempEnabled != enabled else { return }
        defer {
            preferences.localAuthenticationEnabled = enabled
        }
        Task { @MainActor in
            do {
                let reason = enabled ?
                "Please authenticate to enable local authentication" :
                "Please authenticate to disable local authentication"
                let authenticated = try await authenticate(reason: reason)
                if authenticated {
                    tempEnabled.toggle()
                } else {
                    enabled.toggle()
                }
            } catch {
                enabled.toggle()
                authenticationState = .error(error)
            }
        }
    }
}

public extension LABiometryType {
    struct UiModel {
        public let title: String
        public let icon: String?
    }

    var uiModel: UiModel? {
        switch self {
        case .faceID:
            return .init(title: "Face ID", icon: "faceid")
        case .touchID:
            return .init(title: "Touch ID", icon: "touchid")
        case .none:
            return .init(title: "Device passcode", icon: nil)
        default:
            return nil
        }
    }
}
