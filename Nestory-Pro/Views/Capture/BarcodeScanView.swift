//
//  BarcodeScanView.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/29/25.
//

// ============================================================================
// TASK 2.7.1: Barcode Scanning Mode
// ============================================================================
// Implements barcode scanning using AVFoundation for v1.0.
//
// FEATURES:
// - AVCaptureSession with barcode detection
// - Supports common barcode formats (EAN-8, EAN-13, UPC-A, UPC-E, QR, Code 128)
// - On successful scan, shows QuickAddBarcodeSheet with pre-filled barcode
// - Works entirely offline (no network lookup in v1.0)
//
// ARCHITECTURE:
// - BarcodeScanView: SwiftUI view wrapping UIViewRepresentable camera preview
// - BarcodeCameraView: UIViewRepresentable for AVCaptureSession
// - QuickAddBarcodeSheet: Minimal form with barcode pre-filled
//
// SEE: TODO.md Task 2.7.1 | CaptureTab.swift | Item.barcode
// ============================================================================

import SwiftUI
import SwiftData
@preconcurrency import AVFoundation

// MARK: - Barcode Scan View

struct BarcodeScanView: View {
    @Binding var isPresented: Bool
    var onBarcodeScanned: (String) -> Void
    
    @State private var hasCameraPermission = false
    @State private var showingPermissionAlert = false
    @State private var scannedBarcode: String?
    @State private var isProcessing = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                if hasCameraPermission {
                    BarcodeCameraView(
                        onBarcodeDetected: handleBarcodeDetected
                    )
                    .ignoresSafeArea()
                    
                    // Scanning overlay
                    scanningOverlay
                } else {
                    permissionDeniedView
                }
            }
            .navigationTitle("Scan Barcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
            .task {
                await checkCameraPermission()
            }
            .alert("Camera Access Required", isPresented: $showingPermissionAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {
                    isPresented = false
                }
            } message: {
                Text("Nestory needs camera access to scan barcodes. Please enable it in Settings.")
            }
        }
    }
    
    // MARK: - Scanning Overlay (P2-11-3)

    private var scanningOverlay: some View {
        VStack {
            Spacer()

            // Scanning frame with rounded corners
            RoundedRectangle(cornerRadius: NestoryTheme.Metrics.cornerRadiusLarge)
                .stroke(Color.white, lineWidth: 3)
                .frame(width: 280, height: 150)
                .overlay(
                    // Corner accents
                    GeometryReader { geo in
                        let size: CGFloat = 30
                        let stroke: CGFloat = 4

                        Path { path in
                            // Top-left
                            path.move(to: CGPoint(x: 0, y: size))
                            path.addLine(to: CGPoint(x: 0, y: 0))
                            path.addLine(to: CGPoint(x: size, y: 0))
                            // Top-right
                            path.move(to: CGPoint(x: geo.size.width - size, y: 0))
                            path.addLine(to: CGPoint(x: geo.size.width, y: 0))
                            path.addLine(to: CGPoint(x: geo.size.width, y: size))
                            // Bottom-right
                            path.move(to: CGPoint(x: geo.size.width, y: geo.size.height - size))
                            path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                            path.addLine(to: CGPoint(x: geo.size.width - size, y: geo.size.height))
                            // Bottom-left
                            path.move(to: CGPoint(x: size, y: geo.size.height))
                            path.addLine(to: CGPoint(x: 0, y: geo.size.height))
                            path.addLine(to: CGPoint(x: 0, y: geo.size.height - size))
                        }
                        .stroke(NestoryTheme.Colors.accent, lineWidth: stroke)
                    }
                )

            Spacer()

            // Instructions (P2-11-3: instructional text above preview)
            VStack(spacing: NestoryTheme.Metrics.spacingMedium) {
                if isProcessing {
                    ProgressView()
                        .tint(.white)
                    Text("Processing barcode...")
                        .font(NestoryTheme.Typography.headline)
                        .foregroundStyle(.white)
                } else {
                    Text("Position barcode within frame")
                        .font(NestoryTheme.Typography.headline)
                        .foregroundStyle(.white)

                    Text("Supports UPC, EAN, QR codes, and more")
                        .font(NestoryTheme.Typography.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            .padding(NestoryTheme.Metrics.paddingMedium)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: NestoryTheme.Metrics.cornerRadiusLarge))
            .padding(.bottom, NestoryTheme.Metrics.spacingXXLarge + NestoryTheme.Metrics.spacingLarge)
        }
    }
    
    // MARK: - Permission Denied View (P2-11-3)

    private var permissionDeniedView: some View {
        VStack(spacing: NestoryTheme.Metrics.spacingXLarge) {
            Image(systemName: "camera.fill")
                .font(.system(size: NestoryTheme.Metrics.iconHero))
                .foregroundStyle(NestoryTheme.Colors.muted)

            Text("Camera Access Required")
                .font(NestoryTheme.Typography.title2)
                .fontWeight(.semibold)

            Text("Nestory needs camera access to scan barcodes on your items.")
                .font(NestoryTheme.Typography.subheadline)
                .foregroundStyle(NestoryTheme.Colors.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, NestoryTheme.Metrics.spacingXXLarge)

            Button {
                showingPermissionAlert = true
            } label: {
                Text("Go to Settings")
                    .font(NestoryTheme.Typography.headline)
                    .frame(maxWidth: .infinity)
                    .padding(NestoryTheme.Metrics.paddingMedium)
                    .background(NestoryTheme.Colors.accent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: NestoryTheme.Metrics.cornerRadiusLarge))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, NestoryTheme.Metrics.spacingXXLarge)
        }
    }
    
    // MARK: - Camera Permission
    
    private func checkCameraPermission() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            hasCameraPermission = true
        case .notDetermined:
            hasCameraPermission = await AVCaptureDevice.requestAccess(for: .video)
        case .denied, .restricted:
            hasCameraPermission = false
            showingPermissionAlert = true
        @unknown default:
            hasCameraPermission = false
        }
    }
    
    // MARK: - Barcode Handler
    
    private func handleBarcodeDetected(_ barcode: String) {
        guard !isProcessing else { return }
        
        isProcessing = true
        scannedBarcode = barcode
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Slight delay for visual feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onBarcodeScanned(barcode)
            isPresented = false
        }
    }
}

// MARK: - Barcode Camera View (UIViewRepresentable)

struct BarcodeCameraView: UIViewRepresentable {
    var onBarcodeDetected: (String) -> Void
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        
        let coordinator = context.coordinator
        coordinator.setupCamera(in: view)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onBarcodeDetected: onBarcodeDetected)
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        let onBarcodeDetected: (String) -> Void
        private var captureSession: AVCaptureSession?
        private var previewLayer: AVCaptureVideoPreviewLayer?
        private var hasDetected = false
        
        init(onBarcodeDetected: @escaping (String) -> Void) {
            self.onBarcodeDetected = onBarcodeDetected
            super.init()
        }
        
        func setupCamera(in view: UIView) {
            let session = AVCaptureSession()
            captureSession = session
            
            // Get camera device
            guard let device = AVCaptureDevice.default(for: .video) else {
                print("BarcodeScanView: No video device available")
                return
            }
            
            // Create input
            guard let input = try? AVCaptureDeviceInput(device: device) else {
                print("BarcodeScanView: Failed to create device input")
                return
            }
            
            if session.canAddInput(input) {
                session.addInput(input)
            }
            
            // Create metadata output
            let output = AVCaptureMetadataOutput()
            if session.canAddOutput(output) {
                session.addOutput(output)
                
                output.setMetadataObjectsDelegate(self, queue: .main)
                
                // Supported barcode types
                output.metadataObjectTypes = [
                    .ean8,
                    .ean13,
                    .upce,
                    .code128,
                    .code39,
                    .code93,
                    .qr,
                    .pdf417,
                    .aztec,
                    .dataMatrix
                ]
            }
            
            // Setup preview layer
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = view.bounds
            view.layer.addSublayer(previewLayer)
            self.previewLayer = previewLayer
            
            // Start session on background queue
            let sessionToStart = session
            DispatchQueue.global(qos: .userInitiated).async {
                sessionToStart.startRunning()
            }
            
            // Handle view resize
            NotificationCenter.default.addObserver(
                forName: UIDevice.orientationDidChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self, weak view] _ in
                MainActor.assumeIsolated {
                    guard let view = view else { return }
                    self?.previewLayer?.frame = view.bounds
                }
            }
        }
        
        func metadataOutput(
            _ output: AVCaptureMetadataOutput,
            didOutput metadataObjects: [AVMetadataObject],
            from connection: AVCaptureConnection
        ) {
            guard !hasDetected else { return }
            
            guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                  let barcodeValue = metadataObject.stringValue else {
                return
            }
            
            hasDetected = true
            
            // Stop session
            captureSession?.stopRunning()
            
            // Notify
            onBarcodeDetected(barcodeValue)
        }
        
        func stopSession() {
            captureSession?.stopRunning()
            captureSession = nil
        }
    }
}

// MARK: - Quick Add Barcode Sheet

/// Lookup state for product information
enum ProductLookupState: Equatable {
    case idle
    case loading
    case found(ProductInfo)
    case notFound
    case error(String)

    static func == (lhs: ProductLookupState, rhs: ProductLookupState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading), (.notFound, .notFound):
            return true
        case (.found(let a), .found(let b)):
            return a == b
        case (.error(let a), .error(let b)):
            return a == b
        default:
            return false
        }
    }
}

struct QuickAddBarcodeSheet: View {
    let scannedBarcode: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppEnvironment.self) private var env

    @Query(sort: \Room.sortOrder) private var rooms: [Room]
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    @State private var name: String = ""
    @State private var brand: String = ""
    @State private var selectedRoom: Room?
    @State private var selectedCategory: Category?
    @State private var purchasePrice: String = ""
    @State private var isSaving = false
    @State private var lookupState: ProductLookupState = .idle

    var body: some View {
        NavigationStack {
            Form {
                // Barcode section with lookup status
                barcodeSection

                // Product info section (auto-filled or manual)
                Section("Item Details") {
                    TextField("Item Name *", text: $name)
                        .textInputAutocapitalization(.words)

                    TextField("Brand (optional)", text: $brand)
                        .textInputAutocapitalization(.words)

                    HStack {
                        Text(env.settings.currencySymbol)
                            .foregroundStyle(.secondary)
                        TextField("Purchase Price", text: $purchasePrice)
                            .keyboardType(.decimalPad)
                    }
                }

                // Location section
                Section("Location") {
                    Picker("Category", selection: $selectedCategory) {
                        Text("None").tag(nil as Category?)
                        ForEach(categories) { category in
                            Label(category.name, systemImage: category.iconName)
                                .tag(category as Category?)
                        }
                    }

                    Picker("Room", selection: $selectedRoom) {
                        Text("None").tag(nil as Room?)
                        ForEach(rooms) { room in
                            Label(room.name, systemImage: room.iconName)
                                .tag(room as Room?)
                        }
                    }
                }

                // Pro tip section
                if case .notFound = lookupState {
                    Section {
                        Label {
                            Text("Product not in database. Fill in details manually.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        } icon: {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveItem()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            }
            .task {
                await setupAndLookup()
            }
        }
    }

    // MARK: - Barcode Section

    @ViewBuilder
    private var barcodeSection: some View {
        Section {
            HStack {
                Image(systemName: "barcode")
                    .foregroundStyle(.secondary)
                Text(scannedBarcode)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)

                Spacer()

                // Lookup status indicator
                switch lookupState {
                case .idle:
                    EmptyView()
                case .loading:
                    ProgressView()
                        .scaleEffect(0.8)
                case .found:
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                case .notFound:
                    Image(systemName: "questionmark.circle")
                        .foregroundStyle(.orange)
                case .error:
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                }
            }
        } header: {
            Text("Scanned Barcode")
        } footer: {
            switch lookupState {
            case .loading:
                Text("Looking up product information...")
            case .found:
                Text("Product found! Details auto-filled below.")
            case .notFound:
                Text("Product not in database. Enter details manually.")
            case .error(let message):
                Text("Lookup failed: \(message)")
            case .idle:
                Text("Barcode will be saved with your item.")
            }
        }
    }

    // MARK: - Setup & Lookup

    private func setupAndLookup() async {
        // Set default room from settings
        if let defaultRoomId = env.settings.defaultRoomId,
           let defaultRoom = rooms.first(where: { $0.id.uuidString == defaultRoomId }) {
            selectedRoom = defaultRoom
        }

        // Perform product lookup
        lookupState = .loading

        let result = await env.productLookupService.lookup(barcode: scannedBarcode)

        switch result {
        case .success(let product):
            lookupState = .found(product)
            // Auto-fill fields
            if name.isEmpty && !product.name.isEmpty {
                name = product.name
            }
            if brand.isEmpty, let productBrand = product.brand {
                brand = productBrand
            }
            if purchasePrice.isEmpty, let msrp = product.msrp {
                purchasePrice = "\(msrp)"
            }
            // Try to match category from product info
            if selectedCategory == nil, let productCategory = product.category {
                selectedCategory = categories.first { cat in
                    cat.name.lowercased().contains(productCategory.lowercased()) ||
                    productCategory.lowercased().contains(cat.name.lowercased())
                }
            }

        case .notFound:
            lookupState = .notFound

        case .error(let error):
            lookupState = .error(error.localizedDescription)
        }
    }

    // MARK: - Save Item

    private func saveItem() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        isSaving = true

        let item = Item(
            name: trimmedName,
            brand: brand.isEmpty ? nil : brand,
            purchasePrice: Decimal(string: purchasePrice),
            currencyCode: env.settings.preferredCurrencyCode,
            category: selectedCategory,
            room: selectedRoom
        )
        item.barcode = scannedBarcode

        modelContext.insert(item)

        dismiss()
    }
}

// MARK: - Preview

#Preview("Barcode Scanner") {
    BarcodeScanView(isPresented: .constant(true)) { barcode in
        print("Scanned: \(barcode)")
    }
}

#Preview("Quick Add Barcode") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Item.self, Room.self, configurations: config)
    
    return QuickAddBarcodeSheet(scannedBarcode: "012345678905")
        .modelContainer(container)
        .environment(AppEnvironment())
}
