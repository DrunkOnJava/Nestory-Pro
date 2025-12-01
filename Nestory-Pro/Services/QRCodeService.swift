//
//  QRCodeService.swift
//  Nestory-Pro
//
//  Created for v1.2 - F2 QR Code Label Generation Feature
//

// ============================================================================
// QR CODE SERVICE - Task F2
// ============================================================================
// Generates QR codes for items using CoreImage's CIQRCodeGenerator.
// QR codes contain deep links: nestory://item/{uuid}
//
// FEATURES:
// - Generate QR code images at various sizes
// - Label templates (small, medium, large)
// - Batch generation for rooms/containers
// - URL scheme parsing for "scan to find"
//
// SEE: TODO-FEATURES.md F2 | LabelGeneratorView.swift | Info.plist
// ============================================================================

import SwiftUI
import CoreImage.CIFilterBuiltins
import OSLog

// MARK: - Label Size Configuration

/// Label template sizes for printing
enum LabelSize: String, CaseIterable, Identifiable, Sendable {
    case small = "small"     // 1" x 1" - QR only
    case medium = "medium"   // 2" x 1" - QR + item name
    case large = "large"     // 3" x 2" - QR + name + location + value

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .small: return "Small (1\" x 1\")"
        case .medium: return "Medium (2\" x 1\")"
        case .large: return "Large (3\" x 2\")"
        }
    }

    var description: String {
        switch self {
        case .small: return "QR code only"
        case .medium: return "QR code + item name"
        case .large: return "QR code + name + location + value"
        }
    }

    /// QR code size in points
    var qrSize: CGFloat {
        switch self {
        case .small: return 72   // 1 inch at 72 DPI
        case .medium: return 72  // 1 inch QR in 2x1 label
        case .large: return 108  // 1.5 inch QR in 3x2 label
        }
    }

    /// Label width in points (72 points = 1 inch)
    var labelWidth: CGFloat {
        switch self {
        case .small: return 72
        case .medium: return 144
        case .large: return 216
        }
    }

    /// Label height in points
    var labelHeight: CGFloat {
        switch self {
        case .small: return 72
        case .medium: return 72
        case .large: return 144
        }
    }
}

// MARK: - QR Code Service

/// Service for generating QR codes for inventory items
final class QRCodeService: Sendable {

    // MARK: - Properties

    private let logger = Logger(subsystem: "com.drunkonjava.nestory", category: "QRCodeService")
    private let context = CIContext()

    /// URL scheme for deep links
    static let urlScheme = "nestory"

    // MARK: - Singleton

    static let shared = QRCodeService()

    // MARK: - Initialization

    init() {}

    // MARK: - QR Code Generation

    /// Generates a QR code image for an item
    /// - Parameters:
    ///   - itemID: The UUID of the item
    ///   - size: Desired QR code size in points
    ///   - correctionLevel: Error correction level (L, M, Q, H)
    /// - Returns: UIImage of the QR code, or nil if generation fails
    func generateQRCode(for itemID: UUID, size: CGFloat = 200, correctionLevel: String = "M") -> UIImage? {
        let urlString = "\(Self.urlScheme)://item/\(itemID.uuidString)"

        guard let data = urlString.data(using: .utf8) else {
            logger.error("[QRCode] Failed to encode URL string")
            return nil
        }

        // Create QR code filter
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue(correctionLevel, forKey: "inputCorrectionLevel")

        guard let outputImage = filter.outputImage else {
            logger.error("[QRCode] Failed to generate QR code image")
            return nil
        }

        // Scale to desired size
        let scaleX = size / outputImage.extent.width
        let scaleY = size / outputImage.extent.height
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        // Convert to UIImage
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            logger.error("[QRCode] Failed to create CGImage")
            return nil
        }

        logger.info("[QRCode] Generated QR code for item: \(itemID.uuidString)")
        return UIImage(cgImage: cgImage)
    }

    // MARK: - URL Parsing

    /// Parses a Nestory deep link URL and extracts the item ID
    /// - Parameter url: The URL to parse (e.g., nestory://item/{uuid})
    /// - Returns: The item UUID if valid, nil otherwise
    func parseDeepLink(_ url: URL) -> UUID? {
        guard url.scheme == Self.urlScheme else {
            logger.warning("[QRCode] Invalid URL scheme: \(url.scheme ?? "nil")")
            return nil
        }

        guard url.host == "item" else {
            logger.warning("[QRCode] Invalid URL host: \(url.host ?? "nil")")
            return nil
        }

        // Path should be /{uuid}
        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let uuid = UUID(uuidString: path) else {
            logger.warning("[QRCode] Invalid UUID in path: \(path)")
            return nil
        }

        logger.info("[QRCode] Parsed deep link for item: \(uuid.uuidString)")
        return uuid
    }

    /// Constructs a deep link URL for an item
    /// - Parameter itemID: The item's UUID
    /// - Returns: URL for the deep link
    func deepLinkURL(for itemID: UUID) -> URL? {
        URL(string: "\(Self.urlScheme)://item/\(itemID.uuidString)")
    }
}

// MARK: - Label Image Generation

extension QRCodeService {

    /// Generates a label image with QR code and optional text
    /// - Parameters:
    ///   - item: The item to create label for
    ///   - size: Label template size
    ///   - settings: Settings for currency formatting
    /// - Returns: UIImage of the complete label
    @MainActor
    func generateLabel(for item: Item, size: LabelSize, settings: SettingsManager) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size.labelWidth, height: size.labelHeight))

        return renderer.image { ctx in
            // White background
            UIColor.white.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: size.labelWidth, height: size.labelHeight))

            // Generate QR code
            guard let qrImage = generateQRCode(for: item.id, size: size.qrSize) else {
                return
            }

            // Draw based on label size
            switch size {
            case .small:
                // QR only, centered
                qrImage.draw(in: CGRect(x: 0, y: 0, width: size.qrSize, height: size.qrSize))

            case .medium:
                // QR on left, name on right
                let qrRect = CGRect(x: 4, y: 4, width: size.qrSize - 8, height: size.qrSize - 8)
                qrImage.draw(in: qrRect)

                // Item name to the right of QR
                let textX = size.qrSize + 4
                let textWidth = size.labelWidth - textX - 4
                let textRect = CGRect(x: textX, y: 8, width: textWidth, height: size.labelHeight - 16)

                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .left
                paragraphStyle.lineBreakMode = .byTruncatingTail

                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 10, weight: .semibold),
                    .foregroundColor: UIColor.black,
                    .paragraphStyle: paragraphStyle
                ]

                item.name.draw(in: textRect, withAttributes: attributes)

            case .large:
                // QR on left, info on right
                let padding: CGFloat = 8
                let qrRect = CGRect(x: padding, y: padding, width: size.qrSize - padding, height: size.qrSize - padding)
                qrImage.draw(in: qrRect)

                // Text area to the right
                let textX = size.qrSize + padding
                let textWidth = size.labelWidth - textX - padding

                // Item name (bold)
                let nameRect = CGRect(x: textX, y: padding, width: textWidth, height: 20)
                let nameAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12, weight: .bold),
                    .foregroundColor: UIColor.black
                ]
                item.name.draw(in: nameRect, withAttributes: nameAttributes)

                // Location (room + category)
                let locationY = padding + 24
                let locationRect = CGRect(x: textX, y: locationY, width: textWidth, height: 16)
                let locationText = [item.room?.name, item.category?.name].compactMap { $0 }.joined(separator: " / ")
                let locationAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 9, weight: .regular),
                    .foregroundColor: UIColor.darkGray
                ]
                locationText.draw(in: locationRect, withAttributes: locationAttributes)

                // Value
                if let value = item.purchasePrice {
                    let valueY = locationY + 18
                    let valueRect = CGRect(x: textX, y: valueY, width: textWidth, height: 16)
                    let valueText = settings.formatCurrency(value)
                    let valueAttributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 10, weight: .medium),
                        .foregroundColor: UIColor.black
                    ]
                    valueText.draw(in: valueRect, withAttributes: valueAttributes)
                }

                // QR code URL at bottom
                let urlY = size.labelHeight - 20
                let urlRect = CGRect(x: padding, y: urlY, width: size.labelWidth - padding * 2, height: 14)
                let urlText = "nestory://item/\(item.id.uuidString.prefix(8))..."
                let urlAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 7, weight: .light),
                    .foregroundColor: UIColor.gray
                ]
                urlText.draw(in: urlRect, withAttributes: urlAttributes)
            }
        }
    }

    /// Generates labels for multiple items (batch)
    /// - Parameters:
    ///   - items: Array of items to generate labels for
    ///   - size: Label template size
    ///   - settings: Settings for currency formatting
    /// - Returns: Array of (Item, UIImage) tuples
    @MainActor
    func generateLabels(for items: [Item], size: LabelSize, settings: SettingsManager) -> [(item: Item, image: UIImage)] {
        var results: [(Item, UIImage)] = []
        for item in items {
            if let image = generateLabel(for: item, size: size, settings: settings) {
                results.append((item, image))
            }
        }
        logger.info("[QRCode] Generated \(results.count) labels for \(items.count) items")
        return results
    }
}
