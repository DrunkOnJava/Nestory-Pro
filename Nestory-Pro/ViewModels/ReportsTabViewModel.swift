//
//  ReportsTabViewModel.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/29/25.
//

import SwiftUI
import Observation

/// ViewModel for ReportsTab that handles report generation and statistics
/// Follows MVVM pattern with proper dependency injection.
@MainActor
@Observable
final class ReportsTabViewModel {
    
    // MARK: - UI State
    
    var showingLossListSelection: Bool = false
    var showingFullInventoryReport: Bool = false
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Actions
    
    /// Show loss list selection sheet
    func showLossListSelection() {
        showingLossListSelection = true
    }
    
    /// Show full inventory report sheet
    func showFullInventoryReport() {
        showingFullInventoryReport = true
    }
    
    // MARK: - Statistics
    
    /// Calculate total inventory value from items
    /// - Parameter items: Array of items to calculate value from
    /// - Returns: Total value as Decimal
    func calculateTotalInventoryValue(_ items: [Item]) -> Decimal {
        items.reduce(0) { sum, item in
            sum + (item.purchasePrice ?? 0)
        }
    }
}
