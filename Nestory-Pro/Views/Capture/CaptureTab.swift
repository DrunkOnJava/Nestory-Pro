//
//  CaptureTab.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/28/25.
//

// ============================================================================
// CLAUDE CODE AGENT: CAPTURE TAB - Task 2.2.3 COMPLETE
// ============================================================================
// This view implements the main Capture tab with segmented control for:
// - Photo capture (implemented)
// - Receipt capture (placeholder)
// - Barcode scanning (placeholder)
//
// ARCHITECTURE:
// - Segmented control for capture type selection
// - PhotoCaptureView for camera/photo library access
// - QuickAddItemSheet for post-capture item creation
// - Future: CaptureTabViewModel (Task 5.1.4) for state management
//
// WORKFLOW:
// 1. User selects Photo segment
// 2. Taps "Start Photo Capture" button
// 3. PhotoCaptureView modal appears (camera or library)
// 4. After image selection, QuickAddItemSheet appears
// 5. User enters item name and room, saves to SwiftData
//
// FUTURE TASKS:
// - Task 2.3.x: Receipt OCR flow
// - Task 2.4.x: Barcode scanning
// - Task 5.1.4: Add CaptureTabViewModel
//
// SEE: TODO.md Phase 2 | PhotoCaptureView.swift | QuickAddItemSheet.swift
// ============================================================================

import SwiftUI
import SwiftData

struct CaptureTab: View {
    // MARK: - State

    /// Selected capture mode
    @State private var selectedSegment: CaptureMode = .photo

    /// Controls PhotoCaptureView presentation
    @State private var showingPhotoCapture = false

    /// Captured image from PhotoCaptureView
    @State private var capturedImage: UIImage?

    /// Controls QuickAddItemSheet presentation
    @State private var showingQuickAdd = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented Control
                Picker("Capture Mode", selection: $selectedSegment) {
                    ForEach(CaptureMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                .accessibilityIdentifier("captureTab.segmentedControl")

                // Content Area
                switch selectedSegment {
                case .photo:
                    photoSegmentContent
                case .receipt:
                    receiptPlaceholder
                case .barcode:
                    barcodePlaceholder
                }
            }
            .navigationTitle("Capture")
        }
        .sheet(isPresented: $showingPhotoCapture) {
            PhotoCaptureView(
                selectedImage: $capturedImage,
                isPresented: $showingPhotoCapture
            )
        }
        .sheet(isPresented: $showingQuickAdd) {
            if let capturedImage {
                QuickAddItemSheet(capturedImage: capturedImage)
            }
        }
        .onChange(of: capturedImage) { _, newImage in
            if newImage != nil {
                showingQuickAdd = true
            }
        }
        .onChange(of: showingQuickAdd) { _, isShowing in
            // Clear captured image after sheet is dismissed
            if !isShowing {
                capturedImage = nil
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
            Button {
                showingPhotoCapture = true
            } label: {
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

    // MARK: - Receipt Placeholder

    private var receiptPlaceholder: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("Receipt capture coming soon")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            Text("Scan receipts to automatically extract purchase details and attach them to items.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
        }
    }

    // MARK: - Barcode Placeholder

    private var barcodePlaceholder: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "barcode.viewfinder")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("Barcode scan coming soon")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            Text("Scan product barcodes to quickly look up item details and pricing.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
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

// MARK: - Preview

#Preview {
    CaptureTab()
}
