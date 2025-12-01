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

    /// Generate inventory summary from items
    func generateInventorySummary(_ items: [Item]) -> InventorySummary {
        let totalValue = calculateTotalInventoryValue(items)
        let documentedCount = items.filter(\.isDocumented).count
        let withPhotosCount = items.filter { !$0.photos.isEmpty }.count
        let withReceiptsCount = items.filter { !$0.receipts.isEmpty }.count
        let roomCount = Set(items.compactMap(\.room?.id)).count
        let categoryCount = Set(items.compactMap(\.category?.id)).count

        return InventorySummary(
            totalItems: items.count,
            totalValue: totalValue,
            documentedCount: documentedCount,
            withPhotosCount: withPhotosCount,
            withReceiptsCount: withReceiptsCount,
            uniqueRoomCount: roomCount,
            uniqueCategoryCount: categoryCount
        )
    }
}

// MARK: - Presentation Models (P2-07)

/// Summary statistics for the inventory
struct InventorySummary: Equatable {
    let totalItems: Int
    let totalValue: Decimal
    let documentedCount: Int
    let withPhotosCount: Int
    let withReceiptsCount: Int
    let uniqueRoomCount: Int
    let uniqueCategoryCount: Int

    /// Percentage of items that are fully documented (0-100)
    var documentationPercentage: Int {
        guard totalItems > 0 else { return 0 }
        return Int((Double(documentedCount) / Double(totalItems)) * 100)
    }

    /// Percentage of items with photos (0-100)
    var photoPercentage: Int {
        guard totalItems > 0 else { return 0 }
        return Int((Double(withPhotosCount) / Double(totalItems)) * 100)
    }

    /// Percentage of items with receipts (0-100)
    var receiptPercentage: Int {
        guard totalItems > 0 else { return 0 }
        return Int((Double(withReceiptsCount) / Double(totalItems)) * 100)
    }

    /// Average value per item
    var averageItemValue: Decimal {
        guard totalItems > 0 else { return 0 }
        return totalValue / Decimal(totalItems)
    }

    /// Summary display items for UI
    var displayItems: [InventorySummaryItem] {
        [
            InventorySummaryItem(
                label: "Total Items",
                value: "\(totalItems)",
                iconName: "archivebox.fill",
                accentColor: "blue"
            ),
            InventorySummaryItem(
                label: "Total Value",
                value: formatCurrency(totalValue),
                iconName: "dollarsign.circle.fill",
                accentColor: "green"
            ),
            InventorySummaryItem(
                label: "Documented",
                value: "\(documentationPercentage)%",
                iconName: "checkmark.seal.fill",
                accentColor: documentationPercentage >= 80 ? "green" : "orange"
            ),
            InventorySummaryItem(
                label: "With Photos",
                value: "\(photoPercentage)%",
                iconName: "photo.fill",
                accentColor: photoPercentage >= 80 ? "green" : "orange"
            )
        ]
    }

    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: value as NSDecimalNumber) ?? "$0"
    }

    static let empty = InventorySummary(
        totalItems: 0,
        totalValue: 0,
        documentedCount: 0,
        withPhotosCount: 0,
        withReceiptsCount: 0,
        uniqueRoomCount: 0,
        uniqueCategoryCount: 0
    )
}

/// Individual summary item for display
struct InventorySummaryItem: Identifiable, Equatable {
    let label: String
    let value: String
    let iconName: String
    let accentColor: String

    var id: String { label }
}

/// State of report generation process
enum ReportGenerationState: Equatable {
    case idle
    case preparing
    case generating(progress: Double)
    case complete(url: URL)
    case failed(error: String)

    var isActive: Bool {
        switch self {
        case .preparing, .generating:
            return true
        default:
            return false
        }
    }

    var displayMessage: String {
        switch self {
        case .idle:
            return ""
        case .preparing:
            return "Preparing report..."
        case .generating(let progress):
            return "Generating... \(Int(progress * 100))%"
        case .complete:
            return "Report ready"
        case .failed(let error):
            return "Failed: \(error)"
        }
    }

    var iconName: String {
        switch self {
        case .idle:
            return ""
        case .preparing:
            return "doc.text.fill"
        case .generating:
            return "arrow.triangle.2.circlepath"
        case .complete:
            return "checkmark.circle.fill"
        case .failed:
            return "exclamationmark.triangle.fill"
        }
    }

    var progress: Double? {
        if case .generating(let progress) = self {
            return progress
        }
        return nil
    }
}
