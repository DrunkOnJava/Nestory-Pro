//
//  PhotoCaptureView.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/28/25.
//

import SwiftUI
import PhotosUI
import AVFoundation

/// Photo capture view with camera and photo library support
/// Handles permissions gracefully with user-facing rationale
struct PhotoCaptureView: View {
    @Binding var selectedImage: UIImage?
    @Binding var isPresented: Bool

    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingPermissionAlert = false
    @State private var permissionAlertConfig: PermissionAlertConfig?
    @State private var photoPickerItem: PhotosPickerItem?

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.accentColor)

                Text("Add Photo")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Take a photo or choose from your library")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 32)

            Spacer()

            // Action Buttons
            VStack(spacing: 16) {
                Button {
                    checkCameraPermission()
                } label: {
                    Label("Take Photo", systemImage: "camera.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("photoCaptureView.takePhotoButton")

                PhotosPicker(selection: $photoPickerItem, matching: .images) {
                    Label("Choose from Library", systemImage: "photo.on.rectangle")
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
                .accessibilityIdentifier("photoCaptureView.chooseFromLibraryButton")
            }
            .padding(.horizontal, 24)

            Spacer()

            // Cancel Button
            Button("Cancel") {
                isPresented = false
            }
            .foregroundStyle(.secondary)
            .padding(.bottom, 32)
            .accessibilityIdentifier("photoCaptureView.cancelButton")
        }
        .sheet(isPresented: $showingCamera) {
            ImagePickerView(
                sourceType: .camera,
                selectedImage: $selectedImage,
                onImageSelected: {
                    isPresented = false
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
    }

    // MARK: - Permission Handling

    private func checkCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .authorized:
            showingCamera = true

        case .notDetermined:
            // Show rationale before requesting
            permissionAlertConfig = PermissionAlertConfig(
                title: "Camera Access Required",
                message: "Nestory Pro needs camera access to take photos of your items for documentation. This helps create a complete visual record for insurance purposes.",
                type: .camera
            )
            showingPermissionAlert = true

            // Request permission
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
                message: "Please enable camera access in Settings to take photos of your items.",
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
                    selectedImage = image
                    isPresented = false
                }
            }
        } catch {
            print("Failed to load photo: \(error.localizedDescription)")
        }
    }
}

// MARK: - UIImagePickerController Wrapper

struct ImagePickerView: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    @Binding var selectedImage: UIImage?
    var onImageSelected: (() -> Void)?

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // No updates needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePickerView

        init(_ parent: ImagePickerView) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
                parent.onImageSelected?()
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Permission Alert Configuration

struct PermissionAlertConfig {
    let title: String
    let message: String
    let type: PermissionType

    enum PermissionType {
        case camera
        case photoLibrary
    }
}

// MARK: - Previews

#Preview("Photo Capture View") {
    struct PreviewWrapper: View {
        @State private var selectedImage: UIImage?
        @State private var isPresented = true

        var body: some View {
            PhotoCaptureView(
                selectedImage: $selectedImage,
                isPresented: $isPresented
            )
        }
    }

    return PreviewWrapper()
}

#Preview("With Selected Image") {
    struct PreviewWrapper: View {
        @State private var selectedImage: UIImage? = UIImage(systemName: "photo")
        @State private var isPresented = true

        var body: some View {
            VStack {
                PhotoCaptureView(
                    selectedImage: $selectedImage,
                    isPresented: $isPresented
                )

                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .padding()
                }
            }
        }
    }

    return PreviewWrapper()
}
