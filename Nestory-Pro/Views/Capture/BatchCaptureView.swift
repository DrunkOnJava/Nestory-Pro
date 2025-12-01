//
//  BatchCaptureView.swift
//  Nestory-Pro
//
//  F8-01: Batch capture camera interface
//

// ============================================================================
// F8-01: BatchCaptureView
// ============================================================================
// Full-screen camera interface optimized for rapid item capture.
// - Minimal UI: just capture button and queue counter
// - Haptic feedback on each capture
// - Continuous capture mode (stays in camera after shot)
// - Shows queue count badge
// - Swipe down or tap Done to exit
//
// SEE: TODO.md F8-01 | CaptureQueueService.swift | PendingCapture.swift
// ============================================================================

import SwiftUI
import AVFoundation
import CoreLocation

// MARK: - BatchCaptureView

struct BatchCaptureView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = BatchCaptureViewModel()

    var body: some View {
        ZStack {
            // Camera Preview
            CameraPreviewView(session: viewModel.captureSession)
                .ignoresSafeArea()

            // Overlay UI
            VStack {
                // Top Bar
                topBar

                Spacer()

                // Bottom Controls
                bottomControls
            }

            // Permission Denied Overlay
            if viewModel.permissionDenied {
                permissionDeniedView
            }

            // Flash feedback overlay
            if viewModel.showFlash {
                Color.white
                    .ignoresSafeArea()
                    .opacity(0.3)
                    .allowsHitTesting(false)
            }
        }
        .statusBarHidden()
        .task {
            await viewModel.setupCamera()
        }
        .onDisappear {
            viewModel.stopCamera()
        }
        .alert("Camera Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            // Close button
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial.opacity(0.8))
                    .clipShape(Circle())
            }
            .accessibilityLabel("Close camera")
            .accessibilityIdentifier("batchCapture.closeButton")

            Spacer()

            // Queue counter badge
            if viewModel.queueCount > 0 {
                queueBadge
            }
        }
        .padding(.horizontal, NestoryTheme.Metrics.paddingMedium)
        .padding(.top, NestoryTheme.Metrics.paddingMedium)
    }

    private var queueBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "tray.full.fill")
                .font(.system(size: 14, weight: .medium))

            Text("\(viewModel.queueCount)")
                .font(.system(size: 16, weight: .bold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(NestoryTheme.Colors.accent)
        .clipShape(Capsule())
        .accessibilityLabel("\(viewModel.queueCount) photos in queue")
        .accessibilityIdentifier("batchCapture.queueBadge")
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: NestoryTheme.Metrics.spacingLarge) {
            // Capture hint
            Text("Tap to capture • Photos added to queue")
                .font(NestoryTheme.Typography.caption)
                .foregroundStyle(.white.opacity(0.8))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial.opacity(0.6))
                .clipShape(Capsule())

            HStack(spacing: NestoryTheme.Metrics.spacingXXLarge) {
                // Spacer for centering
                Color.clear
                    .frame(width: 60, height: 60)

                // Capture button
                captureButton

                // Done button
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 60, height: 60)
                        .background(.ultraThinMaterial.opacity(0.8))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Done capturing")
                .accessibilityIdentifier("batchCapture.doneButton")
            }
        }
        .padding(.bottom, NestoryTheme.Metrics.paddingXLarge + 20)
    }

    private var captureButton: some View {
        Button {
            Task {
                await viewModel.capturePhoto()
            }
        } label: {
            ZStack {
                // Outer ring
                Circle()
                    .stroke(.white, lineWidth: 4)
                    .frame(width: 80, height: 80)

                // Inner fill
                Circle()
                    .fill(.white)
                    .frame(width: 68, height: 68)
                    .scaleEffect(viewModel.isCapturing ? 0.9 : 1.0)
                    .animation(.easeInOut(duration: 0.1), value: viewModel.isCapturing)
            }
        }
        .disabled(viewModel.isCapturing)
        .accessibilityLabel("Take photo")
        .accessibilityHint("Double tap to capture a photo")
        .accessibilityIdentifier("batchCapture.captureButton")
    }

    // MARK: - Permission Denied View

    private var permissionDeniedView: some View {
        VStack(spacing: NestoryTheme.Metrics.spacingLarge) {
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundStyle(NestoryTheme.Colors.muted)

            Text("Camera Access Required")
                .font(NestoryTheme.Typography.title2)
                .fontWeight(.semibold)

            Text("Please enable camera access in Settings to use batch capture mode.")
                .font(NestoryTheme.Typography.body)
                .foregroundStyle(NestoryTheme.Colors.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, NestoryTheme.Metrics.paddingXLarge)

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Open Settings")
                    .font(NestoryTheme.Typography.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, NestoryTheme.Metrics.paddingXLarge)
                    .padding(.vertical, NestoryTheme.Metrics.paddingMedium)
                    .background(NestoryTheme.Colors.accent)
                    .clipShape(Capsule())
            }
            .padding(.top, NestoryTheme.Metrics.spacingMedium)

            Button("Cancel") {
                dismiss()
            }
            .font(NestoryTheme.Typography.subheadline)
            .foregroundStyle(NestoryTheme.Colors.muted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(NestoryTheme.Colors.background)
    }
}

// MARK: - BatchCaptureViewModel

@Observable
@MainActor
final class BatchCaptureViewModel {
    // Camera
    // nonisolated(unsafe) because AVCaptureSession is thread-safe for start/stop
    // and must be started/stopped on background thread per Apple docs
    nonisolated(unsafe) let captureSession = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var photoCaptureDelegate: PhotoCaptureDelegate?

    // State
    var isCapturing = false
    var showFlash = false
    var queueCount = 0
    var permissionDenied = false
    var showError = false
    var errorMessage = ""

    // Location
    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocationCoordinate2D?

    // Services
    private let queueService = CaptureQueueService.shared

    // MARK: - Camera Setup

    func setupCamera() async {
        // Check permission
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .authorized:
            await configureSession()
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if granted {
                await configureSession()
            } else {
                permissionDenied = true
            }
        case .denied, .restricted:
            permissionDenied = true
        @unknown default:
            permissionDenied = true
        }

        // Load current queue count
        queueCount = await queueService.pendingCount
    }

    private func configureSession() async {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .photo

        // Add video input
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            showError(message: "Camera not available")
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
        } catch {
            showError(message: "Failed to access camera: \(error.localizedDescription)")
            return
        }

        // Add photo output
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
            photoOutput.isHighResolutionCaptureEnabled = true
        }

        captureSession.commitConfiguration()

        // Start session on background thread
        startCaptureSession()
    }

    func stopCamera() {
        stopCaptureSession()
    }

    // MARK: - Camera Session Helpers (nonisolated for background thread access)

    /// Starts the capture session on a background thread
    /// Must be nonisolated to allow DispatchQueue to capture session
    nonisolated private func startCaptureSession() {
        let session = captureSession
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }

    /// Stops the capture session on a background thread
    nonisolated private func stopCaptureSession() {
        let session = captureSession
        DispatchQueue.global(qos: .userInitiated).async {
            session.stopRunning()
        }
    }

    // MARK: - Photo Capture

    func capturePhoto() async {
        guard !isCapturing else { return }

        isCapturing = true

        // Trigger haptic
        HapticManager.mediumImpact()

        // Flash feedback
        withAnimation(.easeOut(duration: 0.1)) {
            showFlash = true
        }

        // Configure capture settings
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .auto

        // Create delegate and capture
        let delegate = PhotoCaptureDelegate { [weak self] image in
            await self?.handleCapturedPhoto(image)
        }
        photoCaptureDelegate = delegate

        photoOutput.capturePhoto(with: settings, delegate: delegate)
    }

    private func handleCapturedPhoto(_ image: UIImage?) async {
        defer {
            isCapturing = false
            withAnimation(.easeIn(duration: 0.15)) {
                showFlash = false
            }
        }

        guard let image else {
            showError(message: "Failed to capture photo")
            HapticManager.error()
            return
        }

        do {
            // Add to queue
            _ = try await queueService.addCapture(
                image: image,
                location: currentLocation
            )

            // Update count
            queueCount = await queueService.pendingCount

            // Success haptic
            HapticManager.success()

        } catch {
            showError(message: "Failed to save photo: \(error.localizedDescription)")
            HapticManager.error()
        }
    }

    // MARK: - Helpers

    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}

// MARK: - Photo Capture Delegate

private final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate, Sendable {
    private let completion: @Sendable (UIImage?) async -> Void

    init(completion: @escaping @Sendable (UIImage?) async -> Void) {
        self.completion = completion
    }

    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        let image: UIImage?
        if let data = photo.fileDataRepresentation() {
            image = UIImage(data: data)
        } else {
            image = nil
        }

        Task { @MainActor in
            await completion(image)
        }
    }
}

// MARK: - Camera Preview View

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.session = session
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        // Session doesn't change
    }
}

final class CameraPreviewUIView: UIView {
    var session: AVCaptureSession? {
        didSet {
            guard let session else { return }
            previewLayer.session = session
        }
    }

    private var previewLayer: AVCaptureVideoPreviewLayer {
        // swiftlint:disable:next force_cast
        layer as! AVCaptureVideoPreviewLayer
    }

    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        previewLayer.videoGravity = .resizeAspectFill
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Batch Capture") {
    BatchCaptureView()
}
#endif
