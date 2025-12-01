//
//  AccessibilityIdentifiers.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/28/25.
//

// ============================================================================
// Task P2-14-5: Accessibility Identifiers for UI Testing
// Centralized, versioned identifiers for VoiceOver and XCUITest support
// ============================================================================

import Foundation

/// Centralized accessibility identifiers for UI testing
/// Usage: .accessibilityIdentifier(AccessibilityIdentifiers.Inventory.addButton)
enum AccessibilityIdentifiers {

    // MARK: - Main Tab Bar

    enum MainTab {
        static let inventoryTab = "mainTab.inventory"
        static let captureTab = "mainTab.capture"
        static let reportsTab = "mainTab.reports"
        static let settingsTab = "mainTab.settings"
    }

    // MARK: - Inventory Tab

    enum Inventory {
        static let screen = "inventory.screen"
        static let itemList = "inventory.itemList"
        static let itemGrid = "inventory.itemGrid"
        static let addButton = "inventory.addButton"
        static let searchField = "inventory.searchField"
        static let filterChip = "inventory.filterChip"
        static let sortButton = "inventory.sortButton"
        static let layoutToggle = "inventory.layoutToggle"

        // Summary cards
        static let totalItemsCard = "inventory.totalItemsCard"
        static let estimatedValueCard = "inventory.estimatedValueCard"
        static let documentationScoreCard = "inventory.documentationScoreCard"

        // Item limit warning
        static let itemLimitBanner = "inventory.itemLimitBanner"
        static let upgradeButton = "inventory.upgradeButton"
    }

    // MARK: - Hierarchy Views (P2-02)

    enum Hierarchy {
        // Property List
        static let propertyList = "hierarchy.propertyList"
        static let addPropertyButton = "hierarchy.addPropertyButton"

        // Property Detail
        static let propertyDetail = "hierarchy.propertyDetail"
        static let propertyName = "hierarchy.propertyName"
        static let propertySummary = "hierarchy.propertySummary"
        static let addRoomButton = "hierarchy.addRoomButton"
        static let roomList = "hierarchy.roomList"

        // Room Detail
        static let roomDetail = "hierarchy.roomDetail"
        static let roomName = "hierarchy.roomName"
        static let roomSummary = "hierarchy.roomSummary"
        static let addContainerButton = "hierarchy.addContainerButton"
        static let addItemButton = "hierarchy.addItemButton"
        static let containerList = "hierarchy.containerList"
        static let itemList = "hierarchy.itemList"

        // Container Detail
        static let containerDetail = "hierarchy.containerDetail"
        static let containerName = "hierarchy.containerName"
        static let containerSummary = "hierarchy.containerSummary"
        static let containerItemList = "hierarchy.containerItemList"

        // Breadcrumb
        static let breadcrumb = "hierarchy.breadcrumb"

        // Editor Sheets
        static let propertyEditor = "hierarchy.propertyEditor"
        static let roomEditor = "hierarchy.roomEditor"
        static let containerEditor = "hierarchy.containerEditor"
    }

    // MARK: - Add/Edit Item

    enum AddEditItem {
        static let screen = "addEditItem.screen"
        static let nameField = "addEditItem.nameField"
        static let brandField = "addEditItem.brandField"
        static let modelNumberField = "addEditItem.modelNumberField"
        static let serialNumberField = "addEditItem.serialNumberField"
        static let purchasePriceField = "addEditItem.purchasePriceField"
        static let purchaseDatePicker = "addEditItem.purchaseDatePicker"
        static let categoryPicker = "addEditItem.categoryPicker"
        static let roomPicker = "addEditItem.roomPicker"
        static let containerPicker = "addEditItem.containerPicker"
        static let conditionPicker = "addEditItem.conditionPicker"
        static let notesField = "addEditItem.notesField"
        static let saveButton = "addEditItem.saveButton"
        static let cancelButton = "addEditItem.cancelButton"
        static let validationError = "addEditItem.validationError"
    }

    // MARK: - Item Detail

    enum ItemDetail {
        static let screen = "itemDetail.screen"
        static let editButton = "itemDetail.editButton"
        static let deleteButton = "itemDetail.deleteButton"
        static let shareButton = "itemDetail.shareButton"
        static let photosCarousel = "itemDetail.photosCarousel"
        static let addPhotoButton = "itemDetail.addPhotoButton"
        static let addReceiptButton = "itemDetail.addReceiptButton"

        // Info Cards
        static let basicInfoCard = "itemDetail.basicInfoCard"
        static let valueCard = "itemDetail.valueCard"
        static let warrantyCard = "itemDetail.warrantyCard"
        static let documentationCard = "itemDetail.documentationCard"

        // Documentation Status
        static let documentationProgress = "itemDetail.documentationProgress"
        static let documentationFieldList = "itemDetail.documentationFieldList"
    }

    // MARK: - Capture Tab

    enum Capture {
        static let screen = "capture.screen"
        static let segmentedControl = "capture.segmentedControl"
        static let photoButton = "capture.photoButton"
        static let receiptButton = "capture.receiptButton"
        static let barcodeButton = "capture.barcodeButton"
        static let cameraPreview = "capture.cameraPreview"
        static let captureButton = "capture.captureButton"
        static let shutterButton = "capture.shutterButton"
        static let flashToggle = "capture.flashToggle"
        static let cancelButton = "capture.cancelButton"
        static let confirmButton = "capture.confirmButton"

        // Status banner
        static let statusBanner = "capture.statusBanner"
        static let recentCaptures = "capture.recentCaptures"
    }

    // MARK: - Reports Tab

    enum Reports {
        static let screen = "reports.screen"
        static let summarySection = "reports.summarySection"
        static let fullInventoryCard = "reports.fullInventoryCard"
        static let lossListCard = "reports.lossListCard"
        static let warrantyListCard = "reports.warrantyListCard"
        static let shareButton = "reports.shareButton"
        static let exportButton = "reports.exportButton"
        static let generateButton = "reports.generateButton"
        static let reportHistory = "reports.reportHistory"

        // Format buttons
        static let pdfFormatButton = "reports.pdfFormatButton"
        static let csvFormatButton = "reports.csvFormatButton"
        static let jsonFormatButton = "reports.jsonFormatButton"

        // Generation states
        static let generatingIndicator = "reports.generatingIndicator"
        static let generationError = "reports.generationError"
    }

    // MARK: - Onboarding

    enum Onboarding {
        static let view = "onboarding.view"
        static let skipButton = "onboarding.skipButton"
        static let nextButton = "onboarding.nextButton"
        static let backButton = "onboarding.backButton"
        static let getStartedButton = "onboarding.getStartedButton"
        static let pageIndicator = "onboarding.pageIndicator"
    }

    // MARK: - Settings Tab

    enum Settings {
        static let screen = "settings.screen"
        static let themeSelector = "settings.themeSelector"
        static let currencySelector = "settings.currencySelector"
        static let iCloudSyncToggle = "settings.iCloudSyncToggle"
        static let appLockToggle = "settings.appLockToggle"
        static let exportDataButton = "settings.exportDataButton"
        static let importDataButton = "settings.importDataButton"
        static let resetOnboardingButton = "settings.resetOnboardingButton"
        static let proUpgradeCell = "settings.proUpgradeCell"
        static let aboutCell = "settings.aboutCell"
        static let notificationsToggle = "settings.notificationsToggle"
        static let weeklyReminderToggle = "settings.weeklyReminderToggle"
        static let feedbackButton = "settings.feedbackButton"
        static let reportProblemButton = "settings.reportProblemButton"
        static let versionLabel = "settings.versionLabel"
    }

    // MARK: - Alerts & Sheets

    enum Alert {
        static let confirmButton = "alert.confirmButton"
        static let cancelButton = "alert.cancelButton"
        static let dismissButton = "alert.dismissButton"
        static let confirmDelete = "alert.confirmDelete"
    }

    enum Sheet {
        static let addItem = "sheet.addItem"
        static let editItem = "sheet.editItem"
        static let selectCategory = "sheet.selectCategory"
        static let selectRoom = "sheet.selectRoom"
        static let selectContainer = "sheet.selectContainer"
        static let exportOptions = "sheet.exportOptions"
    }

    // MARK: - Pro Features & Paywall

    enum Pro {
        static let paywallSheet = "pro.paywallSheet"
        static let purchaseButton = "pro.purchaseButton"
        static let restorePurchasesButton = "pro.restorePurchasesButton"
        static let closeButton = "pro.closeButton"
        static let featuresScroll = "pro.featuresScroll"
        static let priceLabel = "pro.priceLabel"
        static let featureRow = "pro.featureRow"
    }

    // MARK: - Lock Screen

    enum LockScreen {
        static let screen = "lockScreen.screen"
        static let unlockButton = "lockScreen.unlockButton"
        static let biometricIcon = "lockScreen.biometricIcon"
    }

    // MARK: - Common Components

    enum Common {
        static let loadingIndicator = "common.loadingIndicator"
        static let errorMessage = "common.errorMessage"
        static let emptyStateView = "common.emptyStateView"
        static let emptyStateButton = "common.emptyStateButton"
        static let refreshControl = "common.refreshControl"
        static let retryButton = "common.retryButton"
    }
}

// MARK: - Dynamic Identifiers

extension AccessibilityIdentifiers {
    /// Generate identifier for item cell at index
    static func itemCell(at index: Int) -> String {
        "itemCell.\(index)"
    }

    /// Generate identifier for item by ID
    static func itemCell(id: String) -> String {
        "itemCell.\(id)"
    }

    /// Generate identifier for filter chip
    static func filterChip(named name: String) -> String {
        "filterChip.\(name)"
    }

    /// Generate identifier for report in history
    static func reportItem(at index: Int) -> String {
        "reportItem.\(index)"
    }

    /// Generate identifier for property row
    static func propertyRow(id: String) -> String {
        "propertyRow.\(id)"
    }

    /// Generate identifier for room row
    static func roomRow(id: String) -> String {
        "roomRow.\(id)"
    }

    /// Generate identifier for container row
    static func containerRow(id: String) -> String {
        "containerRow.\(id)"
    }

    /// Generate identifier for documentation field
    static func documentationField(named name: String) -> String {
        "documentationField.\(name)"
    }
}
