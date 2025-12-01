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
        title: "Quick Add",
        subtitle: "Take a photo and add an item",
        iconName: "camera.fill",
        accentColor: "blue"
    )

    static let receipt = CaptureActionCard(
        id: "receipt",
        mode: .receipt,
        title: "Scan Receipt",
        subtitle: "Extract details with OCR",
        iconName: "doc.text.viewfinder",
        accentColor: "green"
    )

    static let barcode = CaptureActionCard(
        id: "barcode",
        mode: .barcode,
        title: "Scan Barcode",
        subtitle: "Look up product info",
        iconName: "barcode.viewfinder",
        accentColor: "purple"
    )

    static let allCards: [CaptureActionCard] = [.photo, .receipt, .barcode]
}
