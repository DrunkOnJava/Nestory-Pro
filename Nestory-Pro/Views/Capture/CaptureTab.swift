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
import TipKit

struct CaptureTab: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.modelContext) private var modelContext
    
    // Query for recent items with photos (for recent captures strip)
    @Query(
        filter: #Predicate<Item> { item in
            !item.photos.isEmpty
        },
        sort: \Item.updatedAt,
        order: .reverse
    ) private var recentItems: [Item]
    
    // ViewModel handles capture flow coordination
    private var viewModel: CaptureTabViewModel {
        env.captureViewModel
    }

    // MARK: - Body

    var body: some View {
        @Bindable var vm = viewModel
        let quickCaptureTip = QuickCaptureTip()
        
        return NavigationStack {
            VStack(spacing: 0) {
                // Quick Capture Tip (Task 8.3.3 - general guidance)
                TipView(quickCaptureTip)
                    .tipBackground(NestoryTheme.Colors.cardBackground)
                    .padding(.horizontal, NestoryTheme.Metrics.paddingMedium)
                
                // Segmented Control
                Picker("Capture Mode", selection: $vm.selectedSegment) {
                    ForEach(CaptureMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(NestoryTheme.Metrics.paddingMedium)
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
        VStack(spacing: NestoryTheme.Metrics.spacingXLarge) {
            Spacer()

            // Icon
            Image(systemName: "camera.fill")
                .font(.system(size: NestoryTheme.Metrics.iconHero))
                .foregroundStyle(NestoryTheme.Colors.accent)

            // Title
            Text("Photo Capture")
                .font(NestoryTheme.Typography.title2)

            // Description
            Text("Take photos of your items to build a visual inventory for insurance documentation.")
                .font(NestoryTheme.Typography.subheadline)
                .foregroundStyle(NestoryTheme.Colors.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, NestoryTheme.Metrics.spacingXXLarge)

            Spacer()

            // Action Button
            Button(action: viewModel.startPhotoCapture) {
                Label("Start Photo Capture", systemImage: "camera")
                    .font(NestoryTheme.Typography.headline)
                    .frame(maxWidth: .infinity)
                    .padding(NestoryTheme.Metrics.paddingMedium)
                    .background(NestoryTheme.Colors.accent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: NestoryTheme.Metrics.cornerRadiusLarge))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, NestoryTheme.Metrics.spacingXXLarge)
            .accessibilityIdentifier("captureTab.startPhotoCaptureButton")
            
            // Recent Captures Strip (Task 2.5.4)
            if !recentItems.isEmpty {
                recentCapturesStrip
            }
        }
        .padding(.bottom, 24)
    }
    
    // MARK: - Recent Captures Strip (Task 2.5.4)

    /// Bottom strip showing 3 most recent items with photos
    private var recentCapturesStrip: some View {
        VStack(alignment: .leading, spacing: NestoryTheme.Metrics.spacingMedium) {
            Text("Recent Captures")
                .font(NestoryTheme.Typography.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(NestoryTheme.Colors.muted)
                .padding(.horizontal, NestoryTheme.Metrics.spacingXXLarge)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: NestoryTheme.Metrics.spacingMedium) {
                    ForEach(Array(recentItems.prefix(3))) { item in
                        NavigationLink(destination: ItemDetailView(item: item)) {
                            RecentCaptureCell(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, NestoryTheme.Metrics.spacingXXLarge)
            }
        }
    }

    // MARK: - Receipt Segment

    private var receiptSegmentContent: some View {
        VStack(spacing: NestoryTheme.Metrics.spacingXLarge) {
            Spacer()

            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: NestoryTheme.Metrics.iconHero))
                .foregroundStyle(NestoryTheme.Colors.accent)

            Text("Receipt Capture")
                .font(NestoryTheme.Typography.title2)

            Text("Scan receipts to automatically extract purchase details and attach them to items.")
                .font(NestoryTheme.Typography.subheadline)
                .foregroundStyle(NestoryTheme.Colors.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, NestoryTheme.Metrics.spacingXXLarge)

            Spacer()

            // Action Button
            Button(action: viewModel.startReceiptCapture) {
                Label("Scan Receipt", systemImage: "doc.text.viewfinder")
                    .font(NestoryTheme.Typography.headline)
                    .frame(maxWidth: .infinity)
                    .padding(NestoryTheme.Metrics.paddingMedium)
                    .background(NestoryTheme.Colors.accent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: NestoryTheme.Metrics.cornerRadiusLarge))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, NestoryTheme.Metrics.spacingXXLarge)
            .padding(.bottom, NestoryTheme.Metrics.spacingXXLarge)
            .accessibilityIdentifier("captureTab.startReceiptCaptureButton")
        }
    }

    // MARK: - Barcode Segment (Task 2.7.1)

    private var barcodeSegmentContent: some View {
        VStack(spacing: NestoryTheme.Metrics.spacingXLarge) {
            Spacer()

            Image(systemName: "barcode.viewfinder")
                .font(.system(size: NestoryTheme.Metrics.iconHero))
                .foregroundStyle(NestoryTheme.Colors.accent)

            Text("Barcode Scan")
                .font(NestoryTheme.Typography.title2)

            Text("Scan product barcodes to quickly add items. The barcode is saved for your records.")
                .font(NestoryTheme.Typography.subheadline)
                .foregroundStyle(NestoryTheme.Colors.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, NestoryTheme.Metrics.spacingXXLarge)

            // v1.0 notice
            Text("Product lookup coming in a future update")
                .font(NestoryTheme.Typography.caption)
                .foregroundStyle(NestoryTheme.Colors.muted.opacity(0.7))

            Spacer()

            // Action Button
            Button(action: viewModel.startBarcodeScanning) {
                Label("Start Barcode Scan", systemImage: "barcode.viewfinder")
                    .font(NestoryTheme.Typography.headline)
                    .frame(maxWidth: .infinity)
                    .padding(NestoryTheme.Metrics.paddingMedium)
                    .background(NestoryTheme.Colors.accent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: NestoryTheme.Metrics.cornerRadiusLarge))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, NestoryTheme.Metrics.spacingXXLarge)
            .padding(.bottom, NestoryTheme.Metrics.spacingXXLarge)
            .accessibilityIdentifier("captureTab.startBarcodeScanButton")
        }
    }
}

// MARK: - Recent Capture Cell (Task 2.5.4)

/// Cell for recent captures strip showing item thumbnail and name
struct RecentCaptureCell: View {
    let item: Item

    var body: some View {
        VStack(alignment: .center, spacing: NestoryTheme.Metrics.spacingSmall) {
            // Thumbnail
            ZStack {
                Rectangle()
                    .fill(NestoryTheme.Colors.cardBackground)

                if !item.photos.isEmpty {
                    // TODO: Load actual photo from PhotoStorageService
                    Image(systemName: item.category?.iconName ?? "cube.fill")
                        .font(.title2)
                        .foregroundStyle(NestoryTheme.Colors.muted)
                } else if let category = item.category {
                    Image(systemName: category.iconName)
                        .font(.title2)
                        .foregroundStyle(Color(hex: category.colorHex) ?? NestoryTheme.Colors.muted)
                } else {
                    Image(systemName: "cube.fill")
                        .font(.title2)
                        .foregroundStyle(NestoryTheme.Colors.muted)
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: NestoryTheme.Metrics.cornerRadiusMedium))

            // Item name
            Text(item.name)
                .font(NestoryTheme.Typography.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 80)
        }
    }
}

// MARK: - Preview

#Preview {
    CaptureTab()
        .environment(AppEnvironment())
}
