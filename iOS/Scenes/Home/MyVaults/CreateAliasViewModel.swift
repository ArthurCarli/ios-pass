//
// CreateAliasViewModel.swift
// Proton Pass - Created on 05/08/2022.
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

import Client
import Core
import ProtonCore_Login

final class CreateAliasViewModel: BaseViewModel, DeinitPrintable, ObservableObject {
    deinit { print(deinitMessage) }

    let mode: ItemMode
    let userData: UserData
    let shareRepository: ShareRepositoryProtocol
    let shareKeysRepository: ShareKeysRepositoryProtocol
    let itemRevisionRepository: ItemRevisionRepositoryProtocol
    let aliasRepository: AliasRepositoryProtocol

    init(mode: ItemMode,
         userData: UserData,
         shareRepository: ShareRepositoryProtocol,
         shareKeysRepository: ShareKeysRepositoryProtocol,
         itemRevisionRepository: ItemRevisionRepositoryProtocol,
         aliasRepository: AliasRepositoryProtocol) {
        self.mode = mode
        self.userData = userData
        self.shareRepository = shareRepository
        self.shareKeysRepository = shareKeysRepository
        self.itemRevisionRepository = itemRevisionRepository
        self.aliasRepository = aliasRepository
        super.init()
        bindValues()
    }

    private func bindValues() {
        switch mode {
        case .create(let shareId):
            getAliasOptions(shareId: shareId)
        case .edit(let itemContent):
            break
        }
    }

    private func getAliasOptions(shareId: String) {
        Task { @MainActor in
            do {
                isLoading = true
                let options = try await aliasRepository.getAliasOptions(shareId: shareId)
                isLoading = false
                print(options)
            } catch {
                self.isLoading = false
                self.error = error
            }
        }
    }

    func save() {}
}
