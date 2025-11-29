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
import AVFoundation

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
    
    // MARK: - Scanning Overlay
    
    private var scanningOverlay: some View {
        VStack {
            Spacer()
            
            // Scanning frame
            RoundedRectangle(cornerRadius: 12)
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
                        .stroke(Color.accentColor, lineWidth: stroke)
                    }
                )
            
            Spacer()
            
            // Instructions
            VStack(spacing: 12) {
                if isProcessing {
                    ProgressView()
                        .tint(.white)
                    Text("Processing barcode...")
                        .font(.headline)
                        .foregroundStyle(.white)
                } else {
                    Text("Position barcode within frame")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Text("Supports UPC, EAN, QR codes, and more")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.bottom, 48)
        }
    }
    
    // MARK: - Permission Denied View
    
    private var permissionDeniedView: some View {
        VStack(spacing: 24) {
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("Camera Access Required")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Nestory needs camera access to scan barcodes on your items.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button("Enable Camera Access") {
                showingPermissionAlert = true
            }
            .buttonStyle(.borderedProminent)
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
            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
            }
            
            // Handle view resize
            DispatchQueue.main.async {
                NotificationCenter.default.addObserver(
                    forName: UIDevice.orientationDidChangeNotification,
                    object: nil,
                    queue: .main
                ) { [weak self, weak view] _ in
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
        
        deinit {
            captureSession?.stopRunning()
        }
    }
}

// MARK: - Quick Add Barcode Sheet

struct QuickAddBarcodeSheet: View {
    let scannedBarcode: String
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppEnvironment.self) private var env
    
    @Query(sort: \Room.sortOrder) private var rooms: [Room]
    
    @State private var name: String = ""
    @State private var brand: String = ""
    @State private var selectedRoom: Room?
    @State private var isSaving = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Image(systemName: "barcode")
                            .foregroundStyle(.secondary)
                        Text(scannedBarcode)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Scanned Barcode")
                } footer: {
                    Text("This barcode will be saved with your item for future reference.")
                }
                
                Section("Item Details") {
                    TextField("Item Name *", text: $name)
                        .textInputAutocapitalization(.words)
                    
                    TextField("Brand (optional)", text: $brand)
                        .textInputAutocapitalization(.words)
                }
                
                Section("Location") {
                    Picker("Room", selection: $selectedRoom) {
                        Text("None").tag(nil as Room?)
                        ForEach(rooms) { room in
                            Label(room.name, systemImage: room.iconName)
                                .tag(room as Room?)
                        }
                    }
                }
                
                Section {
                    Text("In v1.0, barcodes are stored for your reference. Automatic product lookup is coming in a future update.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
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
            }
            .task {
                // Set default room from settings
                if let defaultRoomId = env.settings.defaultRoomId,
                   let defaultRoom = rooms.first(where: { $0.id.uuidString == defaultRoomId }) {
                    selectedRoom = defaultRoom
                }
            }
        }
    }
    
    private func saveItem() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        isSaving = true
        
        let item = Item(
            name: trimmedName,
            brand: brand.isEmpty ? nil : brand,
            currencyCode: env.settings.preferredCurrencyCode,
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
