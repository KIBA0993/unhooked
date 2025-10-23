//
//  FoodServiceTests.swift
//  UnhookedTests
//
//  Tests for Food Shop with species filtering
//

import XCTest
import SwiftData
@testable import Unhooked

@MainActor
final class FoodServiceTests: XCTestCase {
    var modelContext: ModelContext!
    var foodService: FoodService!
    var economyService: EconomyService!
    var testUserId: UUID!
    var catPet: Pet!
    var dogPet: Pet!
    
    override func setUp() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: FoodCatalogItem.self, Pet.self, Wallet.self, LedgerEntry.self, DailyStats.self,
            configurations: config
        )
        modelContext = ModelContext(container)
        economyService = EconomyService(modelContext: modelContext)
        foodService = FoodService(modelContext: modelContext, economyService: economyService)
        
        testUserId = UUID()
        
        // Create test pets
        catPet = Pet(userId: testUserId, species: .cat)
        dogPet = Pet(userId: testUserId, species: .dog)
        modelContext.insert(catPet)
        modelContext.insert(dogPet)
        
        // Seed catalog
        try foodService.seedCatalog()
        
        // Give user energy
        try economyService.awardEnergy(userId: testUserId, amount: 500, reason: .dailyAward)
        
        try modelContext.save()
    }
    
    // MARK: - Species Filtering
    
    func testCatOnlySeesAppropriateFood() throws {
        let items = try foodService.getAvailableFoodItems(for: .cat)
        
        // Should include cat-specific and "both" items
        let hasCatItem = items.contains { $0.itemId.contains("cat") }
        let hasBothItem = items.contains { $0.speciesScope == .both }
        let hasDogItem = items.contains { $0.itemId.contains("dog") }
        
        XCTAssertTrue(hasCatItem)
        XCTAssertTrue(hasBothItem)
        XCTAssertFalse(hasDogItem)
    }
    
    func testDogOnlySeesAppropriateFood() throws {
        let items = try foodService.getAvailableFoodItems(for: .dog)
        
        // Should include dog-specific and "both" items
        let hasDogItem = items.contains { $0.itemId.contains("dog") }
        let hasBothItem = items.contains { $0.speciesScope == .both }
        let hasCatItem = items.contains { $0.itemId.contains("cat") }
        
        XCTAssertTrue(hasDogItem)
        XCTAssertTrue(hasBothItem)
        XCTAssertFalse(hasCatItem)
    }
    
    // MARK: - Food Purchase
    
    func testSuccessfulFoodPurchase() throws {
        let result = try foodService.purchaseFood(
            userId: testUserId,
            pet: catPet,
            itemId: "cat_tuna_25",
            idempotencyKey: UUID().uuidString
        )
        
        switch result {
        case .success(let details):
            XCTAssertGreaterThan(details.fullnessDelta, 0)
            XCTAssertGreaterThan(details.moodDelta, 0)
            
            // Check wallet balance decreased
            let wallet = try economyService.getWallet(userId: testUserId)
            XCTAssertEqual(wallet.energyBalance, 475)  // 500 - 25
            
        case .failure(let error):
            XCTFail("Purchase should succeed: \(error)")
        }
    }
    
    func testCannotFeedDeadPet() throws {
        catPet.healthState = .dead
        
        let result = try foodService.purchaseFood(
            userId: testUserId,
            pet: catPet,
            itemId: "cat_tuna_25",
            idempotencyKey: UUID().uuidString
        )
        
        switch result {
        case .success:
            XCTFail("Should not be able to feed dead pet")
        case .failure(let error):
            XCTAssertEqual(error, .petCannotFeed)
        }
    }
    
    func testFedTodayThreshold() throws {
        XCTAssertFalse(catPet.fedToday)
        
        // Purchase 100 Energy worth of food
        _ = try foodService.purchaseFood(
            userId: testUserId,
            pet: catPet,
            itemId: "cat_salmon_100",
            idempotencyKey: UUID().uuidString
        )
        
        XCTAssertTrue(catPet.fedToday)
    }
    
    func testBuffAccumulation() throws {
        let initialBuff = catPet.dailyBuffAccumulated
        
        // Purchase food with buff
        _ = try foodService.purchaseFood(
            userId: testUserId,
            pet: catPet,
            itemId: "cat_chicken_50",  // Has 0.05 buff
            idempotencyKey: UUID().uuidString
        )
        
        XCTAssertGreaterThan(catPet.dailyBuffAccumulated, initialBuff)
    }
    
    func testBuffCapEnforcement() throws {
        catPet.healthState = .sick  // Sick cap = 0.10
        
        // Try to add 0.15 buff
        _ = try foodService.purchaseFood(
            userId: testUserId,
            pet: catPet,
            itemId: "cat_catnip_150",  // Has 0.15 buff
            idempotencyKey: UUID().uuidString
        )
        
        // Should be capped at 0.10
        XCTAssertEqual(catPet.dailyBuffAccumulated, 0.10)
    }
}


