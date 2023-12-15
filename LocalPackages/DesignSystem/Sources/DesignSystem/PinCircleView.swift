//
// PinCircleView.swift
// Proton Pass - Created on 14/12/2023.
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

import SwiftUI

public struct PinCircleView: View {
    let tintColor: UIColor
    let height: CGFloat

    public init(tintColor: UIColor, height: CGFloat) {
        self.tintColor = tintColor
        self.height = height
    }

    public var body: some View {
        ZStack {
            tintColor.toColor
                .clipShape(Circle())
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Image(systemName: "pin.fill")
                .resizable()
                .scaledToFit()
                .frame(height: height * 3 / 5)
                .offset(y: height / 14)
                .foregroundStyle(PassColor.textInvert.toColor)
                .rotationEffect(.degrees(45))
        }
        .frame(width: height, height: height)
    }
}
