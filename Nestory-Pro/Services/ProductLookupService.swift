//
//  ProductLookupService.swift
//  Nestory-Pro
//
//  Created for v1.2 - F1 Barcode Scanning Feature
//

// ============================================================================
// PRODUCT LOOKUP SERVICE - Task F1
// ============================================================================
// Provides product information lookup from barcode/UPC numbers.
// Uses UPCitemdb free trial API (100 requests/day, 15K/month).
//
// FEATURES:
// - Lookup product by UPC/EAN barcode
// - Returns name, brand, category, description, image URL
// - In-memory caching to reduce API calls
// - Graceful offline handling
//
// API REFERENCE:
// - Endpoint: https://api.upcitemdb.com/prod/trial/lookup
// - Docs: https://www.upcitemdb.com/api/explorer#!/lookup/get_trial_lookup
//
// SEE: TODO-FEATURES.md F1 | BarcodeScanView.swift | QuickAddBarcodeSheet
// ============================================================================

@preconcurrency import Foundation
import OSLog

// MARK: - Product Info Model

/// Product information returned from barcode lookup
struct ProductInfo: Sendable, Equatable {
    let barcode: String
    let name: String
    let brand: String?
    let category: String?
    let description: String?
    let imageURL: URL?
    let msrp: Decimal?

    /// Creates an empty result for manual entry fallback
    static func notFound(barcode: String) -> ProductInfo {
        ProductInfo(
            barcode: barcode,
            name: "",
            brand: nil,
            category: nil,
            description: nil,
            imageURL: nil,
            msrp: nil
        )
    }
}

// MARK: - Lookup Error

enum ProductLookupError: LocalizedError, Sendable {
    case networkError(Error)
    case invalidBarcode
    case notFound
    case rateLimitExceeded
    case apiError(String)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidBarcode:
            return "Invalid barcode format"
        case .notFound:
            return "Product not found in database"
        case .rateLimitExceeded:
            return "Daily lookup limit reached. Try again tomorrow."
        case .apiError(let message):
            return "API error: \(message)"
        case .decodingError:
            return "Failed to parse product data"
        }
    }
}

// MARK: - Lookup Result

enum ProductLookupResult: Sendable {
    case success(ProductInfo)
    case notFound(barcode: String)
    case error(ProductLookupError)

    var product: ProductInfo? {
        if case .success(let info) = self { return info }
        return nil
    }

    var isFound: Bool {
        if case .success = self { return true }
        return false
    }
}

// MARK: - Product Lookup Service

/// Service for looking up product information from barcodes
/// Uses UPCitemdb free trial API with in-memory caching
actor ProductLookupService {

    // MARK: - Properties

    private let logger = Logger(subsystem: "com.drunkonjava.nestory", category: "ProductLookupService")
    private let urlSession: URLSession

    /// In-memory cache to reduce API calls
    private var cache: [String: ProductLookupResult] = [:]

    /// Cache expiration (24 hours)
    private let cacheExpiration: TimeInterval = 86400
    private var cacheTimestamps: [String: Date] = [:]

    /// API endpoint
    private let baseURL = "https://api.upcitemdb.com/prod/trial/lookup"

    // MARK: - Singleton (for app use)

    static let shared = ProductLookupService()

    // MARK: - Initialization

    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    // MARK: - Public API

    /// Looks up product information for a barcode
    /// - Parameter barcode: UPC, EAN, or other barcode string
    /// - Returns: ProductLookupResult with product info, not found, or error
    func lookup(barcode: String) async -> ProductLookupResult {
        let cleanBarcode = barcode.trimmingCharacters(in: .whitespacesAndNewlines)

        // Validate barcode format
        guard isValidBarcode(cleanBarcode) else {
            logger.warning("[ProductLookup] Invalid barcode format: \(cleanBarcode)")
            return .error(.invalidBarcode)
        }

        // Check cache first
        if let cached = getCachedResult(for: cleanBarcode) {
            logger.info("[ProductLookup] Cache hit for: \(cleanBarcode)")
            return cached
        }

        // Make API request
        logger.info("[ProductLookup] Looking up barcode: \(cleanBarcode)")

        guard let url = URL(string: "\(baseURL)?upc=\(cleanBarcode)") else {
            return .error(.invalidBarcode)
        }

        do {
            let (data, response) = try await urlSession.data(from: url)

            // Check HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                return .error(.networkError(URLError(.badServerResponse)))
            }

            switch httpResponse.statusCode {
            case 200:
                let result = await parseResponse(data: data, barcode: cleanBarcode)
                cacheResult(result, for: cleanBarcode)
                return result

            case 400:
                logger.warning("[ProductLookup] Bad request for: \(cleanBarcode)")
                return .error(.invalidBarcode)

            case 404:
                logger.info("[ProductLookup] Product not found: \(cleanBarcode)")
                let result = ProductLookupResult.notFound(barcode: cleanBarcode)
                cacheResult(result, for: cleanBarcode)
                return result

            case 429:
                logger.warning("[ProductLookup] Rate limit exceeded")
                return .error(.rateLimitExceeded)

            default:
                logger.error("[ProductLookup] API error: \(httpResponse.statusCode)")
                return .error(.apiError("HTTP \(httpResponse.statusCode)"))
            }

        } catch {
            logger.error("[ProductLookup] Network error: \(error.localizedDescription)")
            return .error(.networkError(error))
        }
    }

    /// Clears the lookup cache
    func clearCache() {
        cache.removeAll()
        cacheTimestamps.removeAll()
        logger.info("[ProductLookup] Cache cleared")
    }

    // MARK: - Private Helpers

    /// Validates barcode format (UPC-A, UPC-E, EAN-8, EAN-13, etc.)
    private func isValidBarcode(_ barcode: String) -> Bool {
        // Must be numeric and reasonable length
        let digits = barcode.filter { $0.isNumber }
        guard digits.count == barcode.count else { return false }

        // Valid lengths: 6-14 digits (covers UPC-E to EAN-14)
        return (6...14).contains(barcode.count)
    }

    /// Gets cached result if still valid
    private func getCachedResult(for barcode: String) -> ProductLookupResult? {
        guard let result = cache[barcode],
              let timestamp = cacheTimestamps[barcode],
              Date().timeIntervalSince(timestamp) < cacheExpiration else {
            return nil
        }
        return result
    }

    /// Caches a lookup result
    private func cacheResult(_ result: ProductLookupResult, for barcode: String) {
        cache[barcode] = result
        cacheTimestamps[barcode] = Date()
    }

    /// Parses UPCitemdb API response
    /// Decoding happens on MainActor to satisfy Swift 6 concurrency requirements
    private func parseResponse(data: Data, barcode: String) async -> ProductLookupResult {
        // Decode on MainActor where the synthesized Decodable conformance lives
        let parseResult = await MainActor.run { () -> Result<(String, String, String, String, String?, Decimal?), Error> in
            do {
                let response = try JSONDecoder().decode(UPCitemdbResponse.self, from: data)
                guard let item = response.items.first else {
                    return .failure(NSError(domain: "ProductLookup", code: 404, userInfo: nil))
                }
                // Extract values we need (avoid passing MainActor-isolated types across isolation boundaries)
                let msrpValue = item.msrp.flatMap { Decimal(string: $0) }
                return .success((item.title, item.brand, item.category, item.description, item.images.first, msrpValue))
            } catch {
                return .failure(error)
            }
        }

        switch parseResult {
        case .success(let (title, brand, category, description, imageURLString, msrp)):
            // Check if items found
            if title.isEmpty {
                logger.info("[ProductLookup] No items in response for: \(barcode)")
                return .notFound(barcode: barcode)
            }

            let product = ProductInfo(
                barcode: barcode,
                name: title,
                brand: brand.isEmpty ? nil : brand,
                category: category.isEmpty ? nil : category,
                description: description.isEmpty ? nil : description,
                imageURL: imageURLString.flatMap { URL(string: $0) },
                msrp: msrp
            )

            logger.info("[ProductLookup] Found product: \(product.name)")
            return .success(product)

        case .failure(let error):
            if (error as NSError).code == 404 {
                logger.info("[ProductLookup] No items in response for: \(barcode)")
                return .notFound(barcode: barcode)
            }
            logger.error("[ProductLookup] Decoding error: \(error.localizedDescription)")
            return .error(.decodingError)
        }
    }
}

// MARK: - UPCitemdb API Response Models
// Note: These types are nonisolated and Sendable to work within the actor context
// (project uses @MainActor default isolation which would otherwise conflict)

/// Response from UPCitemdb API
private struct UPCitemdbResponse: Codable, Sendable {
    nonisolated let code: String
    nonisolated let total: Int
    nonisolated let offset: Int
    nonisolated let items: [UPCitemdbItem]
}

/// Individual item from UPCitemdb response
private struct UPCitemdbItem: Codable, Sendable {
    nonisolated let ean: String
    nonisolated let title: String
    nonisolated let description: String
    nonisolated let upc: String
    nonisolated let brand: String
    nonisolated let model: String
    nonisolated let color: String
    nonisolated let size: String
    nonisolated let dimension: String
    nonisolated let weight: String
    nonisolated let category: String
    nonisolated let currency: String
    nonisolated let lowestRecordedPrice: Double?
    nonisolated let highestRecordedPrice: Double?
    nonisolated let images: [String]
    nonisolated let offers: [UPCitemdbOffer]
    nonisolated let asin: String?
    nonisolated let elid: String?

    // Custom keys to handle optional/missing fields gracefully
    enum CodingKeys: String, CodingKey {
        case ean, title, description, upc, brand, model, color, size
        case dimension, weight, category, currency
        case lowestRecordedPrice = "lowest_recorded_price"
        case highestRecordedPrice = "highest_recorded_price"
        case images, offers, asin, elid
    }

    /// MSRP if available (from offers or recorded prices)
    nonisolated var msrp: String? {
        if let highest = highestRecordedPrice, highest > 0 {
            return String(format: "%.2f", highest)
        }
        return nil
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        ean = try container.decodeIfPresent(String.self, forKey: .ean) ?? ""
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        upc = try container.decodeIfPresent(String.self, forKey: .upc) ?? ""
        brand = try container.decodeIfPresent(String.self, forKey: .brand) ?? ""
        model = try container.decodeIfPresent(String.self, forKey: .model) ?? ""
        color = try container.decodeIfPresent(String.self, forKey: .color) ?? ""
        size = try container.decodeIfPresent(String.self, forKey: .size) ?? ""
        dimension = try container.decodeIfPresent(String.self, forKey: .dimension) ?? ""
        weight = try container.decodeIfPresent(String.self, forKey: .weight) ?? ""
        category = try container.decodeIfPresent(String.self, forKey: .category) ?? ""
        currency = try container.decodeIfPresent(String.self, forKey: .currency) ?? ""
        lowestRecordedPrice = try container.decodeIfPresent(Double.self, forKey: .lowestRecordedPrice)
        highestRecordedPrice = try container.decodeIfPresent(Double.self, forKey: .highestRecordedPrice)
        images = try container.decodeIfPresent([String].self, forKey: .images) ?? []
        offers = try container.decodeIfPresent([UPCitemdbOffer].self, forKey: .offers) ?? []
        asin = try container.decodeIfPresent(String.self, forKey: .asin)
        elid = try container.decodeIfPresent(String.self, forKey: .elid)
    }
}

/// Offer from UPCitemdb response
private struct UPCitemdbOffer: Codable, Sendable {
    nonisolated let merchant: String?
    nonisolated let domain: String?
    nonisolated let title: String?
    nonisolated let currency: String?
    nonisolated let listPrice: String?
    nonisolated let price: Double?
    nonisolated let shipping: String?
    nonisolated let condition: String?
    nonisolated let availability: String?
    nonisolated let link: String?
    nonisolated let updatedT: Int?

    enum CodingKeys: String, CodingKey {
        case merchant, domain, title, currency
        case listPrice = "list_price"
        case price, shipping, condition, availability, link
        case updatedT = "updated_t"
    }
}

// MARK: - Protocol for Testing

/// Protocol for dependency injection in tests
protocol ProductLookupProviding: Actor {
    func lookup(barcode: String) async -> ProductLookupResult
    func clearCache() async
}

extension ProductLookupService: ProductLookupProviding {}
