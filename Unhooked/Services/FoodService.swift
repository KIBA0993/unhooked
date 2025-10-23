//
//  FoodService.swift
//  Unhooked
//
//  Food purchasing with species-aware catalog
//

import Foundation
import SwiftData

@MainActor
class FoodService {
    private let modelContext: ModelContext
    private let economyService: EconomyService
    
    init(modelContext: ModelContext, economyService: EconomyService) {
        self.modelContext = modelContext
        self.economyService = economyService
    }
    
    // MARK: - Catalog
    
    func getAvailableFoodItems(for species: Species) throws -> [FoodCatalogItem] {
        let descriptor = FetchDescriptor<FoodCatalogItem>(
            predicate: #Predicate { item in
                item.isEnabled
            }
        )
        
        let allItems = try modelContext.fetch(descriptor)
        
        return allItems.filter { item in
            item.isAvailable(for: species)
        }
    }
    
    // MARK: - Purchase
    
    func purchaseFood(
        userId: UUID,
        pet: Pet,
        itemId: String,
        idempotencyKey: String
    ) throws -> FoodPurchaseResult {
        // Check if pet can be fed
        guard pet.canFeed else {
            return .failure(.petCannotFeed)
        }
        
        // Get item
        let descriptor = FetchDescriptor<FoodCatalogItem>(
            predicate: #Predicate { $0.itemId == itemId }
        )
        
        guard let item = try modelContext.fetch(descriptor).first else {
            return .failure(.itemNotFound)
        }
        
        // Verify availability for species
        guard item.isAvailable(for: pet.species) else {
            return .failure(.notAvailableForSpecies)
        }
        
        // Spend energy
        let success = try economyService.spendEnergy(
            userId: userId,
            amount: item.priceEnergy,
            reason: .food,
            relatedItemId: itemId,
            idempotencyKey: idempotencyKey
        )
        
        guard success else {
            return .failure(.insufficientEnergy)
        }
        
        // Get effective stats for species
        let stats = item.effectiveStats(for: pet.species)
        
        // Apply effects
        pet.fullness = min(100.0, pet.fullness + Double(stats.fullness))
        pet.mood = min(10, pet.mood + stats.mood)
        
        // Track feeding
        pet.lastFeedAmount += item.priceEnergy
        
        // Check fed_today threshold (100 Energy)
        if pet.lastFeedAmount >= 100 && !pet.fedToday {
            pet.fedToday = true
            print("✅ Fed threshold reached for today!")
        }
        
        // Accumulate buff (capped by health state)
        let newBuff = min(pet.dailyBuffCap, pet.dailyBuffAccumulated + stats.buff)
        pet.dailyBuffAccumulated = newBuff
        
        pet.updatedAt = Date()
        try modelContext.save()
        
        print("🍖 Fed \(item.title): +\(stats.fullness)% fullness, +\(stats.mood) mood, +\(stats.buff) buff")
        
        // Analytics
        logFoodPurchase(userId: userId, pet: pet, item: item, stats: stats)
        
        return .success(
            fullnessDelta: stats.fullness,
            moodDelta: stats.mood,
            buffAdded: stats.buff,
            animationId: stats.animationId
        )
    }
    
    // MARK: - Seed Catalog
    
    func seedCatalog() throws {
        // Check if already seeded
        let descriptor = FetchDescriptor<FoodCatalogItem>()
        let existing = try modelContext.fetch(descriptor)
        
        guard existing.isEmpty else {
            print("📦 Food catalog already seeded")
            return
        }
        
        let items: [FoodCatalogItem] = [
            // Cat items
            FoodCatalogItem(
                itemId: "cat_tuna_25",
                title: "Tuna Treats",
                priceEnergy: 25,
                speciesScope: .cat,
                defaultFullnessDelta: 12,
                defaultMoodDelta: 1,
                defaultBuffFrac: 0.0
            ),
            FoodCatalogItem(
                itemId: "cat_chicken_50",
                title: "Chicken Bites",
                priceEnergy: 50,
                speciesScope: .cat,
                defaultFullnessDelta: 22,
                defaultMoodDelta: 1,
                defaultBuffFrac: 0.05
            ),
            FoodCatalogItem(
                itemId: "cat_salmon_100",
                title: "Salmon Bowl",
                priceEnergy: 100,
                speciesScope: .cat,
                defaultFullnessDelta: 40,
                defaultMoodDelta: 2,
                defaultBuffFrac: 0.10
            ),
            FoodCatalogItem(
                itemId: "cat_catnip_150",
                title: "Catnip Feast",
                priceEnergy: 150,
                speciesScope: .cat,
                defaultFullnessDelta: 55,
                defaultMoodDelta: 3,
                defaultBuffFrac: 0.15
            ),
            
            // Dog items
            FoodCatalogItem(
                itemId: "dog_biscuit_25",
                title: "Crunch Biscuit",
                priceEnergy: 25,
                speciesScope: .dog,
                defaultFullnessDelta: 15,
                defaultMoodDelta: 1,
                defaultBuffFrac: 0.0
            ),
            FoodCatalogItem(
                itemId: "dog_jerky_50",
                title: "Turkey Jerky",
                priceEnergy: 50,
                speciesScope: .dog,
                defaultFullnessDelta: 25,
                defaultMoodDelta: 1,
                defaultBuffFrac: 0.05
            ),
            FoodCatalogItem(
                itemId: "dog_stew_100",
                title: "Beef Stew",
                priceEnergy: 100,
                speciesScope: .dog,
                defaultFullnessDelta: 45,
                defaultMoodDelta: 2,
                defaultBuffFrac: 0.10
            ),
            FoodCatalogItem(
                itemId: "dog_bones_150",
                title: "Birthday Bones",
                priceEnergy: 150,
                speciesScope: .dog,
                defaultFullnessDelta: 60,
                defaultMoodDelta: 3,
                defaultBuffFrac: 0.15
            ),
            
            // Both
            FoodCatalogItem(
                itemId: "both_veggie_75",
                title: "Veggie Medley",
                priceEnergy: 75,
                speciesScope: .both,
                defaultFullnessDelta: 30,
                defaultMoodDelta: 1,
                defaultBuffFrac: 0.05
            )
        ]
        
        for item in items {
            modelContext.insert(item)
        }
        
        try modelContext.save()
        print("✅ Food catalog seeded with \(items.count) items")
    }
    
    // MARK: - Analytics
    
    private func logFoodPurchase(
        userId: UUID,
        pet: Pet,
        item: FoodCatalogItem,
        stats: (fullness: Int, mood: Int, buff: Double, animationId: String?)
    ) {
        // TODO: Implement analytics
        print("📊 species_food_purchase: \(item.itemId), species: \(pet.species.rawValue)")
    }
}

// MARK: - Result Types

enum FoodPurchaseResult {
    case success(fullnessDelta: Int, moodDelta: Int, buffAdded: Double, animationId: String?)
    case failure(FoodPurchaseError)
}

enum FoodPurchaseError: Error {
    case itemNotFound
    case notAvailableForSpecies
    case insufficientEnergy
    case petCannotFeed
}


