//
//  ReceiptCaptureView.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/28/25.
//

// ============================================================================
// CLAUDE CODE AGENT: RECEIPT CAPTURE VIEW
// ============================================================================
// Task 2.3.3: Camera-based receipt capture with OCR processing
//
// PURPOSE:
// - Capture receipt images using device camera
// - Provide visual feedback during OCR processing
// - Show confidence indicator for OCR results
// - Offer manual entry fallback for low-confidence scans
//
// DESIGN RATIONALE:
// - Follows PhotoCaptureView patterns for consistency
// - Rectangle overlay guides user to frame receipt properly
// - Loading state with progress indicator during OCR
// - Color-coded confidence: green (>0.7), yellow (0.4-0.7), red (<0.4)
// - Manual entry always available as escape hatch
//
// ARCHITECTURE:
// - Pure SwiftUI view with UIImagePickerController wrapper for camera
// - Uses OCRService.shared for text recognition
// - Uses PhotoStorageService.shared for receipt image persistence
// - Returns ReceiptData to parent view via completion handler
// - Handles camera permissions with user-friendly alerts
//
// FUTURE ENHANCEMENTS (NOT in v1):
// - Task 2.3.4: ReceiptReviewSheet for editing extracted data
// - Task 7.1.x: Full accessibility labels
// - Consider VisionKit's DataScannerViewController for iOS 16+
//
// SEE: TODO.md Task 2.3.3 | OCRService.swift | PhotoCaptureView.swift
// ============================================================================

import SwiftUI
import AVFoundation
import UIKit
import PhotosUI

/// Receipt capture view with camera, OCR processing, and confidence feedback
struct ReceiptCaptureView: View {
    // MARK: - Dependencies

    /// Completion handler called with extracted receipt data
    let onReceiptCaptured: (ReceiptData, UIImage) -> Void

    /// Manual entry fallback handler
    let onManualEntry: () -> Void

    // MARK: - Services

    private let ocrService = OCRService.shared
    private let photoStorage = PhotoStorageService.shared

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State private var showingCamera = false
    @State private var showingPermissionAlert = false
    @State private var permissionAlertConfig: PermissionAlertConfig?
    @State private var capturedImage: UIImage?
    @State private var isProcessing = false
    @State private var processingProgress: String = ""
    @State private var receiptData: ReceiptData?
    @State private var showingError = false
    @State private var errorMessage: String?
    @State private var photoPickerItem: PhotosPickerItem?

    // MARK: - Computed Properties

    private var confidenceLevel: ConfidenceLevel? {
        guard let confidence = receiptData?.confidence else { return nil }
        return ConfidenceLevel(confidence: confidence)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                if isProcessing {
                    processingView
                } else if let data = receiptData, let image = capturedImage {
                    resultView(data: data, image: image)
                } else {
                    capturePromptView
                }
            }
            .navigationTitle("Scan Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isProcessing)
                }
            }
            .sheet(isPresented: $showingCamera) {
                CameraReceiptScanView(
                    capturedImage: $capturedImage,
                    onCapture: { image in
                        capturedImage = image
                        showingCamera = false
                        processReceipt(image)
                    }
                )
                .ignoresSafeArea()
            }
            .alert(
                permissionAlertConfig?.title ?? "Permission Required",
                isPresented: $showingPermissionAlert,
                presenting: permissionAlertConfig
            ) { config in
                Button("Open Settings") {
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: { config in
                Text(config.message)
            }
            .alert("Processing Failed", isPresented: $showingError) {
                Button("Try Again") {
                    receiptData = nil
                    capturedImage = nil
                }
                Button("Manual Entry") {
                    onManualEntry()
                }
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text(errorMessage ?? "Failed to process receipt image.")
            }
        }
    }

    // MARK: - Subviews

    private var capturePromptView: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "doc.text.viewfinder")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.accentColor)

                Text("Scan Receipt")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Position the entire receipt within the camera frame for best results")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 32)

            Spacer()

            // Receipt frame preview
            receiptFrameGuide

            Spacer()

            // Action Buttons
            VStack(spacing: 16) {
                Button {
                    checkCameraPermission()
                } label: {
                    Label("Scan Receipt", systemImage: "camera.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("receiptCaptureView.scanButton")

                PhotosPicker(selection: $photoPickerItem, matching: .images) {
                    Label("Choose from Photos", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .onChange(of: photoPickerItem) { _, newItem in
                    Task {
                        await loadPhotoPickerItem(newItem)
                    }
                }
                .accessibilityIdentifier("receiptCaptureView.chooseFromPhotosButton")

                Button {
                    onManualEntry()
                } label: {
                    Label("Enter Manually", systemImage: "keyboard")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.tertiarySystemGroupedBackground))
                        .foregroundStyle(.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("receiptCaptureView.manualEntryButton")
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    private var receiptFrameGuide: some View {
        GeometryReader { geometry in
            let frameWidth = geometry.size.width * 0.7
            let frameHeight = frameWidth * 1.4 // Receipt aspect ratio

            ZStack {
                // Darkened background
                Color.black.opacity(0.05)

                // Receipt frame cutout
                Rectangle()
                    .strokeBorder(Color.accentColor, lineWidth: 3)
                    .frame(width: frameWidth, height: frameHeight)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.05))
                    )

                // Corner markers
                VStack {
                    HStack {
                        cornerMarker
                        Spacer()
                        cornerMarker
                    }
                    Spacer()
                    HStack {
                        cornerMarker
                        Spacer()
                        cornerMarker
                    }
                }
                .frame(width: frameWidth, height: frameHeight)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: 250)
    }

    private var cornerMarker: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color.accentColor)
            .frame(width: 20, height: 4)
    }

    private var processingView: some View {
        VStack(spacing: 24) {
            Spacer()

            ProgressView()
                .scaleEffect(1.5)
                .tint(.accentColor)

            Text("Processing Receipt...")
                .font(.headline)
                .foregroundStyle(.primary)

            Text(processingProgress)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    private func resultView(data: ReceiptData, image: UIImage) -> some View {
        VStack(spacing: 20) {
            // Receipt image preview
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(height: 200)
                .cornerRadius(12)
                .shadow(radius: 4)

            // Confidence indicator
            if let level = confidenceLevel {
                confidenceIndicator(level: level)
            }

            // Extracted data preview
            VStack(alignment: .leading, spacing: 12) {
                if let vendor = data.vendor {
                    dataRow(label: "Vendor", value: vendor)
                }
                if let total = data.total {
                    dataRow(label: "Total", value: formatCurrency(total))
                }
                if let tax = data.taxAmount {
                    dataRow(label: "Tax", value: formatCurrency(tax))
                }
                if let date = data.purchaseDate {
                    dataRow(label: "Date", value: formatDate(date))
                }

                if data.vendor == nil && data.total == nil && data.purchaseDate == nil {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("No data extracted. Consider manual entry.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)

            Spacer()

            // Action buttons
            VStack(spacing: 12) {
                Button {
                    onReceiptCaptured(data, image)
                } label: {
                    Text("Use This Receipt")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("receiptCaptureView.useReceiptButton")

                Button {
                    receiptData = nil
                    capturedImage = nil
                } label: {
                    Text("Try Again")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("receiptCaptureView.tryAgainButton")

                Button {
                    onManualEntry()
                } label: {
                    Text("Enter Manually Instead")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .accessibilityIdentifier("receiptCaptureView.manualEntryFallbackButton")
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .padding(.vertical)
    }

    private func confidenceIndicator(level: ConfidenceLevel) -> some View {
        HStack(spacing: 8) {
            Image(systemName: level.iconName)
                .foregroundStyle(level.color)

            Text(level.description)
                .font(.subheadline)
                .fontWeight(.medium)

            Text("(\(Int(level.confidence * 100))%)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(level.color.opacity(0.15))
        .clipShape(Capsule())
    }

    private func dataRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .leading)

            Text(value)
                .font(.body)
                .fontWeight(.medium)

            Spacer()
        }
    }

    // MARK: - Actions

    private func checkCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .authorized:
            showingCamera = true

        case .notDetermined:
            permissionAlertConfig = PermissionAlertConfig(
                title: "Camera Access Required",
                message: "Nestory Pro needs camera access to scan receipts for automatic data extraction.",
                type: .camera
            )
            showingPermissionAlert = true

            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        showingCamera = true
                    }
                }
            }

        case .denied, .restricted:
            permissionAlertConfig = PermissionAlertConfig(
                title: "Camera Access Denied",
                message: "Please enable camera access in Settings to scan receipts.",
                type: .camera
            )
            showingPermissionAlert = true

        @unknown default:
            break
        }
    }

    private func loadPhotoPickerItem(_ item: PhotosPickerItem?) async {
        guard let item else { return }

        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    capturedImage = image
                    processReceipt(image)
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load photo: \(error.localizedDescription)"
                showingError = true
            }
        }
    }

    @MainActor
    private func processReceipt(_ image: UIImage) {
        isProcessing = true
        processingProgress = "Saving receipt image..."

        Task {
            do {
                // Save image first
                let identifier = try await photoStorage.savePhoto(image)

                await MainActor.run {
                    processingProgress = "Extracting text..."
                }

                // Process with OCR
                let data = try await ocrService.processReceipt(from: identifier)

                await MainActor.run {
                    receiptData = data
                    isProcessing = false
                }

            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = "OCR processing failed: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }

    // MARK: - Helpers

    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD" // TODO: Use env.settings.preferredCurrencyCode from @Environment
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Camera Scan View

struct CameraReceiptScanView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    let onCapture: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator

        // Add custom overlay for receipt frame guidance
        if let overlayView = createReceiptOverlay(for: picker.view.bounds) {
            picker.cameraOverlayView = overlayView
        }

        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // No updates needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    private func createReceiptOverlay(for bounds: CGRect) -> UIView? {
        let overlayView = UIView(frame: bounds)
        overlayView.backgroundColor = .clear
        overlayView.isUserInteractionEnabled = false

        // Receipt frame (similar to SwiftUI preview)
        let frameWidth = bounds.width * 0.8
        let frameHeight = frameWidth * 1.4
        let frameX = (bounds.width - frameWidth) / 2
        let frameY = (bounds.height - frameHeight) / 2

        let frameRect = CGRect(x: frameX, y: frameY, width: frameWidth, height: frameHeight)

        // Draw frame border
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = UIBezierPath(roundedRect: frameRect, cornerRadius: 8).cgPath
        shapeLayer.strokeColor = UIColor.systemBlue.cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineWidth = 3
        overlayView.layer.addSublayer(shapeLayer)

        return overlayView
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraReceiptScanView

        init(_ parent: CameraReceiptScanView) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.onCapture(image)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Confidence Level

enum ConfidenceLevel {
    case high    // > 0.7
    case medium  // 0.4 - 0.7
    case low     // < 0.4

    init(confidence: Double) {
        if confidence > 0.7 {
            self = .high
        } else if confidence >= 0.4 {
            self = .medium
        } else {
            self = .low
        }
    }

    var confidence: Double {
        switch self {
        case .high: return 0.85
        case .medium: return 0.55
        case .low: return 0.25
        }
    }

    var color: Color {
        switch self {
        case .high: return .green
        case .medium: return .orange
        case .low: return .red
        }
    }

    var iconName: String {
        switch self {
        case .high: return "checkmark.circle.fill"
        case .medium: return "exclamationmark.triangle.fill"
        case .low: return "xmark.circle.fill"
        }
    }

    var description: String {
        switch self {
        case .high: return "High Confidence"
        case .medium: return "Medium Confidence"
        case .low: return "Low Confidence"
        }
    }
}

// MARK: - Previews

#Preview("Receipt Capture - Initial") {
    ReceiptCaptureView(
        onReceiptCaptured: { data, image in
            print("Captured: \(data)")
        },
        onManualEntry: {
            print("Manual entry selected")
        }
    )
}

#Preview("Receipt Capture - Processing") {
    struct PreviewWrapper: View {
        @State private var isProcessing = true

        var body: some View {
            ReceiptCaptureView(
                onReceiptCaptured: { _, _ in },
                onManualEntry: { }
            )
        }
    }

    return PreviewWrapper()
}
