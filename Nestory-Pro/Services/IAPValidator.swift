//
//  IAPValidator.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/28/25.
//

import Foundation
import StoreKit

/// Actor-based In-App Purchase validator using StoreKit 2
/// Handles purchase verification, transaction listening, and Pro status updates
/// Uses dependency injection via AppEnvironment (Task 5.2.3 complete)
@MainActor
@Observable
final class IAPValidator {

    // MARK: - Product Configuration

    private let productID = "com.drunkonjava.nestory.pro"

    // MARK: - Observable State

    private(set) var isProUnlocked: Bool = false
    private(set) var isPurchasing: Bool = false
    private(set) var purchaseError: Error?

    // MARK: - Transaction Listener

    /// Task handle for transaction updates listener
    /// Using nonisolated(unsafe) allows access from deinit.
    /// This is safe because Task.cancel() is thread-safe.
    private nonisolated(unsafe) var transactionListener: Task<Void, Error>?

    // MARK: - Initialization

    // Public initializer for dependency injection
    init() {
        // Initialize Pro status from Keychain
        self.isProUnlocked = KeychainManager.isProUnlocked()
    }

    // MARK: - Deinitialization

    /// Clean up transaction listener to prevent memory corruption
    /// The Task.detached with async iterator over Transaction.updates must be
    /// cancelled before deallocation to avoid TaskLocal cleanup issues
    deinit {
        transactionListener?.cancel()
        transactionListener = nil
    }

    // MARK: - Transaction Listener

    /// Starts listening for transaction updates
    /// Call this on app launch to handle restored purchases and subscription renewals
    func startTransactionListener() {
        transactionListener = Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self = self else { return }

                do {
                    let transaction = try await self.checkVerified(result)

                    // Update Pro status based on transaction
                    await self.handleVerifiedTransaction(transaction)

                    // Always finish the transaction
                    await transaction.finish()
                } catch {
                    // TODO: Add proper logging instead of print statements
                    // FIXME: Consider reporting verification failures to analytics
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }

    /// Stops the transaction listener
    /// Call this when the app is terminating (cleanup)
    func stopTransactionListener() {
        transactionListener?.cancel()
        transactionListener = nil
    }

    // MARK: - Purchase Flow

    /// Fetches the Pro product from App Store Connect
    func fetchProduct() async throws -> Product? {
        let products = try await Product.products(for: [productID])
        return products.first
    }

    /// Initiates a purchase of the Pro product
    func purchase() async throws {
        isPurchasing = true
        purchaseError = nil

        defer {
            isPurchasing = false
        }

        guard let product = try await fetchProduct() else {
            throw IAPError.productNotFound
        }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)

            // Update Pro status
            await handleVerifiedTransaction(transaction)

            // Finish the transaction
            await transaction.finish()

        case .userCancelled:
            // User cancelled - no error
            break

        case .pending:
            // Purchase is pending (parental approval, etc.)
            throw IAPError.purchasePending

        @unknown default:
            throw IAPError.unknownPurchaseResult
        }
    }

    /// Restores previous purchases
    /// Important: Call this when user taps "Restore Purchases"
    func restorePurchases() async throws {
        isPurchasing = true
        purchaseError = nil

        defer {
            isPurchasing = false
        }

        // Sync with App Store
        try await AppStore.sync()

        // Check for current entitlements
        await updateProStatus()
    }

    // MARK: - Verification

    /// Verifies a transaction using StoreKit's built-in verification
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            // Transaction failed verification
            throw IAPError.verificationFailed(error)

        case .verified(let safe):
            // Transaction is verified and safe to use
            return safe
        }
    }

    /// Handles a verified transaction by updating Pro status
    private func handleVerifiedTransaction(_ transaction: Transaction) async {
        // Only process Pro product transactions
        guard transaction.productID == productID else { return }

        // Update Pro status based on transaction state
        let shouldUnlock = transaction.revocationDate == nil

        await MainActor.run {
            self.isProUnlocked = shouldUnlock

            // Persist to Keychain
            try? KeychainManager.setProUnlocked(shouldUnlock)
        }
    }

    // MARK: - Status Validation

    /// Validates current Pro status by checking all transactions
    /// Call this on app launch and after restore
    func updateProStatus() async {
        var hasValidPurchase = false

        // Check all current entitlements
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                if transaction.productID == productID && transaction.revocationDate == nil {
                    hasValidPurchase = true
                    break
                }
            } catch {
                // Skip invalid transactions
                continue
            }
        }

        await MainActor.run {
            self.isProUnlocked = hasValidPurchase

            // Persist to Keychain
            try? KeychainManager.setProUnlocked(hasValidPurchase)
        }
    }

    // MARK: - Testing Support

    #if DEBUG
    /// Simulates Pro unlock for testing (only available in Debug builds)
    func simulateProUnlock() {
        isProUnlocked = true
        try? KeychainManager.setProUnlocked(true)
    }

    /// Resets Pro status for testing (only available in Debug builds)
    func resetProStatus() {
        isProUnlocked = false
        try? KeychainManager.removeProStatus()
    }
    #endif
}

// MARK: - Error Types

enum IAPError: LocalizedError {
    case productNotFound
    case purchasePending
    case verificationFailed(Error)
    case unknownPurchaseResult

    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Pro product not found. Please try again later."
        case .purchasePending:
            return "Purchase is pending approval."
        case .verificationFailed(let error):
            return "Purchase verification failed: \(error.localizedDescription)"
        case .unknownPurchaseResult:
            return "Unknown purchase result. Please contact support."
        }
    }
}
