//
//  CaptureTab.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/28/25.
//

// ============================================================================
// CLAUDE CODE AGENT: CAPTURE TAB - Tasks 2.5.3, 2.7.1 COMPLETE
// ============================================================================
// This view implements the main Capture tab with segmented control for:
// - Photo capture (implemented)
// - Receipt capture (implemented - ReceiptCaptureView)
// - Barcode scanning (implemented - BarcodeScanView)
//
// ARCHITECTURE:
// - Segmented control for capture type selection
// - PhotoCaptureView for camera/photo library access
// - QuickAddItemSheet for post-capture item creation
// - BarcodeScanView for barcode scanning (Task 2.7.1)
// - ReceiptCaptureView for receipt OCR
// - CaptureTabViewModel for state management (Task 5.1.4)
//
// WORKFLOW (Photo):
// 1. User selects Photo segment
// 2. Taps "Start Photo Capture" button
// 3. PhotoCaptureView modal appears (camera or library)
// 4. After image selection, QuickAddItemSheet appears
// 5. User enters item name and room, saves to SwiftData
//
// WORKFLOW (Barcode):
// 1. User selects Barcode segment
// 2. Taps "Start Barcode Scan" button
// 3. BarcodeScanView modal appears with camera
// 4. After barcode detected, QuickAddBarcodeSheet appears
// 5. User enters item name, barcode is pre-filled
//
// SEE: TODO.md Phase 2 | PhotoCaptureView.swift | BarcodeScanView.swift
// ============================================================================

import SwiftUI
import SwiftData

struct CaptureTab: View {
    @Environment(AppEnvironment.self) private var env
    
    // ViewModel handles capture flow coordination
    private var viewModel: CaptureTabViewModel {
        env.captureViewModel
    }

    // MARK: - Body

    var body: some View {
        @Bindable var vm = viewModel
        
        return NavigationStack {
            VStack(spacing: 0) {
                // Segmented Control
                Picker("Capture Mode", selection: $vm.selectedSegment) {
                    ForEach(CaptureMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                .accessibilityIdentifier("captureTab.segmentedControl")

                // Content Area
                switch vm.selectedSegment {
                case .photo:
                    photoSegmentContent
                case .receipt:
                    receiptSegmentContent
                case .barcode:
                    barcodeSegmentContent
                }
            }
            .navigationTitle("Capture")
        }
        // Photo capture sheets
        .sheet(isPresented: $vm.showingPhotoCapture) {
            PhotoCaptureView(
                selectedImage: $vm.capturedImage,
                isPresented: $vm.showingPhotoCapture
            )
        }
        .sheet(isPresented: $vm.showingQuickAdd) {
            if let capturedImage = vm.capturedImage {
                QuickAddItemSheet(capturedImage: capturedImage)
            }
        }
        // Barcode scanning sheets (Task 2.7.1)
        .sheet(isPresented: $vm.showingBarcodeScanner) {
            BarcodeScanView(isPresented: $vm.showingBarcodeScanner) { barcode in
                viewModel.handleScannedBarcode(barcode)
            }
        }
        .sheet(isPresented: $vm.showingBarcodeQuickAdd) {
            if let barcode = vm.scannedBarcode {
                QuickAddBarcodeSheet(scannedBarcode: barcode)
            }
        }
        // Receipt capture sheet
        .sheet(isPresented: $vm.showingReceiptCapture) {
            ReceiptCaptureView(
                onReceiptCaptured: { receiptData, image in
                    // TODO: Handle receipt capture - create Receipt and optionally link to item
                    print("Receipt captured: \(receiptData.vendor ?? "Unknown vendor")")
                },
                onManualEntry: {
                    // TODO: Show manual receipt entry form
                    print("Manual entry requested")
                }
            )
        }
        // Photo capture state handlers
        .onChange(of: vm.capturedImage) { _, newImage in
            viewModel.handleCapturedImage(newImage)
        }
        .onChange(of: vm.showingQuickAdd) { _, isShowing in
            if !isShowing {
                viewModel.clearCapturedImage()
            }
        }
        // Barcode state handler
        .onChange(of: vm.showingBarcodeQuickAdd) { _, isShowing in
            if !isShowing {
                viewModel.clearScannedBarcode()
            }
        }
    }

    // MARK: - Photo Segment

    private var photoSegmentContent: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.accentColor)

            // Title
            Text("Photo Capture")
                .font(.title2)
                .fontWeight(.semibold)

            // Description
            Text("Take photos of your items to build a visual inventory for insurance documentation.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            // Action Button
            Button(action: viewModel.startPhotoCapture) {
                Label("Start Photo Capture", systemImage: "camera")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
            .accessibilityIdentifier("captureTab.startPhotoCaptureButton")
        }
    }

    // MARK: - Receipt Segment

    private var receiptSegmentContent: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 60))
                .foregroundStyle(Color.accentColor)

            Text("Receipt Capture")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Scan receipts to automatically extract purchase details and attach them to items.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            // Action Button
            Button(action: viewModel.startReceiptCapture) {
                Label("Scan Receipt", systemImage: "doc.text.viewfinder")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
            .accessibilityIdentifier("captureTab.startReceiptCaptureButton")
        }
    }

    // MARK: - Barcode Segment (Task 2.7.1)

    private var barcodeSegmentContent: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "barcode.viewfinder")
                .font(.system(size: 60))
                .foregroundStyle(Color.accentColor)

            Text("Barcode Scan")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Scan product barcodes to quickly add items. The barcode is saved for your records.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            // v1.0 notice
            Text("Product lookup coming in a future update")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Spacer()

            // Action Button
            Button(action: viewModel.startBarcodeScanning) {
                Label("Start Barcode Scan", systemImage: "barcode.viewfinder")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
            .accessibilityIdentifier("captureTab.startBarcodeScanButton")
        }
    }
}

// MARK: - Preview

#Preview {
    CaptureTab()
}
