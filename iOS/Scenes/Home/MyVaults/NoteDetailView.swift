//
// NoteDetailView.swift
// Proton Pass - Created on 07/09/2022.
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

import ProtonCore_UIFoundations
import SwiftUI
import UIComponents

struct NoteDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: NoteDetailViewModel

    init(viewModel: NoteDetailViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            Group {
                if viewModel.note.isEmpty {
                    Text("Empty note")
                        .modifier(ItalicSecondaryTextStyle())
                } else {
                    Text(viewModel.note)
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .onTapGesture(perform: viewModel.copyNote)
                }
            }
            .padding(.vertical, 28)
            .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .navigationBarBackButtonHidden(true)
        .toolbar { toolbarContent }
        .alertToastInformativeMessage($viewModel.informativeMessage)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: dismiss.callAsFunction) {
                Image(uiImage: IconProvider.chevronLeft)
                    .foregroundColor(.primary)
            }
        }

        ToolbarItem(placement: .principal) {
            Text(viewModel.name)
                .fontWeight(.bold)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: viewModel.edit) {
                Text("Edit")
                    .foregroundColor(ColorProvider.InteractionNorm)
            }
        }
    }
}
