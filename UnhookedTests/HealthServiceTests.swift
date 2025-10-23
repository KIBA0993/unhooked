//
//  HealthServiceTests.swift
//  UnhookedTests
//
//  Tests for Health State Machine
//

import XCTest
import SwiftData
@testable import Unhooked

@MainActor
final class HealthServiceTests: XCTestCase {
    var modelContext: ModelContext!
    var healthService: HealthService!
    var testPet: Pet!
    
    override func setUp() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Pet.self, DailyStats.self,
            configurations: config
        )
        modelContext = ModelContext(container)
        healthService = HealthService(modelContext: modelContext)
        
        // Create test pet
        testPet = Pet(userId: UUID(), species: .cat)
        modelContext.insert(testPet)
        try modelContext.save()
    }
    
    override func tearDown() {
        modelContext = nil
        healthService = nil
        testPet = nil
    }
    
    // MARK: - Healthy → Sick Transition
    
    func testPetBecomesSickAfter3ConsecutiveUnfedDays() throws {
        // Given: Healthy pet
        XCTAssertEqual(testPet.healthState, .healthy)
        XCTAssertEqual(testPet.consecutiveUnfedDays, 0)
        
        // When: Not fed for 3 days
        for _ in 1...3 {
            testPet.fedToday = false
            try healthService.performDailyHealthCheck(for: testPet)
        }
        
        // Then: Pet should be sick
        XCTAssertEqual(testPet.healthState, .sick)
        XCTAssertEqual(testPet.consecutiveUnfedDays, 3)
    }
    
    func testConsecutiveUnfedDaysResetWhenFed() throws {
        // Given: Pet with 2 consecutive unfed days
        testPet.consecutiveUnfedDays = 2
        testPet.fedToday = true
        
        // When: Daily check performed
        try healthService.performDailyHealthCheck(for: testPet)
        
        // Then: Counter should reset
        XCTAssertEqual(testPet.consecutiveUnfedDays, 0)
        XCTAssertEqual(testPet.healthState, .healthy)
    }
    
    // MARK: - Sick → Dead Transition
    
    func testPetDiesAfter7ConsecutiveUnfedDays() throws {
        // Given: Healthy pet
        testPet.fedToday = false
        
        // When: Not fed for 7 days
        for _ in 1...7 {
            try healthService.performDailyHealthCheck(for: testPet)
        }
        
        // Then: Pet should be dead
        XCTAssertEqual(testPet.healthState, .dead)
        XCTAssertNotNil(testPet.deadAt)
    }
    
    // MARK: - Buff Caps
    
    func testHealthyPetBuffCap() {
        testPet.healthState = .healthy
        testPet.fragileUntil = nil
        
        XCTAssertEqual(testPet.dailyBuffCap, 0.25)
    }
    
    func testSickPetBuffCap() {
        testPet.healthState = .sick
        
        XCTAssertEqual(testPet.dailyBuffCap, 0.10)
    }
    
    func testFragilePetBuffCap() {
        testPet.healthState = .healthy
        testPet.fragileUntil = Date().addingTimeInterval(86400 * 3)  // 3 days from now
        
        XCTAssertEqual(testPet.dailyBuffCap, 0.15)
    }
    
    func testDeadPetBuffCap() {
        testPet.healthState = .dead
        
        XCTAssertEqual(testPet.dailyBuffCap, 0.0)
    }
    
    // MARK: - Action Availability
    
    func testDeadPetCannotFeed() {
        testPet.healthState = .dead
        
        XCTAssertFalse(testPet.canFeed)
    }
    
    func testSickPetCannotTrick() {
        testPet.healthState = .sick
        
        XCTAssertFalse(testPet.canTrick)
    }
    
    func testHealthyPetCanDoAllActions() {
        testPet.healthState = .healthy
        
        XCTAssertTrue(testPet.canFeed)
        XCTAssertTrue(testPet.canTrick)
        XCTAssertTrue(testPet.canPet)
        XCTAssertTrue(testPet.canGroom)
        XCTAssertTrue(testPet.canNap)
    }
}


