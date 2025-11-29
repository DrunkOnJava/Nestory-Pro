//
//  AppEnvironment.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/28/25.
//

// ============================================================================
// CLAUDE CODE AGENT: DEPENDENCY INJECTION CONTAINER
// ============================================================================
// Task 5.2.1: AppEnvironment replaces singleton pattern with proper DI
// - All services are initialized once and injected via @Environment
// - No more .shared singletons throughout the codebase
// - Services remain actor-isolated where needed (PhotoStorage, OCR, etc.)
// - MainActor services (SettingsManager, IAPValidator) are marked accordingly
//
// USAGE:
// 1. Access in views: @Environment(AppEnvironment.self) private var env
// 2. Use services: env.settings.isProUnlocked, await env.photoStorage.savePhoto(...)
// 3. ViewModels get AppEnvironment injected via initializer
//
// SEE: TODO.md Task 5.2.1 | WARP.md Architecture section
// ============================================================================

import Foundation
import SwiftUI

/// Central dependency injection container for all app services
/// Injected at app root via @Environment and passed down to all views/viewmodels
@Observable
@MainActor
final class AppEnvironment {
    
    // MARK: - Services
    
    /// User preferences and settings
    let settings: SettingsManager
    
    /// In-app purchase validation and Pro status
    let iapValidator: IAPValidator
    
    /// Photo file storage (actor-isolated)
    nonisolated let photoStorage: PhotoStorageService
    
    /// OCR text recognition (actor-isolated)
    nonisolated let ocrService: OCRService
    
    /// PDF report generation (actor-isolated)
    nonisolated let reportGenerator: ReportGeneratorService
    
    /// Data backup/restore (actor-isolated)
    nonisolated let backupService: BackupService
    
    // MARK: - ViewModels
    
    /// Inventory tab view model
    let inventoryViewModel: InventoryTabViewModel
    
    /// Capture tab view model
    let captureViewModel: CaptureTabViewModel
    
    /// Reports tab view model
    let reportsViewModel: ReportsTabViewModel
    
    /// Create a new AddItemViewModel instance
    /// Each AddItemView sheet gets its own fresh instance
    func makeAddItemViewModel() -> AddItemViewModel {
        AddItemViewModel(settings: settings)
    }
    
    // MARK: - Initialization
    
    /// Creates app environment with all services
    /// Called once at app launch in Nestory_ProApp
    /// MainActor-isolated to allow initializing MainActor services
    init(
        settings: SettingsManager? = nil,
        iapValidator: IAPValidator? = nil,
        photoStorage: PhotoStorageService? = nil,
        ocrService: OCRService? = nil,
        reportGenerator: ReportGeneratorService? = nil,
        backupService: BackupService? = nil
    ) {
        // Use provided services or create defaults
        self.settings = settings ?? SettingsManager()
        self.iapValidator = iapValidator ?? IAPValidator()
        self.photoStorage = photoStorage ?? PhotoStorageService.shared
        self.ocrService = ocrService ?? OCRService.shared
        self.reportGenerator = reportGenerator ?? ReportGeneratorService.shared
        self.backupService = backupService ?? BackupService.shared
        
        // Initialize ViewModels with service dependencies
        self.inventoryViewModel = InventoryTabViewModel(settings: self.settings)
        self.captureViewModel = CaptureTabViewModel()
        self.reportsViewModel = ReportsTabViewModel()
    }
    
    // MARK: - Testing Support
    
    #if DEBUG
    /// Creates a mock environment for previews and tests
    /// - Parameters:
    ///   - isProUnlocked: Whether Pro features are unlocked
    ///   - preferredCurrencyCode: Currency code for formatting
    /// - Returns: AppEnvironment configured for testing
    static func mock(
        isProUnlocked: Bool = true,
        preferredCurrencyCode: String = "USD"
    ) -> AppEnvironment {
        let settings = SettingsManager()
        settings.isProUnlocked = isProUnlocked
        
        let iapValidator = IAPValidator()
        
        return AppEnvironment(
            settings: settings,
            iapValidator: iapValidator,
            photoStorage: PhotoStorageService.shared,
            ocrService: OCRService.shared,
            reportGenerator: ReportGeneratorService.shared,
            backupService: BackupService.shared
        )
    }
    #endif
}

// MARK: - Environment Key

extension EnvironmentValues {
    @Entry var appEnvironment: AppEnvironment = AppEnvironment()
}
