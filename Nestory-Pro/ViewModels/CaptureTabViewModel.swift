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
