//
//  AccessibilityIdentifiers.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/28/25.
//

import Foundation

/// Centralized accessibility identifiers for UI testing
/// Usage: .accessibilityIdentifier(AccessibilityIdentifiers.Inventory.addButton)
enum AccessibilityIdentifiers {

    // MARK: - Inventory Tab
    enum Inventory {
        static let addButton = "inventory.addButton"
        static let searchField = "inventory.searchField"
        static let filterChip = "inventory.filterChip"
        static let sortButton = "inventory.sortButton"
        static let layoutToggle = "inventory.layoutToggle"
    }

    // MARK: - Add/Edit Item
    enum AddEditItem {
        static let nameField = "addEditItem.nameField"
        static let brandField = "addEditItem.brandField"
        static let modelNumberField = "addEditItem.modelNumberField"
        static let serialNumberField = "addEditItem.serialNumberField"
        static let purchasePriceField = "addEditItem.purchasePriceField"
        static let purchaseDatePicker = "addEditItem.purchaseDatePicker"
        static let categoryPicker = "addEditItem.categoryPicker"
        static let roomPicker = "addEditItem.roomPicker"
        static let conditionPicker = "addEditItem.conditionPicker"
        static let saveButton = "addEditItem.saveButton"
        static let cancelButton = "addEditItem.cancelButton"
    }

    // MARK: - Item Detail
    enum ItemDetail {
        static let screen = "itemDetail.screen"
        static let editButton = "itemDetail.editButton"
        static let deleteButton = "itemDetail.deleteButton"
        static let shareButton = "itemDetail.shareButton"
        static let photosCarousel = "itemDetail.photosCarousel"
        static let addPhotoButton = "itemDetail.addPhotoButton"
    }

    // MARK: - Capture Tab
    enum Capture {
        static let photoButton = "capture.photoButton"
        static let receiptButton = "capture.receiptButton"
        static let barcodeButton = "capture.barcodeButton"
        static let cameraPreview = "capture.cameraPreview"
        static let captureButton = "capture.captureButton"
        static let flashToggle = "capture.flashToggle"
        static let cancelButton = "capture.cancelButton"
        static let confirmButton = "capture.confirmButton"
    }

    // MARK: - Reports Tab
    enum Reports {
        static let fullInventoryCard = "reports.fullInventoryCard"
        static let lossListCard = "reports.lossListCard"
        static let shareButton = "reports.shareButton"
        static let exportButton = "reports.exportButton"
        static let reportHistory = "reports.reportHistory"
        static let pdfFormatButton = "reports.pdfFormatButton"
        static let csvFormatButton = "reports.csvFormatButton"
        static let jsonFormatButton = "reports.jsonFormatButton"
    }

    // MARK: - Settings Tab
    enum Settings {
        static let themeSelector = "settings.themeSelector"
        static let currencySelector = "settings.currencySelector"
        static let iCloudSyncToggle = "settings.iCloudSyncToggle"
        static let appLockToggle = "settings.appLockToggle"
        static let exportDataButton = "settings.exportDataButton"
        static let importDataButton = "settings.importDataButton"
        static let proUpgradeCell = "settings.proUpgradeCell"
        static let aboutCell = "settings.aboutCell"
        static let notificationsToggle = "settings.notificationsToggle"
        static let weeklyReminderToggle = "settings.weeklyReminderToggle"
    }

    // MARK: - Alerts & Dialogs
    enum Alert {
        static let confirmButton = "alert.confirmButton"
        static let cancelButton = "alert.cancelButton"
        static let dismissButton = "alert.dismissButton"
    }

    // MARK: - Pro Features
    enum Pro {
        static let purchaseButton = "pro.purchaseButton"
        static let restorePurchasesButton = "pro.restorePurchasesButton"
        static let closeButton = "pro.closeButton"
        static let featuresScroll = "pro.featuresScroll"
    }

    // MARK: - Common Components
    enum Common {
        static let loadingIndicator = "common.loadingIndicator"
        static let errorMessage = "common.errorMessage"
        static let emptyStateView = "common.emptyStateView"
        static let refreshControl = "common.refreshControl"
    }
}
