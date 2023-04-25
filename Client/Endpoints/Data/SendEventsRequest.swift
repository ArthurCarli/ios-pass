//
// SendEventsRequest.swift
// Proton Pass - Created on 17/04/2023.
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

import Foundation

struct SendEventsRequest: Encodable {
    let eventInfo: [EventInfo]

    enum CodingKeys: String, CodingKey {
        case eventInfo = "EventInfo"
    }
}

public struct EventInfo: Encodable {
    let measurementGroup: String
    let event: String
    let dimensions: Dimensions

    enum CodingKeys: String, CodingKey {
        case measurementGroup = "MeasurementGroup"
        case event = "Event"
        case dimensions = "Dimensions"
    }

    struct Dimensions: Encodable {
        let type: String?
        let location: String?
        let userTier: String

        enum CodingKeys: String, CodingKey {
            case type = "type"
            case location = "location"
            case userTier = "user_tier"
        }

        init(type: String?, location: String?, userTier: String) {
            self.type = type
            self.location = location
            self.userTier = userTier
        }
    }

    init(measurementGroup: String, event: String, dimensions: Dimensions) {
        self.measurementGroup = measurementGroup
        self.event = event
        self.dimensions = dimensions
    }
}

public extension EventInfo {
    init(event: TelemetryEvent, userPlan: UserPlan) {
        self.measurementGroup = "pass.any.user_actions"
        self.event = event.eventName
        self.dimensions = .init(type: event.dimensionType,
                                location: event.dimensionLocation,
                                userTier: userPlan.userTier)
    }
}

private extension TelemetryEvent {
    var eventName: String {
        switch type {
        case .create:
            return "item.creation"
        case .read:
            return "item.read"
        case .update:
            return "item.update"
        case .delete:
            return "item.deletion"
        case .autofillDisplay:
            return "autofill.display"
        case .autofillTriggeredFromApp, .autofillTriggeredFromSource:
            return "autofill.triggered"
        case .searchClick:
            return "search.click"
        case .searchTriggered:
            return "search.triggered"
        }
    }

    var dimensionType: String? {
        switch type {
        case .create(let itemContentType):
            return itemContentType.dimensionType
        case .read(let itemContentType):
            return itemContentType.dimensionType
        case .update(let itemContentType):
            return itemContentType.dimensionType
        case .delete(let itemContentType):
            return itemContentType.dimensionType
        case .autofillDisplay,
                .autofillTriggeredFromSource,
                .autofillTriggeredFromApp,
                .searchClick,
                .searchTriggered:
            return nil
        }
    }

    var dimensionLocation: String? {
        switch type {
        case .autofillTriggeredFromSource:
            return "source"
        case .autofillTriggeredFromApp:
            return "app"
        case .create,
                .read,
                .update,
                .delete,
                .autofillDisplay,
                .searchClick,
                .searchTriggered:
            return nil
        }
    }
}

private extension ItemContentType {
    var dimensionType: String {
        switch self {
        case .login:
            return "login"
        case .alias:
            return "alias"
        case .note:
            return "note"
        }
    }
}

private extension UserPlan {
    var userTier: String {
        switch self {
        case .free:
            return "free"
        case .paid(let plan):
            return plan.name
        case .subUser:
            return "subuser"
        }
    }
}
