//
//  EconomyServiceTests.swift
//  UnhookedTests
//
//  Tests for Economy System
//

import XCTest
import SwiftData
@testable import Unhooked

@MainActor
final class EconomyServiceTests: XCTestCase {
    var modelContext: ModelContext!
    var economyService: EconomyService!
    var testUserId: UUID!
    
    override func setUp() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Wallet.self, LedgerEntry.self, DailyStats.self, Pet.self,
            configurations: config
        )
        modelContext = ModelContext(container)
        economyService = EconomyService(modelContext: modelContext)
        testUserId = UUID()
    }
    
    override func tearDown() {
        modelContext = nil
        economyService = nil
        testUserId = nil
    }
    
    // MARK: - Energy Award Calculation
    
    func testFullEnergyWhenUnderLimit() throws {
        // Given: Usage well under limit (60/180 = 0.33 ratio)
        let energy = try economyService.calculateDailyEnergy(
            userId: testUserId,
            usageMinutes: 60,
            limitMinutes: 180,
            date: "2025-10-17"
        )
        
        // Then: Should award significant energy (roughly 150 * (1-0.33) = ~100)
        XCTAssertGreaterThan(energy, 80)
        XCTAssertLessThanOrEqual(energy, 150)
    }
    
    func testZeroEnergyWhenOverLimit() throws {
        // Given: Usage over limit (200/180 > 1.0)
        let energy = try economyService.calculateDailyEnergy(
            userId: testUserId,
            usageMinutes: 200,
            limitMinutes: 180,
            date: "2025-10-17"
        )
        
        // Then: Should award 0 energy
        XCTAssertEqual(energy, 0)
    }
    
    func testPartialEnergyWhenNearLimit() throws {
        // Given: Usage near limit (150/180 = 0.83 ratio)
        let energy = try economyService.calculateDailyEnergy(
            userId: testUserId,
            usageMinutes: 150,
            limitMinutes: 180,
            date: "2025-10-17"
        )
        
        // Then: Should award some energy but not max
        XCTAssertGreaterThan(energy, 0)
        XCTAssertLessThan(energy, 50)
    }
    
    // MARK: - Wallet Operations
    
    func testWalletCreation() throws {
        let wallet = try economyService.getWallet(userId: testUserId)
        
        XCTAssertEqual(wallet.energyBalance, 0)
        XCTAssertEqual(wallet.gemsBalance, 0)
    }
    
    func testAwardEnergy() throws {
        try economyService.awardEnergy(userId: testUserId, amount: 100, reason: .dailyAward)
        
        let wallet = try economyService.getWallet(userId: testUserId)
        XCTAssertEqual(wallet.energyBalance, 100)
    }
    
    func testSpendEnergy() throws {
        try economyService.awardEnergy(userId: testUserId, amount: 100, reason: .dailyAward)
        
        let success = try economyService.spendEnergy(
            userId: testUserId,
            amount: 50,
            reason: .food
        )
        
        XCTAssertTrue(success)
        
        let wallet = try economyService.getWallet(userId: testUserId)
        XCTAssertEqual(wallet.energyBalance, 50)
    }
    
    func testCannotSpendMoreThanBalance() throws {
        try economyService.awardEnergy(userId: testUserId, amount: 50, reason: .dailyAward)
        
        let success = try economyService.spendEnergy(
            userId: testUserId,
            amount: 100,
            reason: .food
        )
        
        XCTAssertFalse(success)
        
        let wallet = try economyService.getWallet(userId: testUserId)
        XCTAssertEqual(wallet.energyBalance, 50)  // Balance unchanged
    }
    
    // MARK: - Ledger
    
    func testLedgerEntryCreated() throws {
        try economyService.awardEnergy(userId: testUserId, amount: 100, reason: .dailyAward)
        
        let descriptor = FetchDescriptor<LedgerEntry>(
            predicate: #Predicate { $0.userId == testUserId }
        )
        
        let entries = try modelContext.fetch(descriptor)
        XCTAssertEqual(entries.count, 1)
        
        let entry = entries.first!
        XCTAssertEqual(entry.currency, .energy)
        XCTAssertEqual(entry.delta, 100)
        XCTAssertEqual(entry.reason, .dailyAward)
    }
}


