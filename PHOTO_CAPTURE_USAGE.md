# PhotoCaptureView Usage Guide

## Overview

`PhotoCaptureView` is a reusable SwiftUI component for capturing photos via camera or selecting from the photo library. It handles permissions gracefully with user-facing rationale messages.

## Basic Usage

```swift
import SwiftUI

struct ExampleView: View {
    @State private var selectedImage: UIImage?
    @State private var showingPhotoPicker = false

    var body: some View {
        VStack {
            Button("Add Photo") {
                showingPhotoPicker = true
            }

            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
            }
        }
        .sheet(isPresented: $showingPhotoPicker) {
            PhotoCaptureView(
                selectedImage: $selectedImage,
                isPresented: $showingPhotoPicker
            )
        }
    }
}
```

## Integration with QuickAddItemSheet (Task 2.2.2)

When implementing `QuickAddItemSheet.swift`, use PhotoCaptureView like this:

```swift
struct QuickAddItemSheet: View {
    @Binding var capturedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    @State private var itemName = ""
    @State private var selectedRoom: Room?
    @State private var showingPhotoPicker = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Item Name *", text: $itemName)
                }

                Section {
                    Picker("Room", selection: $selectedRoom) {
                        Text("None").tag(nil as Room?)
                        // Room list...
                    }
                }

                Section {
                    if let image = capturedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                    }

                    Button("Change Photo") {
                        showingPhotoPicker = true
                    }
                }
            }
            .navigationTitle("Quick Add Item")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        // Save item with capturedImage
                    }
                    .disabled(itemName.isEmpty)
                }
            }
        }
        .sheet(isPresented: $showingPhotoPicker) {
            PhotoCaptureView(
                selectedImage: $capturedImage,
                isPresented: $showingPhotoPicker
            )
        }
    }
}
```

## Features

### Camera Integration
- Uses `UIImagePickerController` for camera access
- Checks camera authorization status before presenting
- Shows user-friendly permission rationale

### Photo Library Integration
- Uses iOS 17+ `PhotosPicker` for modern photo selection
- No permission prompts needed (system handles it)
- Supports loading transferable image data

### Permission Handling
- **Not Determined**: Shows rationale alert before requesting
- **Denied/Restricted**: Shows alert with option to open Settings
- **Authorized**: Immediately presents camera

### Accessibility
- All buttons have accessibility identifiers:
  - `photoCaptureView.takePhotoButton`
  - `photoCaptureView.chooseFromLibraryButton`
  - `photoCaptureView.cancelButton`

## Info.plist Requirements

The following permissions are already configured in `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Nestory Pro needs camera access to take photos of your items for documentation and insurance records.</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>Nestory Pro needs photo library access to select photos of your items for documentation and insurance records.</string>
```

## Architecture Notes

### Bindings
The view uses two bindings:
- `selectedImage: Binding<UIImage?>` - The captured/selected image
- `isPresented: Binding<Bool>` - Controls sheet presentation

The view automatically dismisses (sets `isPresented = false`) when:
- User selects an image from camera or library
- User taps Cancel button

### Photo Processing
After selection, the parent view should:
1. Receive the `UIImage` via the binding
2. Save it using `PhotoStorageService` (Task 2.1.1)
3. Create an `ItemPhoto` model with the file identifier
4. Attach to the `Item` being created/edited

Example with PhotoStorageService:
```swift
if let image = selectedImage {
    let photoService = PhotoStorageService()
    let fileIdentifier = try await photoService.savePhoto(image, for: item.id)

    let itemPhoto = ItemPhoto(
        fileIdentifier: fileIdentifier,
        isPrimary: item.photos.isEmpty, // First photo is primary
        sortOrder: item.photos.count
    )
    itemPhoto.item = item
    modelContext.insert(itemPhoto)
}
```

## Testing

The view can be tested in Xcode Previews with the included preview configurations:
- Default state
- State with selected image

For UI tests, use the accessibility identifiers to interact with buttons.

## Next Steps (TODO.md Tasks)

1. **Task 2.2.2**: Create `QuickAddItemSheet` to use this view
2. **Task 2.2.3**: Wire `CaptureTab` to show segmented control with Photo option
3. **Task 2.1.1**: Integrate with `PhotoStorageService` for saving images

## Known Limitations

- No image cropping/editing (future enhancement)
- No multi-photo selection (use PhotosPicker directly for that)
- Camera not available on simulator (use library instead)

---

**Created**: 2025-11-28
**Task**: 2.2.1 - Create PhotoCaptureView with camera integration
