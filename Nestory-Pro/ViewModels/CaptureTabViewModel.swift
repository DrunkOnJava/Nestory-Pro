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
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Actions
    
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
}

// MARK: - Capture Mode

enum CaptureMode: String, CaseIterable, Identifiable {
    case photo = "Photo"
    case receipt = "Receipt"
    case barcode = "Barcode"
    
    var id: String { rawValue }
}
