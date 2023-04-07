//
// CreateEditItemTitleSection.swift
// Proton Pass - Created on 13/02/2023.
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

import ProtonCore_UIFoundations
import SwiftUI
import UIComponents

struct CreateEditItemTitleSection: View {
    var isFocused: FocusState<Bool>.Binding
    @Binding var title: String
    var onSubmit: (() -> Void)?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: kItemDetailSectionPadding / 4) {
                Text("Title")
                    .sectionTitleText()
                TextField("Untitled", text: $title)
                    .font(.title.weight(.bold))
                    .focused(isFocused)
                    .submitLabel(.next)
                    .foregroundColor(Color(uiColor: PassColor.textNorm))
                    .onSubmit { onSubmit?() }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if !title.isEmpty {
                Button(action: {
                    title = ""
                }, label: {
                    ItemDetailSectionIcon(icon: IconProvider.cross)
                })
            }
        }
        .padding(kItemDetailSectionPadding)
        .roundedEditableSection()
        .animation(.default, value: title.isEmpty)
    }
}
