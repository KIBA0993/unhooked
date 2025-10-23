//
//  CosmeticsService.swift
//  Unhooked
//
//  Cosmetics with dual currency pricing
//

import Foundation
import SwiftData

@MainActor
class CosmeticsService {
    private let modelContext: ModelContext
    private let economyService: EconomyService
    
    init(modelContext: ModelContext, economyService: EconomyService) {
        self.modelContext = modelContext
        self.economyService = economyService
    }
    
    // MARK: - Catalog
    
    func getAvailableCosmetics(category: CosmeticCategory? = nil) throws -> [CosmeticItem] {
        var predicate: Predicate<CosmeticItem>
        
        if let category = category {
            predicate = #Predicate { $0.isEnabled && $0.category == category }
        } else {
            predicate = #Predicate { $0.isEnabled }
        }
        
        let descriptor = FetchDescriptor<CosmeticItem>(predicate: predicate)
        let items = try modelContext.fetch(descriptor)
        
        return items.filter { $0.isAvailable }
    }
    
    func getOwnedCosmetics(userId: UUID) throws -> [OwnedCosmetic] {
        let descriptor = FetchDescriptor<OwnedCosmetic>(
            predicate: #Predicate { $0.userId == userId },
            sortBy: [SortDescriptor(\.purchaseDate, order: .reverse)]
        )
        
        return try modelContext.fetch(descriptor)
    }
    
    func isOwned(userId: UUID, itemId: String) throws -> Bool {
        let descriptor = FetchDescriptor<OwnedCosmetic>(
            predicate: #Predicate { $0.userId == userId && $0.itemId == itemId }
        )
        
        return try modelContext.fetchCount(descriptor) > 0
    }
    
    // MARK: - Purchase
    
    func purchaseWithEnergy(
        userId: UUID,
        itemId: String,
        idempotencyKey: String
    ) throws -> CosmeticPurchaseResult {
        // Get item
        let descriptor = FetchDescriptor<CosmeticItem>(
            predicate: #Predicate { $0.itemId == itemId }
        )
        
        guard let item = try modelContext.fetch(descriptor).first else {
            return .failure(.itemNotFound)
        }
        
        guard item.isAvailable else {
            return .failure(.notAvailable)
        }
        
        guard let priceEnergy = item.priceEnergy else {
            return .failure(.currencyNotAccepted)
        }
        
        // Check if already owned
        if try isOwned(userId: userId, itemId: itemId) {
            return .failure(.alreadyOwned)
        }
        
        // Spend energy
        let success = try economyService.spendEnergy(
            userId: userId,
            amount: priceEnergy,
            reason: .cosmetic,
            relatedItemId: itemId,
            idempotencyKey: idempotencyKey
        )
        
        guard success else {
            return .failure(.insufficientCurrency)
        }
        
        // Grant ownership
        let owned = OwnedCosmetic(
            userId: userId,
            itemId: itemId,
            purchasedWithCurrency: .energy
        )
        modelContext.insert(owned)
        try modelContext.save()
        
        print("✨ Cosmetic purchased: \(item.title) for \(priceEnergy) Energy")
        
        return .success(item: item)
    }
    
    func purchaseWithGems(
        userId: UUID,
        itemId: String,
        idempotencyKey: String
    ) throws -> CosmeticPurchaseResult {
        // Get item
        let descriptor = FetchDescriptor<CosmeticItem>(
            predicate: #Predicate { $0.itemId == itemId }
        )
        
        guard let item = try modelContext.fetch(descriptor).first else {
            return .failure(.itemNotFound)
        }
        
        guard item.isAvailable else {
            return .failure(.notAvailable)
        }
        
        guard let priceGems = item.priceGems else {
            return .failure(.currencyNotAccepted)
        }
        
        // Check if already owned
        if try isOwned(userId: userId, itemId: itemId) {
            return .failure(.alreadyOwned)
        }
        
        // Spend gems
        let success = try economyService.spendGems(
            userId: userId,
            amount: priceGems,
            reason: .cosmetic,
            relatedItemId: itemId,
            idempotencyKey: idempotencyKey
        )
        
        guard success else {
            return .failure(.insufficientCurrency)
        }
        
        // Grant ownership
        let owned = OwnedCosmetic(
            userId: userId,
            itemId: itemId,
            purchasedWithCurrency: .gems
        )
        modelContext.insert(owned)
        try modelContext.save()
        
        print("✨ Cosmetic purchased: \(item.title) for \(priceGems) Gems")
        
        return .success(item: item)
    }
}

// MARK: - Result Types

enum CosmeticPurchaseResult {
    case success(item: CosmeticItem)
    case failure(CosmeticPurchaseError)
}

enum CosmeticPurchaseError: Error {
    case itemNotFound
    case notAvailable
    case currencyNotAccepted
    case alreadyOwned
    case insufficientCurrency
}


