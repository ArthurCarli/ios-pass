//
// TrashView.swift
// Proton Pass - Created on 07/07/2022.
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

struct TrashView: View {
    @StateObject private var viewModel: TrashViewModel
    @State private var isShowingEmptyTrashAlert = false

    init(viewModel: TrashViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            Color.clear
            switch viewModel.state {
            case .idle:
                EmptyView()

            case .loading:
                ProgressView()

            case .loaded(let uiModels):
                if uiModels.isEmpty {
                    EmptyTrashView()
                } else {
                    itemList(uiModels)
                }

            case .error(let error):
                RetryableErrorView(errorMessage: error.messageForTheUser,
                                   onRetry: { viewModel.fetchAllTrashedItems(forceRefresh: true) })
            }
        }
        .toolbar { toolbarContent }
        .alert(isPresented: $isShowingEmptyTrashAlert) { emptyTrashAlert }
        .alertToastSuccessMessage($viewModel.successMessage)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            ToggleSidebarButton(action: viewModel.toggleSidebar)
        }

        ToolbarItem(placement: .principal) {
            Text("Trash")
                .fontWeight(.bold)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            Menu(content: {
                Button(action: viewModel.restoreAllItems) {
                    Label(title: {
                        Text("Restore all items")
                    }, icon: {
                        Image(uiImage: IconProvider.clockRotateLeft)
                    })
                }

                DestructiveButton(title: "Empty trash",
                                  icon: IconProvider.trashCross) {
                    isShowingEmptyTrashAlert.toggle()
                }
            }, label: {
                Image(uiImage: IconProvider.threeDotsHorizontal)
                    .foregroundColor(Color(.label))
            })
            .opacity(viewModel.state.isEmpty ? 0 : 1)
            .disabled(viewModel.state.isEmpty)
        }
    }

    private var emptyTrashAlert: Alert {
        Alert(title: Text("Empty trash?"),
              message: Text("Items in trash will be deleted permanently. You can not undo this action."),
              primaryButton: .destructive(Text("Empty trash"), action: viewModel.emptyTrash),
              secondaryButton: .cancel())
    }

    private func itemList(_ uiModels: [ItemListUiModel]) -> some View {
        ScrollView {
            LazyVStack {
                ForEach(uiModels, id: \.itemId) { uiModel in
                    GenericItemView(
                        item: uiModel,
                        showDivider: uiModel.itemId != uiModels.last?.itemId,
                        action: {  },
                        trailingView: {
                            Button(action: {
//                                viewModel.showOptions(item)
                            }, label: {
                                Image(uiImage: IconProvider.threeDotsHorizontal)
                                    .foregroundColor(.secondary)
                            })
                        })
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                Spacer()
            }
        }
    }
}
