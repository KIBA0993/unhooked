//
//  IAPService.swift
//  Unhooked
//
//  In-App Purchase handling with StoreKit 2
//

import Foundation
import Combine
import StoreKit
import SwiftData

@MainActor
class IAPService: ObservableObject {
    private let modelContext: ModelContext
    private let economyService: EconomyService
    
    @Published var gemProducts: [Product] = []
    @Published var purchaseInProgress = false
    
    // Gem SKUs
    private let gemSKUs = [
        "gems_100",   // 100 Gems
        "gems_500",   // 500 Gems
        "gems_1200",  // 1200 Gems (best value)
        "gems_2500"   // 2500 Gems
    ]
    
    init(modelContext: ModelContext, economyService: EconomyService) {
        self.modelContext = modelContext
        self.economyService = economyService
    }
    
    // MARK: - Product Loading
    
    func loadProducts() async {
        do {
            let products = try await Product.products(for: gemSKUs)
            self.gemProducts = products.sorted { $0.price < $1.price }
            print("✅ Loaded \(products.count) gem products")
        } catch {
            print("❌ Failed to load products: \(error)")
        }
    }
    
    // MARK: - Purchase Flow
    
    func purchase(
        userId: UUID,
        product: Product,
        idempotencyKey: String
    ) async throws -> PurchaseResult {
        guard !purchaseInProgress else {
            return .failure(.purchaseInProgress)
        }
        
        purchaseInProgress = true
        defer { purchaseInProgress = false }
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                // Verify transaction
                let transaction = try checkVerified(verification)
                
                // Process purchase
                let gemsAwarded = try await processPurchase(
                    userId: userId,
                    transaction: transaction,
                    idempotencyKey: idempotencyKey
                )
                
                // Finish transaction
                await transaction.finish()
                
                print("💎 Purchase successful! Awarded \(gemsAwarded) Gems")
                
                return .success(gemsAwarded: gemsAwarded)
                
            case .userCancelled:
                return .failure(.userCancelled)
                
            case .pending:
                return .failure(.pending)
                
            @unknown default:
                return .failure(.unknown)
            }
        } catch {
            print("❌ Purchase error: \(error)")
            return .failure(.failed(error))
        }
    }
    
    // MARK: - Receipt Validation
    
    private func checkVerified(_ result: VerificationResult<Transaction>) throws -> Transaction {
        switch result {
        case .unverified(_, let error):
            throw IAPError.verificationFailed(error)
        case .verified(let transaction):
            return transaction
        }
    }
    
    private func processPurchase(
        userId: UUID,
        transaction: Transaction,
        idempotencyKey: String
    ) async throws -> Int {
        // Map product ID to gem amount
        let gemsAwarded = gemAmountForProduct(transaction.productID)
        
        // Award gems via economy service (with idempotency)
        try economyService.awardGems(
            userId: userId,
            amount: gemsAwarded,
            reason: .iapPurchase,
            idempotencyKey: idempotencyKey
        )
        
        // Record purchase
        let priceUSD = transaction.price.map { NSDecimalNumber(decimal: $0).doubleValue } ?? 0.0
        let purchase = IAPurchase(
            userId: userId,
            transactionId: String(transaction.id),
            productId: transaction.productID,
            gemsAwarded: gemsAwarded,
            priceUSD: priceUSD,
            idempotencyKey: idempotencyKey
        )
        modelContext.insert(purchase)
        try modelContext.save()
        
        // Analytics
        logIAPEvent(purchase: purchase)
        
        return gemsAwarded
    }
    
    private func gemAmountForProduct(_ productId: String) -> Int {
        switch productId {
        case "gems_100": return 100
        case "gems_500": return 500
        case "gems_1200": return 1200
        case "gems_2500": return 2500
        default: return 0
        }
    }
    
    // MARK: - Refund Handling
    
    func processRefund(transactionId: String) async throws {
        let descriptor = FetchDescriptor<IAPurchase>(
            predicate: #Predicate { $0.transactionId == transactionId }
        )
        
        guard let purchase = try modelContext.fetch(descriptor).first else {
            print("⚠️ Refund for unknown transaction: \(transactionId)")
            return
        }
        
        // Rollback gems
        _ = try economyService.spendGems(
            userId: purchase.userId,
            amount: purchase.gemsAwarded,
            reason: .refund,
            relatedItemId: transactionId
        )
        
        purchase.refunded = true
        purchase.refundedAt = Date()
        try modelContext.save()
        
        print("♻️ Refund processed: -\(purchase.gemsAwarded) Gems")
        
        // Analytics
        logRefundEvent(purchase: purchase)
    }
    
    // MARK: - Transaction Observer
    
    func startTransactionObserver(userId: UUID) {
        Task {
            for await result in Transaction.updates {
                do {
                    let transaction = try checkVerified(result)
                    
                    // Handle refunds
                    if transaction.revocationDate != nil {
                        try await processRefund(transactionId: String(transaction.id))
                    }
                    
                    await transaction.finish()
                } catch {
                    print("❌ Transaction update error: \(error)")
                }
            }
        }
    }
    
    // MARK: - Analytics
    
    private func logIAPEvent(purchase: IAPurchase) {
        // TODO: Implement analytics
        print("📊 iap_validated: \(purchase.productId), \(purchase.priceUSD) USD")
    }
    
    private func logRefundEvent(purchase: IAPurchase) {
        // TODO: Implement analytics
        print("📊 refund_processed: \(purchase.priceUSD) USD")
    }
}

// MARK: - Supporting Types

@Model
final class IAPurchase {
    @Attribute(.unique) var id: UUID = UUID()
    var userId: UUID = UUID()
    var transactionId: String = ""
    var productId: String = ""
    var gemsAwarded: Int = 0
    var priceUSD: Double = 0.0
    var refunded: Bool = false
    var refundedAt: Date?
    var idempotencyKey: String = ""
    var createdAt: Date = Date()
    
    init(
        userId: UUID,
        transactionId: String,
        productId: String,
        gemsAwarded: Int,
        priceUSD: Double,
        idempotencyKey: String
    ) {
        self.id = UUID()
        self.userId = userId
        self.transactionId = transactionId
        self.productId = productId
        self.gemsAwarded = gemsAwarded
        self.priceUSD = priceUSD
        self.idempotencyKey = idempotencyKey
        self.createdAt = Date()
    }
}

enum PurchaseResult {
    case success(gemsAwarded: Int)
    case failure(PurchaseError)
}

enum PurchaseError: Error {
    case purchaseInProgress
    case userCancelled
    case pending
    case failed(Error)
    case unknown
}

enum IAPError: Error {
    case verificationFailed(VerificationResult<Transaction>.VerificationError)
}

