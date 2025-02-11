//
// AliasDetailViewModel.swift
// Proton Pass - Created on 15/09/2022.
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
import Combine
import Core
import Entities
import Factory
import Foundation
import Macro

@MainActor
final class AliasDetailViewModel: BaseItemDetailViewModel, DeinitPrintable {
    deinit { print(deinitMessage) }

    @Published private(set) var aliasEmail = ""
    @Published private(set) var name = ""
    @Published private(set) var note = ""
    @Published private(set) var mailboxes: [AliasLinkedMailbox]?
    @Published private(set) var error: (any Error)?
    @Published private(set) var aliasEnabled = false
    @Published private(set) var togglingAliasStatus = false

    @LazyInjected(\SharedRepositoryContainer.aliasRepository) private var aliasRepository
    @LazyInjected(\SharedServiceContainer.userManager) private var userManager
    @LazyInjected(\SharedUseCasesContainer.getFeatureFlagStatus) private var getFeatureFlagStatus

    var isSimpleLoginAliasSyncActive: Bool {
        getFeatureFlagStatus(with: FeatureFlagType.passSimpleLoginAliasesSync)
    }

    override func bindValues() {
        super.bindValues()
        aliasEmail = itemContent.item.aliasEmail ?? ""
        aliasEnabled = itemContent.item.isAliasEnabled
        if case .alias = itemContent.contentData {
            name = itemContent.name
            note = itemContent.note
        } else {
            fatalError("Expecting alias type")
        }
    }

    func getAlias() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let alias =
                    try await aliasRepository.getAliasDetails(shareId: itemContent.shareId,
                                                              itemId: itemContent.item.itemID)
                aliasEmail = alias.email
                mailboxes = alias.mailboxes
                aliasEnabled = itemContent.item.isAliasEnabled
                logger.info("Get alias detail successfully \(itemContent.debugDescription)")
            } catch {
                logger.error(error)
                self.error = error
            }
        }
    }

    func toggleAliasState() {
        setAliasStatus(enabled: !aliasEnabled)
    }

    func disableAlias() {
        setAliasStatus(enabled: false)
    }

    override func refresh() {
        mailboxes = nil
        error = nil
        super.refresh()
        getAlias()
    }

    func copyAliasEmail() {
        copyToClipboard(text: aliasEmail, message: #localized("Alias copied"))
    }

    func copyMailboxEmail(_ email: String) {
        copyToClipboard(text: email, message: #localized("Email address copied"))
    }
}

private extension AliasDetailViewModel {
    func setAliasStatus(enabled: Bool) {
        Task { [weak self] in
            guard let self else { return }
            defer { togglingAliasStatus = false }
            do {
                togglingAliasStatus = true
                let userId = try await userManager.getActiveUserId()
                try await itemRepository.changeAliasStatus(userId: userId,
                                                           item: itemContent,
                                                           enabled: enabled)
                let message = if enabled {
                    #localized("Alias enabled")
                } else {
                    #localized("Alias disabled")
                }
                router.display(element: .infosMessage(message, config: .refresh))
                logger.trace("Successfully updated the alias status of \(enabled)")
                aliasEnabled = enabled
            } catch {
                logger.error(error)
                self.error = error
            }
        }
    }
}
