//
//  CaptureTabViewModel.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/29/25.
//

import SwiftUI
import Observation

/// ViewModel for CaptureTab that coordinates capture flows and manages state
/// Follows MVVM pattern with proper dependency injection.
@MainActor
@Observable
final class CaptureTabViewModel {
    
    // MARK: - UI State

    var selectedSegment: CaptureMode = .photo
    var showingPhotoCapture: Bool = false
    var capturedImage: UIImage?
    var showingQuickAdd: Bool = false

    // Barcode scanning state (Task 2.7.1)
    var showingBarcodeScanner: Bool = false
    var scannedBarcode: String?
    var showingBarcodeQuickAdd: Bool = false

    // Receipt capture state
    var showingReceiptCapture: Bool = false

    // Batch capture state (F8)
    var showingBatchCapture: Bool = false
    var showingEditQueue: Bool = false
    var queueCount: Int = 0

    // Capture status for status banner (P2-11-1)
    var captureStatus: CaptureStatus = .idle
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Photo Actions
    
    /// Start photo capture flow
    func startPhotoCapture() {
        showingPhotoCapture = true
    }
    
    /// Handle captured image from PhotoCaptureView
    /// - Parameter image: The captured UIImage
    func handleCapturedImage(_ image: UIImage?) {
        capturedImage = image
        if image != nil {
            showingQuickAdd = true
        }
    }
    
    /// Clear captured image after QuickAdd sheet is dismissed
    func clearCapturedImage() {
        capturedImage = nil
    }
    
    /// Handle QuickAdd sheet dismissal
    func handleQuickAddDismissal() {
        if !showingQuickAdd {
            clearCapturedImage()
        }
    }
    
    // MARK: - Barcode Actions (Task 2.7.1)
    
    /// Start barcode scanning flow
    func startBarcodeScanning() {
        showingBarcodeScanner = true
    }
    
    /// Handle scanned barcode
    /// - Parameter barcode: The scanned barcode string
    func handleScannedBarcode(_ barcode: String) {
        scannedBarcode = barcode
        showingBarcodeQuickAdd = true
    }
    
    /// Clear scanned barcode after sheet is dismissed
    func clearScannedBarcode() {
        scannedBarcode = nil
    }
    
    // MARK: - Receipt Actions

    /// Start receipt capture flow
    func startReceiptCapture() {
        showingReceiptCapture = true
    }

    // MARK: - Batch Capture Actions (F8)

    /// Start batch capture mode
    func startBatchCapture() {
        showingBatchCapture = true
    }

    /// Show the edit queue view
    func showEditQueue() {
        showingEditQueue = true
    }

    /// Refresh the queue count from CaptureQueueService
    func refreshQueueCount() async {
        queueCount = await CaptureQueueService.shared.pendingCount
    }

    // MARK: - Status Management (P2-11-1)

    /// Update capture status with optional auto-dismiss for success/error states
    func updateStatus(_ status: CaptureStatus) {
        captureStatus = status

        // Auto-dismiss success/error after delay
        switch status {
        case .success, .error:
            Task {
                try? await Task.sleep(for: .seconds(2))
                if captureStatus == status {
                    captureStatus = .idle
                }
            }
        default:
            break
        }
    }

    /// Reset status to idle
    func clearStatus() {
        captureStatus = .idle
    }

    // MARK: - Action Cards (P2-11-1)

    /// Get the action card for the current capture mode
    var currentActionCard: CaptureActionCard {
        switch selectedSegment {
        case .photo:
            return .photo
        case .receipt:
            return .receipt
        case .barcode:
            return .barcode
        }
    }
}

// MARK: - Capture Mode

enum CaptureMode: String, CaseIterable, Identifiable {
    case photo = "Photo"
    case receipt = "Receipt"
    case barcode = "Barcode"

    var id: String { rawValue }
}

// MARK: - Presentation Models (P2-07)

/// Represents the current status of a capture operation
enum CaptureStatus: Equatable {
    case idle
    case capturing
    case processing
    case success(message: String)
    case error(message: String)

    var isActive: Bool {
        switch self {
        case .capturing, .processing:
            return true
        default:
            return false
        }
    }

    var displayMessage: String {
        switch self {
        case .idle:
            return ""
        case .capturing:
            return "Capturing..."
        case .processing:
            return "Processing..."
        case .success(let message):
            return message
        case .error(let message):
            return message
        }
    }

    var iconName: String {
        switch self {
        case .idle:
            return ""
        case .capturing:
            return "camera.fill"
        case .processing:
            return "gearshape.fill"
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        }
    }
}

/// Represents an action card on the capture tab
struct CaptureActionCard: Identifiable, Equatable {
    let id: String
    let mode: CaptureMode
    let title: String
    let subtitle: String
    let iconName: String
    let accentColor: String

    static let photo = CaptureActionCard(
        id: "photo",
        mode: .photo,
        title: "Photo Capture",
        subtitle: "Take photos of your items to build a visual inventory for insurance documentation.",
        iconName: "camera.fill",
        accentColor: "blue"
    )

    static let receipt = CaptureActionCard(
        id: "receipt",
        mode: .receipt,
        title: "Receipt Capture",
        subtitle: "Scan receipts to automatically extract purchase details and attach them to items.",
        iconName: "doc.text.viewfinder",
        accentColor: "green"
    )

    static let barcode = CaptureActionCard(
        id: "barcode",
        mode: .barcode,
        title: "Barcode Scan",
        subtitle: "Scan product barcodes to quickly add items. The barcode is saved for your records.",
        iconName: "barcode.viewfinder",
        accentColor: "purple"
    )

    static let allCards: [CaptureActionCard] = [.photo, .receipt, .barcode]
}
