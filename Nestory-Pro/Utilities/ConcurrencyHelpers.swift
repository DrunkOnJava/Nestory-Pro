//
//  ConcurrencyHelpers.swift
//  Nestory-Pro
//
//  Created by Gemini on 11/29/25.
//

import UIKit

/// A wrapper around UIImage that asserts Sendable conformance for transferring
/// images between actors (e.g. MainActor -> Service).
///
/// **Swift 6 Concurrency Best Practice:**
/// `UIImage` is not yet `Sendable`. To prevent strict concurrency warnings when passing
/// images to background actors (like `PhotoStorageService`), we wrap it in this
/// `@unchecked Sendable` container.
///
/// - Important: Only wrap images that are immutable and safe to share.
///
/// Usage:
/// ```swift
/// let sendableImage = SendableImage(originalImage)
/// await service.process(sendableImage)
/// ```
struct SendableImage: @unchecked Sendable {
    let image: UIImage
    
    init(_ image: UIImage) {
        self.image = image
    }
}
