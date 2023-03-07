//
// MyVaultsCoordinator.swift
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

import Client
import Core
import CryptoKit
import ProtonCore_Login
import SwiftUI
import UIComponents

protocol MyVaultsCoordinatorDelegate: AnyObject {
    func myVaultsCoordinatorWantsToRefreshTrash()
}

final class MyVaultsCoordinator: Coordinator {
    private let symmetricKey: SymmetricKey
    private let userData: UserData
    private let vaultSelection: VaultSelection
    private let vaultContentViewModel: VaultContentViewModel
    private let shareRepository: ShareRepositoryProtocol
    private let itemRepository: ItemRepositoryProtocol
    private let credentialManager: CredentialManagerProtocol
    private let aliasRepository: AliasRepositoryProtocol
    private let myVaultsViewModel: MyVaultsViewModel
    private let preferences: Preferences
    private let manualLogIn: Bool
    private let logManager: LogManager

    private var currentItemDetailViewModel: BaseItemDetailViewModel?
    private var currentCreateEditItemViewModel: BaseCreateEditItemViewModel?
    private var searchViewModel: SearchViewModel?

    weak var itemCountDelegate: ItemCountDelegate? {
        didSet {
            vaultContentViewModel.itemCountDelegate = itemCountDelegate
        }
    }

    weak var delegate: MyVaultsCoordinatorDelegate?
    weak var bannerManager: BannerManager?
    weak var clipboardManager: ClipboardManager?
    weak var urlOpener: UrlOpener?

    init(symmetricKey: SymmetricKey,
         userData: UserData,
         vaultSelection: VaultSelection,
         shareRepository: ShareRepositoryProtocol,
         itemRepository: ItemRepositoryProtocol,
         aliasRepository: AliasRepositoryProtocol,
         publicKeyRepository: PublicKeyRepositoryProtocol,
         credentialManager: CredentialManagerProtocol,
         syncEventLoop: SyncEventLoop,
         preferences: Preferences,
         manualLogIn: Bool,
         logManager: LogManager) {
        self.symmetricKey = symmetricKey
        self.userData = userData
        self.vaultSelection = vaultSelection
        self.shareRepository = shareRepository
        self.itemRepository = itemRepository
        self.credentialManager = credentialManager
        self.aliasRepository = aliasRepository
        self.vaultContentViewModel = .init(vaultSelection: vaultSelection,
                                           itemRepository: itemRepository,
                                           credentialManager: credentialManager,
                                           symmetricKey: symmetricKey,
                                           syncEventLoop: syncEventLoop,
                                           preferences: preferences,
                                           logManager: logManager)
        self.myVaultsViewModel = MyVaultsViewModel(vaultSelection: vaultSelection)
        self.preferences = preferences
        self.manualLogIn = manualLogIn
        self.logManager = logManager
        super.init()
        vaultContentViewModel.delegate = self
        start()
    }

    private func start() {
        let viewModel = LoadVaultsViewModel(userData: userData,
                                            vaultSelection: vaultSelection,
                                            shareRepository: shareRepository,
                                            itemRepository: itemRepository,
                                            manualLogIn: manualLogIn,
                                            logManager: logManager)
        viewModel.delegate = self
        let view = MyVaultsView(myVaultsViewModel: myVaultsViewModel,
                                loadVaultsViewModel: viewModel,
                                vaultContentViewModel: vaultContentViewModel)
        let secondaryView = ItemDetailPlaceholderView(onGoBack: { self.popTopViewController() })
        self.start(with: view, secondaryView: secondaryView)
    }

    private func showCreateItemView() {
        guard let shareId = vaultSelection.selectedVault?.shareId else { return }
        let createItemViewModel = CreateItemViewModel()
        createItemViewModel.onSelectedOption = { [unowned self] option in
            dismissTopMostViewController(animated: true) { [unowned self] in
                switch option {
                case .login:
                    showCreateEditLoginView(mode: .create(shareId: shareId,
                                                          type: .login(title: nil,
                                                                       url: nil,
                                                                       autofill: false)))
                case .alias:
                    showCreateEditAliasView(mode: .create(shareId: shareId, type: .alias))
                case .note:
                    showCreateEditNoteView(mode: .create(shareId: shareId, type: .other))
                case .password:
                    showGeneratePasswordView(delegate: self, mode: .random)
                }
            }
        }
        let createItemView = CreateItemView(viewModel: createItemViewModel)
        let createItemViewController = UIHostingController(rootView: createItemView)
        createItemViewController.sheetPresentationController?.detents = [.medium(), .large()]
        present(createItemViewController, userInterfaceStyle: preferences.theme.userInterfaceStyle)
    }

    private func showVaultListView() {
        let viewModel = VaultListViewModel(itemRepository: itemRepository,
                                           shareRespository: shareRepository,
                                           vaultSelection: vaultSelection,
                                           logManager: logManager)
        viewModel.delegate = self
        let view = VaultListView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)
        viewController.sheetPresentationController?.detents = [.medium(), .large()]
        present(viewController, userInterfaceStyle: preferences.theme.userInterfaceStyle)
    }

    private func showCreateVaultView() {
        let createVaultViewModel =
        CreateVaultViewModel(userData: userData,
                             shareRepository: shareRepository,
                             logManager: logManager)
        createVaultViewModel.delegate = self
        let createVaultView = CreateVaultView(viewModel: createVaultViewModel)
        present(createVaultView,
                userInterfaceStyle: preferences.theme.userInterfaceStyle,
                dismissible: false)
    }

    private func showCreateEditLoginView(mode: ItemMode) {
        let emailAddress = userData.addresses.first?.email ?? ""
        let viewModel = CreateEditLoginViewModel(mode: mode,
                                                 itemRepository: itemRepository,
                                                 aliasRepository: aliasRepository,
                                                 preferences: preferences,
                                                 logManager: logManager,
                                                 emailAddress: emailAddress)
        viewModel.delegate = self
        viewModel.createEditLoginViewModelDelegate = self
        let view = CreateEditLoginView(viewModel: viewModel)
        present(view,
                userInterfaceStyle: preferences.theme.userInterfaceStyle,
                dismissible: false)
        currentCreateEditItemViewModel = viewModel
    }

    private func showCreateEditAliasView(mode: ItemMode) {
        let viewModel = CreateEditAliasViewModel(mode: mode,
                                                 itemRepository: itemRepository,
                                                 aliasRepository: aliasRepository,
                                                 preferences: preferences,
                                                 logManager: logManager)
        viewModel.delegate = self
        viewModel.createEditAliasViewModelDelegate = self
        let view = CreateEditAliasView(viewModel: viewModel)
        present(view,
                userInterfaceStyle: preferences.theme.userInterfaceStyle,
                dismissible: false)
        currentCreateEditItemViewModel = viewModel
    }

    private func showCreateAliasLiteView(options: AliasOptions,
                                         creationInfo: AliasCreationLiteInfo,
                                         delegate: AliasCreationLiteInfoDelegate) {
        let viewModel = CreateAliasLiteViewModel(options: options,
                                                 creationInfo: creationInfo)
        viewModel.aliasCreationDelegate = delegate
        viewModel.delegate = self
        let view = CreateAliasLiteView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.sheetPresentationController?.detents = [.medium()]
        viewModel.onDismiss = { navigationController.dismiss(animated: true) }
        present(navigationController, userInterfaceStyle: preferences.theme.userInterfaceStyle)
    }

    private func showMailboxSelectionView(_ mailboxSelection: MailboxSelection,
                                          mode: MailboxSelectionView.Mode) {
        let view = MailboxSelectionView(mailboxSelection: mailboxSelection, mode: mode)
        let viewController = UIHostingController(rootView: view)
        viewController.sheetPresentationController?.detents = [.medium(), .large()]
        present(viewController,
                userInterfaceStyle: preferences.theme.userInterfaceStyle)
    }

    private func showCreateEditNoteView(mode: ItemMode) {
        let viewModel = CreateEditNoteViewModel(mode: mode,
                                                itemRepository: itemRepository,
                                                preferences: preferences,
                                                logManager: logManager)
        viewModel.delegate = self
        let view = CreateEditNoteView(viewModel: viewModel)
        present(view, userInterfaceStyle: preferences.theme.userInterfaceStyle, dismissible: false)
        currentCreateEditItemViewModel = viewModel
    }

    private func showGeneratePasswordView(delegate: GeneratePasswordViewModelDelegate?,
                                          mode: GeneratePasswordViewMode) {
        let viewModel = GeneratePasswordViewModel(mode: mode)
        viewModel.delegate = delegate
        let view = GeneratePasswordView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)
        let navigationController = UINavigationController(rootViewController: viewController)
        if #available(iOS 16, *) {
            let customDetent = UISheetPresentationController.Detent.custom { _ in
                344
            }
            navigationController.sheetPresentationController?.detents = [customDetent]
        } else {
            navigationController.sheetPresentationController?.detents = [.medium()]
        }
        viewModel.onDismiss = { navigationController.dismiss(animated: true) }
        present(navigationController, userInterfaceStyle: preferences.theme.userInterfaceStyle)
    }

    private func showSearchView() {
        let viewModel = SearchViewModel(symmetricKey: symmetricKey,
                                        itemRepository: itemRepository,
                                        vaultSelection: vaultSelection,
                                        preferences: preferences,
                                        logManager: logManager)
        viewModel.delegate = self
        searchViewModel = viewModel
        let viewController = UIHostingController(rootView: SearchView(viewModel: viewModel))
        let navigationController = UINavigationController(rootViewController: viewController)
        if UIDevice.current.isIpad {
            navigationController.modalPresentationStyle = .formSheet
        } else {
            navigationController.modalPresentationStyle = .fullScreen
            navigationController.modalTransitionStyle = .coverVertical
        }
        present(navigationController,
                userInterfaceStyle: preferences.theme.userInterfaceStyle,
                dismissible: UIDevice.current.isIpad)
    }

    private func showItemDetailView(_ itemContent: ItemContent) {
        let itemDetailView: any View
        let baseItemDetailViewModel: BaseItemDetailViewModel
        switch itemContent.contentData {
        case .login:
            let viewModel = LogInDetailViewModel(itemContent: itemContent,
                                                 itemRepository: itemRepository,
                                                 logManager: logManager)
            viewModel.logInDetailViewModelDelegate = self
            baseItemDetailViewModel = viewModel
            itemDetailView = LogInDetailView(viewModel: viewModel)

        case .note:
            let viewModel = NoteDetailViewModel(itemContent: itemContent,
                                                itemRepository: itemRepository,
                                                logManager: logManager)
            baseItemDetailViewModel = viewModel
            itemDetailView = NoteDetailView(viewModel: viewModel)

        case .alias:
            let viewModel = AliasDetailViewModel(itemContent: itemContent,
                                                 itemRepository: itemRepository,
                                                 aliasRepository: aliasRepository,
                                                 logManager: logManager)
            baseItemDetailViewModel = viewModel
            itemDetailView = AliasDetailView(viewModel: viewModel)
        }

        baseItemDetailViewModel.delegate = self
        currentItemDetailViewModel = baseItemDetailViewModel

        // Push on iPad, sheets on iPhone
        if UIDevice.current.isIpad {
            push(itemDetailView)
        } else {
            present(NavigationView { AnyView(itemDetailView) }.navigationViewStyle(.stack),
                    userInterfaceStyle: preferences.theme.userInterfaceStyle)
        }
    }

    private func handleCreatedItem(_ itemContentType: ItemContentType) {
        dismissTopMostViewController(animated: true) { [unowned self] in
            bannerManager?.displayBottomSuccessMessage(itemContentType.creationMessage)
            vaultContentViewModel.fetchItems()
        }
    }

    private func showEditItemView(_ item: ItemContent) {
        let mode = ItemMode.edit(item)
        switch item.contentData.type {
        case .login:
            showCreateEditLoginView(mode: mode)
        case .note:
            showCreateEditNoteView(mode: mode)
        case .alias:
            showCreateEditAliasView(mode: mode)
        }
    }

    private func handleTrashedItem(_ item: ItemIdentifiable, type: ItemContentType) {
        let message: String
        switch type {
        case .alias:
            message = "Alias deleted"
        case .login:
            message = "Login deleted"
        case .note:
            message = "Note deleted"
        }

        if isAtRootViewController() {
            bannerManager?.displayBottomInfoMessage(message)
        } else {
            dismissTopMostViewController(animated: true) { [unowned self] in
                var placeholderViewController: UIViewController?
                if UIDevice.current.isIpad,
                   let currentItemDetailViewModel,
                   currentItemDetailViewModel.itemContent.shareId == item.shareId,
                   currentItemDetailViewModel.itemContent.item.itemID == item.itemId {
                    let placeholderView = ItemDetailPlaceholderView { self.popTopViewController(animated: true) }
                    placeholderViewController = UIHostingController(rootView: placeholderView)
                }
                self.popToRoot(animated: true, secondaryViewController: placeholderViewController)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [unowned self] in
                    self.bannerManager?.displayBottomInfoMessage(message)
                }
            }
        }

        vaultContentViewModel.fetchItems()
        delegate?.myVaultsCoordinatorWantsToRefreshTrash()
        Task { await searchViewModel?.refreshResults() }
    }

    private func handleMovedItem(_ item: ItemIdentifiable, type: ItemContentType) {
        let message: String
        switch type {
        case .alias:
            message = "Alias moved"
        case .login:
            message = "Login moved"
        case .note:
            message = "Note moved"
        }
        bannerManager?.displayBottomInfoMessage(message)
        vaultContentViewModel.fetchItems()
        delegate?.myVaultsCoordinatorWantsToRefreshTrash()
        Task { await searchViewModel?.refreshResults() }
    }

    private func handleUpdatedItem(_ itemContentType: ItemContentType) {
        dismissTopMostViewController(animated: true) { [unowned self] in
            currentItemDetailViewModel?.refresh()
            bannerManager?.displayBottomSuccessMessage("Changes saved")
            vaultContentViewModel.fetchItems()
            Task { await searchViewModel?.refreshResults() }
        }
    }

    func refreshItems() {
        vaultContentViewModel.fetchItems()
        if let aliasDetailViewModel = currentItemDetailViewModel as? AliasDetailViewModel {
            aliasDetailViewModel.refresh()
        } else {
            currentItemDetailViewModel?.refresh()
        }
        currentCreateEditItemViewModel?.refresh()
    }

    func updateFilterOption(_ filterOption: ItemTypeFilterOption) {
        vaultContentViewModel.filterOption = filterOption
    }
}

// MARK: - CreateVaultViewModelDelegate
extension MyVaultsCoordinator: CreateVaultViewModelDelegate {
    func createVaultViewModelDidCreateShare(_ share: Share) {
        // Set vaults to empty to trigger refresh
        self.vaultSelection.update(vaults: [])
        self.dismissTopMostViewController(animated: true, completion: nil)
    }

    func createVaultViewModelDidFail(_ error: Error) {
        bannerManager?.displayTopErrorMessage(error)
    }
}

// MARK: - VaultContentViewModelDelegate
extension MyVaultsCoordinator: VaultContentViewModelDelegate {
    func vaultContentViewModelWantsToToggleSidebar() {}

    func vaultContentViewModelWantsToShowLoadingHud() {}

    func vaultContentViewModelWantsToHideLoadingHud() {}

    func vaultContentViewModelWantsToSearch() {
        showSearchView()
    }

    func vaultContentViewModelWantsToEnableAutoFill() {
        let view = TurnOnAutoFillView(credentialManager: credentialManager)
        let viewController = UIHostingController(rootView: view)
        if !UIDevice.current.isIpad {
            viewController.modalPresentationStyle = .fullScreen
        }
        present(viewController,
                userInterfaceStyle: preferences.theme.userInterfaceStyle,
                dismissible: false)
    }

    func vaultContentViewModelWantsToShowVaultList() {
        showVaultListView()
    }

    func vaultContentViewModelWantsToCreateItem() {
        showCreateItemView()
    }

    func vaultContentViewModelWantsToShowItemDetail(_ item: ItemContent) {
        showItemDetailView(item)
    }

    func vaultContentViewModelWantsToEditItem(_ item: ItemContent) {
        showEditItemView(item)
    }

    func vaultContentViewModelWantsToCopy(text: String, bannerMessage: String) {
        clipboardManager?.copy(text: text, bannerMessage: bannerMessage)
    }

    func vaultContentViewModelDidTrashItem(_ item: ItemIdentifiable, type: ItemContentType) {
        handleTrashedItem(item, type: type)
    }

    func vaultContentViewModelDidMoveItem(_ item: Client.ItemIdentifiable, type: ItemContentType) {
        handleMovedItem(item, type: type)
    }

    func vaultContentViewModelDidFail(_ error: Error) {
        bannerManager?.displayTopErrorMessage(error)
    }
}

// MARK: - CreateEditItemViewModelDelegate
extension MyVaultsCoordinator: CreateEditItemViewModelDelegate {
    func createEditItemViewModelWantsToShowLoadingHud() {}

    func createEditItemViewModelWantsToHideLoadingHud() {}

    func createEditItemViewModelDidCreateItem(_ item: SymmetricallyEncryptedItem,
                                              type: ItemContentType) {
        handleCreatedItem(type)
    }

    func createEditItemViewModelDidUpdateItem(_ type: ItemContentType) {
        handleUpdatedItem(type)
    }

    func createEditItemViewModelDidTrashItem(_ item: ItemIdentifiable, type: ItemContentType) {
        handleTrashedItem(item, type: type)
    }

    func createEditItemViewModelDidFail(_ error: Error) {
        bannerManager?.displayTopErrorMessage(error)
    }
}

// MARK: - CreateEditAliasViewModelDelegate
extension MyVaultsCoordinator: CreateEditAliasViewModelDelegate {
    func createEditAliasViewModelWantsToSelectMailboxes(_ mailboxSelection: MailboxSelection) {
        showMailboxSelectionView(mailboxSelection, mode: .createEditAlias)
    }

    func createEditAliasViewModelCanNotCreateMoreAliases() {
        dismissTopMostViewController(animated: true) { [unowned self] in
            self.bannerManager?.displayTopErrorMessage("You can not create more aliases.")
        }
    }
}

// MARK: - CreateEditLoginViewModelDelegate
extension MyVaultsCoordinator: CreateEditLoginViewModelDelegate {
    func createEditLoginViewModelWantsToGenerateAlias(options: AliasOptions,
                                                      creationInfo: AliasCreationLiteInfo,
                                                      delegate: AliasCreationLiteInfoDelegate) {
        showCreateAliasLiteView(options: options, creationInfo: creationInfo, delegate: delegate)
    }

    func createEditLoginViewModelWantsToGeneratePassword(_ delegate: GeneratePasswordViewModelDelegate) {
        showGeneratePasswordView(delegate: delegate, mode: .createLogin)
    }

    func createEditLoginViewModelWantsToOpenSettings() {
        UIApplication.shared.openAppSettings()
    }

    func createEditLoginViewModelCanNotCreateMoreAlias() {
        bannerManager?.displayTopErrorMessage("You can not create more aliases.")
    }
}

// MARK: - ItemDetailViewModelDelegate
extension MyVaultsCoordinator: ItemDetailViewModelDelegate {
    func itemDetailViewModelWantsToGoBack() {
        // Dismiss differently because show differently
        // (push on iPad, sheets on iPhone)
        if UIDevice.current.isIpad {
            popTopViewController(animated: true)
        } else {
            dismissTopMostViewController()
        }
    }

    func itemDetailViewModelWantsToEditItem(_ itemContent: ItemContent) {
        showEditItemView(itemContent)
    }

    func itemDetailViewModelWantsToRestore(_ item: ItemListUiModel) {
        print("\(#function) not applicable")
    }

    func itemDetailViewModelWantsToCopy(text: String, bannerMessage: String) {
        clipboardManager?.copy(text: text, bannerMessage: bannerMessage)
    }

    func itemDetailViewModelWantsToShowFullScreen(_ text: String) {
        showFullScreen(text: text, userInterfaceStyle: preferences.theme.userInterfaceStyle)
    }

    func itemDetailViewModelWantsToOpen(urlString: String) {
        urlOpener?.open(urlString: urlString)
    }

    func itemDetailViewModelDidFail(_ error: Error) {
        bannerManager?.displayTopErrorMessage(error)
    }
}

// MARK: - GeneratePasswordViewModelDelegate
extension MyVaultsCoordinator: GeneratePasswordViewModelDelegate {
    func generatePasswordViewModelDidConfirm(password: String) {
        dismissTopMostViewController(animated: true) { [unowned self] in
            clipboardManager?.copy(text: password, bannerMessage: "Password copied")
        }
    }
}

// MARK: - SearchViewModelDelegate
extension MyVaultsCoordinator: SearchViewModelDelegate {
    func searchViewModelWantsToShowLoadingHud() {}

    func searchViewModelWantsToHideLoadingHud() {}

    func searchViewModelWantsToDismiss() {
        dismissTopMostViewController()
    }

    func searchViewModelWantsToShowItemDetail(_ item: Client.ItemContent) {
        showItemDetailView(item)
    }

    func searchViewModelWantsToEditItem(_ item: Client.ItemContent) {
        showEditItemView(item)
    }

    func searchViewModelWantsToCopy(text: String, bannerMessage: String) {
        clipboardManager?.copy(text: text, bannerMessage: bannerMessage)
    }

    func searchViewModelDidTrashItem(_ item: ItemIdentifiable, type: Client.ItemContentType) {
        handleTrashedItem(item, type: type)
    }

    func searchViewModelDidFail(_ error: Error) {
        bannerManager?.displayTopErrorMessage(error)
    }
}

// MARK: - VaultListViewModelDelegate
extension MyVaultsCoordinator: VaultListViewModelDelegate {
    func vaultListViewModelWantsShowLoadingHud() {
        showLoadingHud()
    }

    func vaultListViewModelWantsHideLoadingHud() {
        hideLoadingHud()
    }

    func vaultListViewModelWantsToCreateVault() {
        dismissTopMostViewController(animated: true) { [unowned self] in
            self.showCreateVaultView()
        }
    }

    func vaultListViewModelDidDelete(vault: Vault) {
        dismissTopMostViewController(animated: true) { [unowned self] in
            self.bannerManager?.displayBottomInfoMessage("Vault \"\(vault.name)\" deleted")
            self.vaultSelection.remove(vault: vault)
        }
    }

    func vaultListViewModelDidFail(error: Error) {
        bannerManager?.displayTopErrorMessage(error)
    }
}

// MARK: - CreateAliasLiteViewModelDelegate
extension MyVaultsCoordinator: CreateAliasLiteViewModelDelegate {
    func createAliasLiteViewModelWantsToSelectMailboxes(_ mailboxSelection: MailboxSelection) {
        showMailboxSelectionView(mailboxSelection, mode: .createAliasLite)
    }
}

// MARK: - LogInDetailViewModelDelegate
extension MyVaultsCoordinator: LogInDetailViewModelDelegate {
    func logInDetailViewModelWantsToShowAliasDetail(_ itemContent: ItemContent) {
        showItemDetailView(itemContent)
    }
}

// MARK: - LoadVaultsViewModelDelegate
extension MyVaultsCoordinator: LoadVaultsViewModelDelegate {
    func loadVaultsViewModelWantsToToggleSidebar() {}

    func loadVaultsViewModelDidLoadAllItems() {
        delegate?.myVaultsCoordinatorWantsToRefreshTrash()
    }
}
