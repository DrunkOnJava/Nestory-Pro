//
//  AccessibilityIdentifiers.swift
//  Nestory-ProUITests
//
//  Centralized accessibility identifiers for UI testing
//

import Foundation

/// Centralized accessibility identifiers for UI testing
/// Keep this file in sync with identifiers used in the app
enum AccessibilityIdentifiers {
    
    // MARK: - Main Tab Bar
    
    enum MainTab {
        static let inventoryTab = "mainTab.inventory"
        static let captureTab = "mainTab.capture"
        static let reportsTab = "mainTab.reports"
        static let settingsTab = "mainTab.settings"
    }
    
    // MARK: - Inventory Screen
    
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
    }
    
    // MARK: - Item Detail Screen
    
    enum ItemDetail {
        static let screen = "itemDetail.screen"
        static let nameLabel = "itemDetail.nameLabel"
        static let priceLabel = "itemDetail.priceLabel"
        static let categoryLabel = "itemDetail.categoryLabel"
        static let roomLabel = "itemDetail.roomLabel"
        static let editButton = "itemDetail.editButton"
        static let deleteButton = "itemDetail.deleteButton"
        static let addPhotoButton = "itemDetail.addPhotoButton"
        static let addReceiptButton = "itemDetail.addReceiptButton"
        static let photoCarousel = "itemDetail.photoCarousel"
    }
    
    // MARK: - Add/Edit Item Screen
    
    enum AddEditItem {
        static let screen = "addEditItem.screen"
        static let nameField = "addEditItem.nameField"
        static let brandField = "addEditItem.brandField"
        static let modelField = "addEditItem.modelField"
        static let serialField = "addEditItem.serialField"
        static let priceField = "addEditItem.priceField"
        static let dateField = "addEditItem.dateField"
        static let categoryPicker = "addEditItem.categoryPicker"
        static let roomPicker = "addEditItem.roomPicker"
        static let conditionPicker = "addEditItem.conditionPicker"
        static let saveButton = "addEditItem.saveButton"
        static let cancelButton = "addEditItem.cancelButton"
    }
    
    // MARK: - Capture Screen
    
    enum Capture {
        static let screen = "capture.screen"
        static let segmentedControl = "capture.segmentedControl"
        static let photoModeButton = "capture.photoModeButton"
        static let receiptModeButton = "capture.receiptModeButton"
        static let barcodeModeButton = "capture.barcodeModeButton"
        static let shutterButton = "capture.shutterButton"
        static let galleryButton = "capture.galleryButton"
        static let flashButton = "capture.flashButton"
        static let recentCaptures = "capture.recentCaptures"
    }
    
    // MARK: - Reports Screen
    
    enum Reports {
        static let screen = "reports.screen"
        static let fullInventoryCard = "reports.fullInventoryCard"
        static let lossListCard = "reports.lossListCard"
        static let generateButton = "reports.generateButton"
        static let reportHistory = "reports.reportHistory"
        static let shareButton = "reports.shareButton"
    }
    
    // MARK: - Settings Screen
    
    enum Settings {
        static let screen = "settings.screen"
        static let proUpgradeCell = "settings.proUpgradeCell"
        static let iCloudSyncToggle = "settings.iCloudSyncToggle"
        static let exportDataButton = "settings.exportDataButton"
        static let importDataButton = "settings.importDataButton"
        static let themeSelector = "settings.themeSelector"
        static let currencySelector = "settings.currencySelector"
        static let appLockToggle = "settings.appLockToggle"
        static let aboutCell = "settings.aboutCell"
    }
    
    // MARK: - Alerts & Sheets
    
    enum Alert {
        static let confirmDelete = "alert.confirmDelete"
        static let confirmButton = "alert.confirmButton"
        static let cancelButton = "alert.cancelButton"
    }
    
    enum Sheet {
        static let addItem = "sheet.addItem"
        static let editItem = "sheet.editItem"
        static let selectCategory = "sheet.selectCategory"
        static let selectRoom = "sheet.selectRoom"
        static let exportOptions = "sheet.exportOptions"
    }
}

// MARK: - Helper Extensions

extension AccessibilityIdentifiers {
    /// Generate identifier for item cell at index
    static func itemCell(at index: Int) -> String {
        return "itemCell.\(index)"
    }
    
    /// Generate identifier for filter chip
    static func filterChip(named name: String) -> String {
        return "filterChip.\(name)"
    }
    
    /// Generate identifier for report in history
    static func reportItem(at index: Int) -> String {
        return "reportItem.\(index)"
    }
}
