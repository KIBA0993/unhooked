//
//  ScreenTimeUsageTests.swift
//  UnhookedTests
//
//  Unit tests for ScreenTimeUsageManager
//

import XCTest
@testable import Unhooked

final class ScreenTimeUsageTests: XCTestCase {
    
    var manager: ScreenTimeUsageManager!
    var testDefaults: UserDefaults!
    
    override func setUp() {
        super.setUp()
        testDefaults = UserDefaults(suiteName: "test.screentime.usage")!
        testDefaults.removePersistentDomain(forName: "test.screentime.usage")
        
        manager = ScreenTimeUsageManager()
        manager.userDefaultsOverride = testDefaults
    }
    
    override func tearDown() {
        testDefaults.removePersistentDomain(forName: "test.screentime.usage")
        manager = nil
        testDefaults = nil
        super.tearDown()
    }
    
    // MARK: - Basic Save/Load Tests
    
    func testSaveAndLoadUsage() {
        XCTAssertNil(manager.loadUsage())
        
        let data = ScreenTimeUsageData(date: Date(), totalMinutes: 25)
        manager.saveUsage(data)
        
        let loaded = manager.loadUsage()
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.totalMinutes, 25)
        XCTAssertTrue(loaded?.isToday ?? false)
    }
    
    func testLoadReturnsNilForStaleData() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let staleData = ScreenTimeUsageData(date: yesterday, totalMinutes: 100)
        
        let encoded = try! JSONEncoder().encode(staleData)
        testDefaults.set(encoded, forKey: "screentime.usage.v3")
        
        let loaded = manager.loadUsage()
        XCTAssertNil(loaded, "Stale data should return nil")
    }
    
    func testClearUsageData() {
        manager.forceSetUsage(minutes: 50)
        XCTAssertEqual(manager.getCurrentMinutes(), 50)
        
        manager.clearUsageData()
        
        XCTAssertNil(manager.loadUsage())
        XCTAssertEqual(manager.getCurrentMinutes(), 0)
    }
    
    // MARK: - Update Validation: Never Go Backwards
    
    func testUpdateRejectsDecreasingValue() {
        manager.forceSetUsage(minutes: 30)
        
        let accepted = manager.updateUsage(newMinutes: 20)
        
        XCTAssertFalse(accepted, "Decreasing value should be rejected")
        XCTAssertEqual(manager.getCurrentMinutes(), 30)
    }
    
    func testUpdateAcceptsSameValue() {
        manager.forceSetUsage(minutes: 15)
        
        let accepted = manager.updateUsage(newMinutes: 15)
        
        XCTAssertTrue(accepted, "Same value should be accepted")
        XCTAssertEqual(manager.getCurrentMinutes(), 15)
    }
    
    // MARK: - Update Validation: Max Increase Limits
    
    func testFirstUpdateAcceptsUpTo60() {
        XCTAssertEqual(manager.getCurrentMinutes(), 0)
        
        let accepted = manager.updateUsage(newMinutes: 60)
        
        XCTAssertTrue(accepted, "First update up to 60 should be accepted")
        XCTAssertEqual(manager.getCurrentMinutes(), 60)
    }
    
    func testFirstUpdateRejectsOver60() {
        XCTAssertEqual(manager.getCurrentMinutes(), 0)
        
        let accepted = manager.updateUsage(newMinutes: 61)
        
        XCTAssertFalse(accepted, "First update over 60 should be rejected")
        XCTAssertEqual(manager.getCurrentMinutes(), 0)
    }
    
    // 0-120 mins: max increase is 30
    func testLowUsageAcceptsUpTo30Increase() {
        manager.forceSetUsage(minutes: 50)
        
        let accepted = manager.updateUsage(newMinutes: 80)  // +30
        
        XCTAssertTrue(accepted, "Increase of 30 at low usage should be accepted")
        XCTAssertEqual(manager.getCurrentMinutes(), 80)
    }
    
    func testLowUsageRejectsOver30Increase() {
        manager.forceSetUsage(minutes: 50)
        
        let accepted = manager.updateUsage(newMinutes: 81)  // +31
        
        XCTAssertFalse(accepted, "Increase of 31 at low usage should be rejected")
        XCTAssertEqual(manager.getCurrentMinutes(), 50)
    }
    
    // 120-300 mins: max increase is 60
    func testMidUsageAcceptsUpTo60Increase() {
        manager.forceSetUsage(minutes: 150)
        
        let accepted = manager.updateUsage(newMinutes: 210)  // +60
        
        XCTAssertTrue(accepted, "Increase of 60 at mid usage should be accepted")
        XCTAssertEqual(manager.getCurrentMinutes(), 210)
    }
    
    func testMidUsageRejectsOver60Increase() {
        manager.forceSetUsage(minutes: 150)
        
        let accepted = manager.updateUsage(newMinutes: 211)  // +61
        
        XCTAssertFalse(accepted, "Increase of 61 at mid usage should be rejected")
        XCTAssertEqual(manager.getCurrentMinutes(), 150)
    }
    
    // 300+ mins: max increase is 90
    func testHighUsageAcceptsUpTo90Increase() {
        manager.forceSetUsage(minutes: 350)
        
        let accepted = manager.updateUsage(newMinutes: 440)  // +90
        
        XCTAssertTrue(accepted, "Increase of 90 at high usage should be accepted")
        XCTAssertEqual(manager.getCurrentMinutes(), 440)
    }
    
    func testHighUsageRejectsOver90Increase() {
        manager.forceSetUsage(minutes: 350)
        
        let accepted = manager.updateUsage(newMinutes: 441)  // +91
        
        XCTAssertFalse(accepted, "Increase of 91 at high usage should be rejected")
        XCTAssertEqual(manager.getCurrentMinutes(), 350)
    }
    
    // MARK: - Realistic Threshold Sequences
    
    func testNormalThresholdSequence() {
        // Simulate normal usage: 5 -> 10 -> 15 -> 20 -> 25
        XCTAssertTrue(manager.updateUsage(newMinutes: 5))
        XCTAssertTrue(manager.updateUsage(newMinutes: 10))
        XCTAssertTrue(manager.updateUsage(newMinutes: 15))
        XCTAssertTrue(manager.updateUsage(newMinutes: 20))
        XCTAssertTrue(manager.updateUsage(newMinutes: 25))
        
        XCTAssertEqual(manager.getCurrentMinutes(), 25)
    }
    
    func testSkippedThresholdsWithinLimit() {
        // Start at 5, skip some, jump to 30 (increase of 25, within 30 limit for low usage)
        XCTAssertTrue(manager.updateUsage(newMinutes: 5))
        XCTAssertTrue(manager.updateUsage(newMinutes: 30))  // +25
        XCTAssertTrue(manager.updateUsage(newMinutes: 60))  // +30
        
        XCTAssertEqual(manager.getCurrentMinutes(), 60)
    }
    
    func testLargeSkipRejectedAtLowUsage() {
        manager.forceSetUsage(minutes: 20)
        
        // Try to jump from 20 to 60 (increase of 40, > 30 limit for low usage)
        let accepted = manager.updateUsage(newMinutes: 60)
        
        XCTAssertFalse(accepted, "Large skip of 40 at low usage should be rejected")
        XCTAssertEqual(manager.getCurrentMinutes(), 20)
    }
    
    // MARK: - Stale Event Rejection
    
    func testStaleEventOnFreshDay() {
        XCTAssertEqual(manager.getCurrentMinutes(), 0)
        
        let accepted = manager.updateUsage(newMinutes: 180)
        
        XCTAssertFalse(accepted, "180 min stale event should be rejected on fresh day")
        XCTAssertEqual(manager.getCurrentMinutes(), 0)
    }
    
    func testStaleEventAfterRealUsage() {
        manager.forceSetUsage(minutes: 50)
        
        // Stale event tries to jump to 180 (increase of 130, > 30 limit)
        let accepted = manager.updateUsage(newMinutes: 180)
        
        XCTAssertFalse(accepted, "Jump of 130 at low usage should be rejected")
        XCTAssertEqual(manager.getCurrentMinutes(), 50)
    }
    
    // MARK: - User's Reported Issues
    
    func testRealUserScenario_75to104() {
        // User's issue: Screen Time shows 104, app stuck at 75
        // Increase is 104 - 75 = 29, which is within 30 limit for low usage
        manager.forceSetUsage(minutes: 75)
        
        let accepted = manager.updateUsage(newMinutes: 104)
        
        XCTAssertTrue(accepted, "75 -> 104 (increase of 29) should be accepted")
        XCTAssertEqual(manager.getCurrentMinutes(), 104)
    }
    
    func testRealUserScenario_180to251() {
        // User used 251 mins but only saw 180
        // At 180 mins (mid-usage), max increase is 60
        // Need to simulate proper threshold progression
        manager.forceSetUsage(minutes: 180)
        
        // 180 -> 230 should work (increase of 50, within 60 limit for mid-usage)
        XCTAssertTrue(manager.updateUsage(newMinutes: 230))
        
        // 230 -> 251 should work (increase of 21, within 60 limit)
        XCTAssertTrue(manager.updateUsage(newMinutes: 251))
        
        XCTAssertEqual(manager.getCurrentMinutes(), 251)
    }
    
    // MARK: - Date String Tests
    
    func testDateStringFormat() {
        let data = ScreenTimeUsageData(date: Date(), totalMinutes: 0)
        
        let dateRegex = #"^\d{4}-\d{2}-\d{2}$"#
        XCTAssertTrue(data.dateString.range(of: dateRegex, options: .regularExpression) != nil)
    }
    
    func testIsTodayCheck() {
        let todayData = ScreenTimeUsageData(date: Date(), totalMinutes: 10)
        XCTAssertTrue(todayData.isToday)
        
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let yesterdayData = ScreenTimeUsageData(date: yesterday, totalMinutes: 10)
        XCTAssertFalse(yesterdayData.isToday)
    }
    
    // MARK: - Edge Cases
    
    func testZeroValueAccepted() {
        let accepted = manager.updateUsage(newMinutes: 0)
        XCTAssertTrue(accepted, "Zero should be valid first value")
    }
    
    func testMultipleUpdatesWithinDay() {
        // Simulate full day with proper threshold intervals
        XCTAssertTrue(manager.updateUsage(newMinutes: 10))    // First: +10
        XCTAssertTrue(manager.updateUsage(newMinutes: 30))    // Low: +20
        XCTAssertTrue(manager.updateUsage(newMinutes: 60))    // Low: +30
        XCTAssertTrue(manager.updateUsage(newMinutes: 90))    // Low: +30
        XCTAssertTrue(manager.updateUsage(newMinutes: 120))   // Low: +30
        // Now at 120, transitions to mid-usage limits
        XCTAssertTrue(manager.updateUsage(newMinutes: 170))   // Mid: +50
        XCTAssertTrue(manager.updateUsage(newMinutes: 220))   // Mid: +50
        XCTAssertTrue(manager.updateUsage(newMinutes: 280))   // Mid: +60
        // Now at 280, still mid-usage
        XCTAssertTrue(manager.updateUsage(newMinutes: 340))   // High: +60
        // At 340, now high-usage limits apply (>300)
        XCTAssertTrue(manager.updateUsage(newMinutes: 420))   // High: +80
        
        XCTAssertEqual(manager.getCurrentMinutes(), 420)
    }
    
    func testFullDayHeavyUsage() {
        // Simulate 8 hours of usage
        manager.forceSetUsage(minutes: 60)   // Start at 1 hour
        XCTAssertTrue(manager.updateUsage(newMinutes: 90))    // +30
        XCTAssertTrue(manager.updateUsage(newMinutes: 120))   // +30
        XCTAssertTrue(manager.updateUsage(newMinutes: 180))   // Mid: +60
        XCTAssertTrue(manager.updateUsage(newMinutes: 240))   // Mid: +60
        XCTAssertTrue(manager.updateUsage(newMinutes: 300))   // Mid: +60
        XCTAssertTrue(manager.updateUsage(newMinutes: 380))   // High: +80
        XCTAssertTrue(manager.updateUsage(newMinutes: 460))   // High: +80
        
        XCTAssertEqual(manager.getCurrentMinutes(), 460)
    }
}

//  UnhookedTests
//
//  Unit tests for ScreenTimeUsageManager
//

import XCTest
@testable import Unhooked

final class ScreenTimeUsageTests: XCTestCase {
    
    var manager: ScreenTimeUsageManager!
    var testDefaults: UserDefaults!
    
    override func setUp() {
        super.setUp()
        testDefaults = UserDefaults(suiteName: "test.screentime.usage")!
        testDefaults.removePersistentDomain(forName: "test.screentime.usage")
        
        manager = ScreenTimeUsageManager()
        manager.userDefaultsOverride = testDefaults
    }
    
    override func tearDown() {
        testDefaults.removePersistentDomain(forName: "test.screentime.usage")
        manager = nil
        testDefaults = nil
        super.tearDown()
    }
    
    // MARK: - Basic Save/Load Tests
    
    func testSaveAndLoadUsage() {
        XCTAssertNil(manager.loadUsage())
        
        let data = ScreenTimeUsageData(date: Date(), totalMinutes: 25)
        manager.saveUsage(data)
        
        let loaded = manager.loadUsage()
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.totalMinutes, 25)
        XCTAssertTrue(loaded?.isToday ?? false)
    }
    
    func testLoadReturnsNilForStaleData() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let staleData = ScreenTimeUsageData(date: yesterday, totalMinutes: 100)
        
        let encoded = try! JSONEncoder().encode(staleData)
        testDefaults.set(encoded, forKey: "screentime.usage.v3")
        
        let loaded = manager.loadUsage()
        XCTAssertNil(loaded, "Stale data should return nil")
    }
    
    func testClearUsageData() {
        manager.forceSetUsage(minutes: 50)
        XCTAssertEqual(manager.getCurrentMinutes(), 50)
        
        manager.clearUsageData()
        
        XCTAssertNil(manager.loadUsage())
        XCTAssertEqual(manager.getCurrentMinutes(), 0)
    }
    
    // MARK: - Update Validation: Never Go Backwards
    
    func testUpdateRejectsDecreasingValue() {
        manager.forceSetUsage(minutes: 30)
        
        let accepted = manager.updateUsage(newMinutes: 20)
        
        XCTAssertFalse(accepted, "Decreasing value should be rejected")
        XCTAssertEqual(manager.getCurrentMinutes(), 30)
    }
    
    func testUpdateAcceptsSameValue() {
        manager.forceSetUsage(minutes: 15)
        
        let accepted = manager.updateUsage(newMinutes: 15)
        
        XCTAssertTrue(accepted, "Same value should be accepted")
        XCTAssertEqual(manager.getCurrentMinutes(), 15)
    }
    
    // MARK: - Update Validation: Max Increase Limits
    
    func testFirstUpdateAcceptsUpTo60() {
        XCTAssertEqual(manager.getCurrentMinutes(), 0)
        
        let accepted = manager.updateUsage(newMinutes: 60)
        
        XCTAssertTrue(accepted, "First update up to 60 should be accepted")
        XCTAssertEqual(manager.getCurrentMinutes(), 60)
    }
    
    func testFirstUpdateRejectsOver60() {
        XCTAssertEqual(manager.getCurrentMinutes(), 0)
        
        let accepted = manager.updateUsage(newMinutes: 61)
        
        XCTAssertFalse(accepted, "First update over 60 should be rejected")
        XCTAssertEqual(manager.getCurrentMinutes(), 0)
    }
    
    // 0-120 mins: max increase is 30
    func testLowUsageAcceptsUpTo30Increase() {
        manager.forceSetUsage(minutes: 50)
        
        let accepted = manager.updateUsage(newMinutes: 80)  // +30
        
        XCTAssertTrue(accepted, "Increase of 30 at low usage should be accepted")
        XCTAssertEqual(manager.getCurrentMinutes(), 80)
    }
    
    func testLowUsageRejectsOver30Increase() {
        manager.forceSetUsage(minutes: 50)
        
        let accepted = manager.updateUsage(newMinutes: 81)  // +31
        
        XCTAssertFalse(accepted, "Increase of 31 at low usage should be rejected")
        XCTAssertEqual(manager.getCurrentMinutes(), 50)
    }
    
    // 120-300 mins: max increase is 60
    func testMidUsageAcceptsUpTo60Increase() {
        manager.forceSetUsage(minutes: 150)
        
        let accepted = manager.updateUsage(newMinutes: 210)  // +60
        
        XCTAssertTrue(accepted, "Increase of 60 at mid usage should be accepted")
        XCTAssertEqual(manager.getCurrentMinutes(), 210)
    }
    
    func testMidUsageRejectsOver60Increase() {
        manager.forceSetUsage(minutes: 150)
        
        let accepted = manager.updateUsage(newMinutes: 211)  // +61
        
        XCTAssertFalse(accepted, "Increase of 61 at mid usage should be rejected")
        XCTAssertEqual(manager.getCurrentMinutes(), 150)
    }
    
    // 300+ mins: max increase is 90
    func testHighUsageAcceptsUpTo90Increase() {
        manager.forceSetUsage(minutes: 350)
        
        let accepted = manager.updateUsage(newMinutes: 440)  // +90
        
        XCTAssertTrue(accepted, "Increase of 90 at high usage should be accepted")
        XCTAssertEqual(manager.getCurrentMinutes(), 440)
    }
    
    func testHighUsageRejectsOver90Increase() {
        manager.forceSetUsage(minutes: 350)
        
        let accepted = manager.updateUsage(newMinutes: 441)  // +91
        
        XCTAssertFalse(accepted, "Increase of 91 at high usage should be rejected")
        XCTAssertEqual(manager.getCurrentMinutes(), 350)
    }
    
    // MARK: - Realistic Threshold Sequences
    
    func testNormalThresholdSequence() {
        // Simulate normal usage: 5 -> 10 -> 15 -> 20 -> 25
        XCTAssertTrue(manager.updateUsage(newMinutes: 5))
        XCTAssertTrue(manager.updateUsage(newMinutes: 10))
        XCTAssertTrue(manager.updateUsage(newMinutes: 15))
        XCTAssertTrue(manager.updateUsage(newMinutes: 20))
        XCTAssertTrue(manager.updateUsage(newMinutes: 25))
        
        XCTAssertEqual(manager.getCurrentMinutes(), 25)
    }
    
    func testSkippedThresholdsWithinLimit() {
        // Start at 5, skip some, jump to 30 (increase of 25, within 30 limit for low usage)
        XCTAssertTrue(manager.updateUsage(newMinutes: 5))
        XCTAssertTrue(manager.updateUsage(newMinutes: 30))  // +25
        XCTAssertTrue(manager.updateUsage(newMinutes: 60))  // +30
        
        XCTAssertEqual(manager.getCurrentMinutes(), 60)
    }
    
    func testLargeSkipRejectedAtLowUsage() {
        manager.forceSetUsage(minutes: 20)
        
        // Try to jump from 20 to 60 (increase of 40, > 30 limit for low usage)
        let accepted = manager.updateUsage(newMinutes: 60)
        
        XCTAssertFalse(accepted, "Large skip of 40 at low usage should be rejected")
        XCTAssertEqual(manager.getCurrentMinutes(), 20)
    }
    
    // MARK: - Stale Event Rejection
    
    func testStaleEventOnFreshDay() {
        XCTAssertEqual(manager.getCurrentMinutes(), 0)
        
        let accepted = manager.updateUsage(newMinutes: 180)
        
        XCTAssertFalse(accepted, "180 min stale event should be rejected on fresh day")
        XCTAssertEqual(manager.getCurrentMinutes(), 0)
    }
    
    func testStaleEventAfterRealUsage() {
        manager.forceSetUsage(minutes: 50)
        
        // Stale event tries to jump to 180 (increase of 130, > 30 limit)
        let accepted = manager.updateUsage(newMinutes: 180)
        
        XCTAssertFalse(accepted, "Jump of 130 at low usage should be rejected")
        XCTAssertEqual(manager.getCurrentMinutes(), 50)
    }
    
    // MARK: - User's Reported Issues
    
    func testRealUserScenario_75to104() {
        // User's issue: Screen Time shows 104, app stuck at 75
        // Increase is 104 - 75 = 29, which is within 30 limit for low usage
        manager.forceSetUsage(minutes: 75)
        
        let accepted = manager.updateUsage(newMinutes: 104)
        
        XCTAssertTrue(accepted, "75 -> 104 (increase of 29) should be accepted")
        XCTAssertEqual(manager.getCurrentMinutes(), 104)
    }
    
    func testRealUserScenario_180to251() {
        // User used 251 mins but only saw 180
        // At 180 mins (mid-usage), max increase is 60
        // Need to simulate proper threshold progression
        manager.forceSetUsage(minutes: 180)
        
        // 180 -> 230 should work (increase of 50, within 60 limit for mid-usage)
        XCTAssertTrue(manager.updateUsage(newMinutes: 230))
        
        // 230 -> 251 should work (increase of 21, within 60 limit)
        XCTAssertTrue(manager.updateUsage(newMinutes: 251))
        
        XCTAssertEqual(manager.getCurrentMinutes(), 251)
    }
    
    // MARK: - Date String Tests
    
    func testDateStringFormat() {
        let data = ScreenTimeUsageData(date: Date(), totalMinutes: 0)
        
        let dateRegex = #"^\d{4}-\d{2}-\d{2}$"#
        XCTAssertTrue(data.dateString.range(of: dateRegex, options: .regularExpression) != nil)
    }
    
    func testIsTodayCheck() {
        let todayData = ScreenTimeUsageData(date: Date(), totalMinutes: 10)
        XCTAssertTrue(todayData.isToday)
        
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let yesterdayData = ScreenTimeUsageData(date: yesterday, totalMinutes: 10)
        XCTAssertFalse(yesterdayData.isToday)
    }
    
    // MARK: - Edge Cases
    
    func testZeroValueAccepted() {
        let accepted = manager.updateUsage(newMinutes: 0)
        XCTAssertTrue(accepted, "Zero should be valid first value")
    }
    
    func testMultipleUpdatesWithinDay() {
        // Simulate full day with proper threshold intervals
        XCTAssertTrue(manager.updateUsage(newMinutes: 10))    // First: +10
        XCTAssertTrue(manager.updateUsage(newMinutes: 30))    // Low: +20
        XCTAssertTrue(manager.updateUsage(newMinutes: 60))    // Low: +30
        XCTAssertTrue(manager.updateUsage(newMinutes: 90))    // Low: +30
        XCTAssertTrue(manager.updateUsage(newMinutes: 120))   // Low: +30
        // Now at 120, transitions to mid-usage limits
        XCTAssertTrue(manager.updateUsage(newMinutes: 170))   // Mid: +50
        XCTAssertTrue(manager.updateUsage(newMinutes: 220))   // Mid: +50
        XCTAssertTrue(manager.updateUsage(newMinutes: 280))   // Mid: +60
        // Now at 280, still mid-usage
        XCTAssertTrue(manager.updateUsage(newMinutes: 340))   // High: +60
        // At 340, now high-usage limits apply (>300)
        XCTAssertTrue(manager.updateUsage(newMinutes: 420))   // High: +80
        
        XCTAssertEqual(manager.getCurrentMinutes(), 420)
    }
    
    func testFullDayHeavyUsage() {
        // Simulate 8 hours of usage
        manager.forceSetUsage(minutes: 60)   // Start at 1 hour
        XCTAssertTrue(manager.updateUsage(newMinutes: 90))    // +30
        XCTAssertTrue(manager.updateUsage(newMinutes: 120))   // +30
        XCTAssertTrue(manager.updateUsage(newMinutes: 180))   // Mid: +60
        XCTAssertTrue(manager.updateUsage(newMinutes: 240))   // Mid: +60
        XCTAssertTrue(manager.updateUsage(newMinutes: 300))   // Mid: +60
        XCTAssertTrue(manager.updateUsage(newMinutes: 380))   // High: +80
        XCTAssertTrue(manager.updateUsage(newMinutes: 460))   // High: +80
        
        XCTAssertEqual(manager.getCurrentMinutes(), 460)
    }
}

//  UnhookedTests
//
//  Unit tests for ScreenTimeUsageManager
//

import XCTest
@testable import Unhooked

final class ScreenTimeUsageTests: XCTestCase {
    
    var manager: ScreenTimeUsageManager!
    var testDefaults: UserDefaults!
    
    override func setUp() {
        super.setUp()
        testDefaults = UserDefaults(suiteName: "test.screentime.usage")!
        testDefaults.removePersistentDomain(forName: "test.screentime.usage")
        
        manager = ScreenTimeUsageManager()
        manager.userDefaultsOverride = testDefaults
    }
    
    override func tearDown() {
        testDefaults.removePersistentDomain(forName: "test.screentime.usage")
        manager = nil
        testDefaults = nil
        super.tearDown()
    }
    
    // MARK: - Basic Save/Load Tests
    
    func testSaveAndLoadUsage() {
        XCTAssertNil(manager.loadUsage())
        
        let data = ScreenTimeUsageData(date: Date(), totalMinutes: 25)
        manager.saveUsage(data)
        
        let loaded = manager.loadUsage()
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.totalMinutes, 25)
        XCTAssertTrue(loaded?.isToday ?? false)
    }
    
    func testLoadReturnsNilForStaleData() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let staleData = ScreenTimeUsageData(date: yesterday, totalMinutes: 100)
        
        let encoded = try! JSONEncoder().encode(staleData)
        testDefaults.set(encoded, forKey: "screentime.usage.v3")
        
        let loaded = manager.loadUsage()
        XCTAssertNil(loaded, "Stale data should return nil")
    }
    
    func testClearUsageData() {
        manager.forceSetUsage(minutes: 50)
        XCTAssertEqual(manager.getCurrentMinutes(), 50)
        
        manager.clearUsageData()
        
        XCTAssertNil(manager.loadUsage())
        XCTAssertEqual(manager.getCurrentMinutes(), 0)
    }
    
    // MARK: - Update Validation: Never Go Backwards
    
    func testUpdateRejectsDecreasingValue() {
        manager.forceSetUsage(minutes: 30)
        
        let accepted = manager.updateUsage(newMinutes: 20)
        
        XCTAssertFalse(accepted, "Decreasing value should be rejected")
        XCTAssertEqual(manager.getCurrentMinutes(), 30)
    }
    
    func testUpdateAcceptsSameValue() {
        manager.forceSetUsage(minutes: 15)
        
        let accepted = manager.updateUsage(newMinutes: 15)
        
        XCTAssertTrue(accepted, "Same value should be accepted")
        XCTAssertEqual(manager.getCurrentMinutes(), 15)
    }
    
    // MARK: - Update Validation: Max Increase Limits
    
    func testFirstUpdateAcceptsUpTo60() {
        XCTAssertEqual(manager.getCurrentMinutes(), 0)
        
        let accepted = manager.updateUsage(newMinutes: 60)
        
        XCTAssertTrue(accepted, "First update up to 60 should be accepted")
        XCTAssertEqual(manager.getCurrentMinutes(), 60)
    }
    
    func testFirstUpdateRejectsOver60() {
        XCTAssertEqual(manager.getCurrentMinutes(), 0)
        
        let accepted = manager.updateUsage(newMinutes: 61)
        
        XCTAssertFalse(accepted, "First update over 60 should be rejected")
        XCTAssertEqual(manager.getCurrentMinutes(), 0)
    }
    
    // 0-120 mins: max increase is 30
    func testLowUsageAcceptsUpTo30Increase() {
        manager.forceSetUsage(minutes: 50)
        
        let accepted = manager.updateUsage(newMinutes: 80)  // +30
        
        XCTAssertTrue(accepted, "Increase of 30 at low usage should be accepted")
        XCTAssertEqual(manager.getCurrentMinutes(), 80)
    }
    
    func testLowUsageRejectsOver30Increase() {
        manager.forceSetUsage(minutes: 50)
        
        let accepted = manager.updateUsage(newMinutes: 81)  // +31
        
        XCTAssertFalse(accepted, "Increase of 31 at low usage should be rejected")
        XCTAssertEqual(manager.getCurrentMinutes(), 50)
    }
    
    // 120-300 mins: max increase is 60
    func testMidUsageAcceptsUpTo60Increase() {
        manager.forceSetUsage(minutes: 150)
        
        let accepted = manager.updateUsage(newMinutes: 210)  // +60
        
        XCTAssertTrue(accepted, "Increase of 60 at mid usage should be accepted")
        XCTAssertEqual(manager.getCurrentMinutes(), 210)
    }
    
    func testMidUsageRejectsOver60Increase() {
        manager.forceSetUsage(minutes: 150)
        
        let accepted = manager.updateUsage(newMinutes: 211)  // +61
        
        XCTAssertFalse(accepted, "Increase of 61 at mid usage should be rejected")
        XCTAssertEqual(manager.getCurrentMinutes(), 150)
    }
    
    // 300+ mins: max increase is 90
    func testHighUsageAcceptsUpTo90Increase() {
        manager.forceSetUsage(minutes: 350)
        
        let accepted = manager.updateUsage(newMinutes: 440)  // +90
        
        XCTAssertTrue(accepted, "Increase of 90 at high usage should be accepted")
        XCTAssertEqual(manager.getCurrentMinutes(), 440)
    }
    
    func testHighUsageRejectsOver90Increase() {
        manager.forceSetUsage(minutes: 350)
        
        let accepted = manager.updateUsage(newMinutes: 441)  // +91
        
        XCTAssertFalse(accepted, "Increase of 91 at high usage should be rejected")
        XCTAssertEqual(manager.getCurrentMinutes(), 350)
    }
    
    // MARK: - Realistic Threshold Sequences
    
    func testNormalThresholdSequence() {
        // Simulate normal usage: 5 -> 10 -> 15 -> 20 -> 25
        XCTAssertTrue(manager.updateUsage(newMinutes: 5))
        XCTAssertTrue(manager.updateUsage(newMinutes: 10))
        XCTAssertTrue(manager.updateUsage(newMinutes: 15))
        XCTAssertTrue(manager.updateUsage(newMinutes: 20))
        XCTAssertTrue(manager.updateUsage(newMinutes: 25))
        
        XCTAssertEqual(manager.getCurrentMinutes(), 25)
    }
    
    func testSkippedThresholdsWithinLimit() {
        // Start at 5, skip some, jump to 30 (increase of 25, within 30 limit for low usage)
        XCTAssertTrue(manager.updateUsage(newMinutes: 5))
        XCTAssertTrue(manager.updateUsage(newMinutes: 30))  // +25
        XCTAssertTrue(manager.updateUsage(newMinutes: 60))  // +30
        
        XCTAssertEqual(manager.getCurrentMinutes(), 60)
    }
    
    func testLargeSkipRejectedAtLowUsage() {
        manager.forceSetUsage(minutes: 20)
        
        // Try to jump from 20 to 60 (increase of 40, > 30 limit for low usage)
        let accepted = manager.updateUsage(newMinutes: 60)
        
        XCTAssertFalse(accepted, "Large skip of 40 at low usage should be rejected")
        XCTAssertEqual(manager.getCurrentMinutes(), 20)
    }
    
    // MARK: - Stale Event Rejection
    
    func testStaleEventOnFreshDay() {
        XCTAssertEqual(manager.getCurrentMinutes(), 0)
        
        let accepted = manager.updateUsage(newMinutes: 180)
        
        XCTAssertFalse(accepted, "180 min stale event should be rejected on fresh day")
        XCTAssertEqual(manager.getCurrentMinutes(), 0)
    }
    
    func testStaleEventAfterRealUsage() {
        manager.forceSetUsage(minutes: 50)
        
        // Stale event tries to jump to 180 (increase of 130, > 30 limit)
        let accepted = manager.updateUsage(newMinutes: 180)
        
        XCTAssertFalse(accepted, "Jump of 130 at low usage should be rejected")
        XCTAssertEqual(manager.getCurrentMinutes(), 50)
    }
    
    // MARK: - User's Reported Issues
    
    func testRealUserScenario_75to104() {
        // User's issue: Screen Time shows 104, app stuck at 75
        // Increase is 104 - 75 = 29, which is within 30 limit for low usage
        manager.forceSetUsage(minutes: 75)
        
        let accepted = manager.updateUsage(newMinutes: 104)
        
        XCTAssertTrue(accepted, "75 -> 104 (increase of 29) should be accepted")
        XCTAssertEqual(manager.getCurrentMinutes(), 104)
    }
    
    func testRealUserScenario_180to251() {
        // User used 251 mins but only saw 180
        // At 180 mins (mid-usage), max increase is 60
        // Need to simulate proper threshold progression
        manager.forceSetUsage(minutes: 180)
        
        // 180 -> 230 should work (increase of 50, within 60 limit for mid-usage)
        XCTAssertTrue(manager.updateUsage(newMinutes: 230))
        
        // 230 -> 251 should work (increase of 21, within 60 limit)
        XCTAssertTrue(manager.updateUsage(newMinutes: 251))
        
        XCTAssertEqual(manager.getCurrentMinutes(), 251)
    }
    
    // MARK: - Date String Tests
    
    func testDateStringFormat() {
        let data = ScreenTimeUsageData(date: Date(), totalMinutes: 0)
        
        let dateRegex = #"^\d{4}-\d{2}-\d{2}$"#
        XCTAssertTrue(data.dateString.range(of: dateRegex, options: .regularExpression) != nil)
    }
    
    func testIsTodayCheck() {
        let todayData = ScreenTimeUsageData(date: Date(), totalMinutes: 10)
        XCTAssertTrue(todayData.isToday)
        
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let yesterdayData = ScreenTimeUsageData(date: yesterday, totalMinutes: 10)
        XCTAssertFalse(yesterdayData.isToday)
    }
    
    // MARK: - Edge Cases
    
    func testZeroValueAccepted() {
        let accepted = manager.updateUsage(newMinutes: 0)
        XCTAssertTrue(accepted, "Zero should be valid first value")
    }
    
    func testMultipleUpdatesWithinDay() {
        // Simulate full day with proper threshold intervals
        XCTAssertTrue(manager.updateUsage(newMinutes: 10))    // First: +10
        XCTAssertTrue(manager.updateUsage(newMinutes: 30))    // Low: +20
        XCTAssertTrue(manager.updateUsage(newMinutes: 60))    // Low: +30
        XCTAssertTrue(manager.updateUsage(newMinutes: 90))    // Low: +30
        XCTAssertTrue(manager.updateUsage(newMinutes: 120))   // Low: +30
        // Now at 120, transitions to mid-usage limits
        XCTAssertTrue(manager.updateUsage(newMinutes: 170))   // Mid: +50
        XCTAssertTrue(manager.updateUsage(newMinutes: 220))   // Mid: +50
        XCTAssertTrue(manager.updateUsage(newMinutes: 280))   // Mid: +60
        // Now at 280, still mid-usage
        XCTAssertTrue(manager.updateUsage(newMinutes: 340))   // High: +60
        // At 340, now high-usage limits apply (>300)
        XCTAssertTrue(manager.updateUsage(newMinutes: 420))   // High: +80
        
        XCTAssertEqual(manager.getCurrentMinutes(), 420)
    }
    
    func testFullDayHeavyUsage() {
        // Simulate 8 hours of usage
        manager.forceSetUsage(minutes: 60)   // Start at 1 hour
        XCTAssertTrue(manager.updateUsage(newMinutes: 90))    // +30
        XCTAssertTrue(manager.updateUsage(newMinutes: 120))   // +30
        XCTAssertTrue(manager.updateUsage(newMinutes: 180))   // Mid: +60
        XCTAssertTrue(manager.updateUsage(newMinutes: 240))   // Mid: +60
        XCTAssertTrue(manager.updateUsage(newMinutes: 300))   // Mid: +60
        XCTAssertTrue(manager.updateUsage(newMinutes: 380))   // High: +80
        XCTAssertTrue(manager.updateUsage(newMinutes: 460))   // High: +80
        
        XCTAssertEqual(manager.getCurrentMinutes(), 460)
    }
}

//  UnhookedTests
//
//  Unit tests for ScreenTimeUsageManager
//

import XCTest
@testable import Unhooked

final class ScreenTimeUsageTests: XCTestCase {
    
    var manager: ScreenTimeUsageManager!
    var testDefaults: UserDefaults!
    
    override func setUp() {
        super.setUp()
        testDefaults = UserDefaults(suiteName: "test.screentime.usage")!
        testDefaults.removePersistentDomain(forName: "test.screentime.usage")
        
        manager = ScreenTimeUsageManager()
        manager.userDefaultsOverride = testDefaults
    }
    
    override func tearDown() {
        testDefaults.removePersistentDomain(forName: "test.screentime.usage")
        manager = nil
        testDefaults = nil
        super.tearDown()
    }
    
    // MARK: - Basic Save/Load Tests
    
    func testSaveAndLoadUsage() {
        XCTAssertNil(manager.loadUsage())
        
        let data = ScreenTimeUsageData(date: Date(), totalMinutes: 25)
        manager.saveUsage(data)
        
        let loaded = manager.loadUsage()
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.totalMinutes, 25)
        XCTAssertTrue(loaded?.isToday ?? false)
    }
    
    func testLoadReturnsNilForStaleData() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let staleData = ScreenTimeUsageData(date: yesterday, totalMinutes: 100)
        
        let encoded = try! JSONEncoder().encode(staleData)
        testDefaults.set(encoded, forKey: "screentime.usage.v3")
        
        let loaded = manager.loadUsage()
        XCTAssertNil(loaded, "Stale data should return nil")
    }
    
    func testClearUsageData() {
        manager.forceSetUsage(minutes: 50)
        XCTAssertEqual(manager.getCurrentMinutes(), 50)
        
        manager.clearUsageData()
        
        XCTAssertNil(manager.loadUsage())
        XCTAssertEqual(manager.getCurrentMinutes(), 0)
    }
    
    // MARK: - Update Validation: Never Go Backwards
    
    func testUpdateRejectsDecreasingValue() {
        manager.forceSetUsage(minutes: 30)
        
        let accepted = manager.updateUsage(newMinutes: 20)
        
        XCTAssertFalse(accepted, "Decreasing value should be rejected")
        XCTAssertEqual(manager.getCurrentMinutes(), 30)
    }
    
    func testUpdateAcceptsSameValue() {
        manager.forceSetUsage(minutes: 15)
        
        let accepted = manager.updateUsage(newMinutes: 15)
        
        XCTAssertTrue(accepted, "Same value should be accepted")
        XCTAssertEqual(manager.getCurrentMinutes(), 15)
    }
    
    // MARK: - Update Validation: Max Increase Limits
    
    func testFirstUpdateAcceptsUpTo60() {
        XCTAssertEqual(manager.getCurrentMinutes(), 0)
        
        let accepted = manager.updateUsage(newMinutes: 60)
        
        XCTAssertTrue(accepted, "First update up to 60 should be accepted")
        XCTAssertEqual(manager.getCurrentMinutes(), 60)
    }
    
    func testFirstUpdateRejectsOver60() {
        XCTAssertEqual(manager.getCurrentMinutes(), 0)
        
        let accepted = manager.updateUsage(newMinutes: 61)
        
        XCTAssertFalse(accepted, "First update over 60 should be rejected")
        XCTAssertEqual(manager.getCurrentMinutes(), 0)
    }
    
    // 0-120 mins: max increase is 30
    func testLowUsageAcceptsUpTo30Increase() {
        manager.forceSetUsage(minutes: 50)
        
        let accepted = manager.updateUsage(newMinutes: 80)  // +30
        
        XCTAssertTrue(accepted, "Increase of 30 at low usage should be accepted")
        XCTAssertEqual(manager.getCurrentMinutes(), 80)
    }
    
    func testLowUsageRejectsOver30Increase() {
        manager.forceSetUsage(minutes: 50)
        
        let accepted = manager.updateUsage(newMinutes: 81)  // +31
        
        XCTAssertFalse(accepted, "Increase of 31 at low usage should be rejected")
        XCTAssertEqual(manager.getCurrentMinutes(), 50)
    }
    
    // 120-300 mins: max increase is 60
    func testMidUsageAcceptsUpTo60Increase() {
        manager.forceSetUsage(minutes: 150)
        
        let accepted = manager.updateUsage(newMinutes: 210)  // +60
        
        XCTAssertTrue(accepted, "Increase of 60 at mid usage should be accepted")
        XCTAssertEqual(manager.getCurrentMinutes(), 210)
    }
    
    func testMidUsageRejectsOver60Increase() {
        manager.forceSetUsage(minutes: 150)
        
        let accepted = manager.updateUsage(newMinutes: 211)  // +61
        
        XCTAssertFalse(accepted, "Increase of 61 at mid usage should be rejected")
        XCTAssertEqual(manager.getCurrentMinutes(), 150)
    }
    
    // 300+ mins: max increase is 90
    func testHighUsageAcceptsUpTo90Increase() {
        manager.forceSetUsage(minutes: 350)
        
        let accepted = manager.updateUsage(newMinutes: 440)  // +90
        
        XCTAssertTrue(accepted, "Increase of 90 at high usage should be accepted")
        XCTAssertEqual(manager.getCurrentMinutes(), 440)
    }
    
    func testHighUsageRejectsOver90Increase() {
        manager.forceSetUsage(minutes: 350)
        
        let accepted = manager.updateUsage(newMinutes: 441)  // +91
        
        XCTAssertFalse(accepted, "Increase of 91 at high usage should be rejected")
        XCTAssertEqual(manager.getCurrentMinutes(), 350)
    }
    
    // MARK: - Realistic Threshold Sequences
    
    func testNormalThresholdSequence() {
        // Simulate normal usage: 5 -> 10 -> 15 -> 20 -> 25
        XCTAssertTrue(manager.updateUsage(newMinutes: 5))
        XCTAssertTrue(manager.updateUsage(newMinutes: 10))
        XCTAssertTrue(manager.updateUsage(newMinutes: 15))
        XCTAssertTrue(manager.updateUsage(newMinutes: 20))
        XCTAssertTrue(manager.updateUsage(newMinutes: 25))
        
        XCTAssertEqual(manager.getCurrentMinutes(), 25)
    }
    
    func testSkippedThresholdsWithinLimit() {
        // Start at 5, skip some, jump to 30 (increase of 25, within 30 limit for low usage)
        XCTAssertTrue(manager.updateUsage(newMinutes: 5))
        XCTAssertTrue(manager.updateUsage(newMinutes: 30))  // +25
        XCTAssertTrue(manager.updateUsage(newMinutes: 60))  // +30
        
        XCTAssertEqual(manager.getCurrentMinutes(), 60)
    }
    
    func testLargeSkipRejectedAtLowUsage() {
        manager.forceSetUsage(minutes: 20)
        
        // Try to jump from 20 to 60 (increase of 40, > 30 limit for low usage)
        let accepted = manager.updateUsage(newMinutes: 60)
        
        XCTAssertFalse(accepted, "Large skip of 40 at low usage should be rejected")
        XCTAssertEqual(manager.getCurrentMinutes(), 20)
    }
    
    // MARK: - Stale Event Rejection
    
    func testStaleEventOnFreshDay() {
        XCTAssertEqual(manager.getCurrentMinutes(), 0)
        
        let accepted = manager.updateUsage(newMinutes: 180)
        
        XCTAssertFalse(accepted, "180 min stale event should be rejected on fresh day")
        XCTAssertEqual(manager.getCurrentMinutes(), 0)
    }
    
    func testStaleEventAfterRealUsage() {
        manager.forceSetUsage(minutes: 50)
        
        // Stale event tries to jump to 180 (increase of 130, > 30 limit)
        let accepted = manager.updateUsage(newMinutes: 180)
        
        XCTAssertFalse(accepted, "Jump of 130 at low usage should be rejected")
        XCTAssertEqual(manager.getCurrentMinutes(), 50)
    }
    
    // MARK: - User's Reported Issues
    
    func testRealUserScenario_75to104() {
        // User's issue: Screen Time shows 104, app stuck at 75
        // Increase is 104 - 75 = 29, which is within 30 limit for low usage
        manager.forceSetUsage(minutes: 75)
        
        let accepted = manager.updateUsage(newMinutes: 104)
        
        XCTAssertTrue(accepted, "75 -> 104 (increase of 29) should be accepted")
        XCTAssertEqual(manager.getCurrentMinutes(), 104)
    }
    
    func testRealUserScenario_180to251() {
        // User used 251 mins but only saw 180
        // At 180 mins (mid-usage), max increase is 60
        // Need to simulate proper threshold progression
        manager.forceSetUsage(minutes: 180)
        
        // 180 -> 230 should work (increase of 50, within 60 limit for mid-usage)
        XCTAssertTrue(manager.updateUsage(newMinutes: 230))
        
        // 230 -> 251 should work (increase of 21, within 60 limit)
        XCTAssertTrue(manager.updateUsage(newMinutes: 251))
        
        XCTAssertEqual(manager.getCurrentMinutes(), 251)
    }
    
    // MARK: - Date String Tests
    
    func testDateStringFormat() {
        let data = ScreenTimeUsageData(date: Date(), totalMinutes: 0)
        
        let dateRegex = #"^\d{4}-\d{2}-\d{2}$"#
        XCTAssertTrue(data.dateString.range(of: dateRegex, options: .regularExpression) != nil)
    }
    
    func testIsTodayCheck() {
        let todayData = ScreenTimeUsageData(date: Date(), totalMinutes: 10)
        XCTAssertTrue(todayData.isToday)
        
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let yesterdayData = ScreenTimeUsageData(date: yesterday, totalMinutes: 10)
        XCTAssertFalse(yesterdayData.isToday)
    }
    
    // MARK: - Edge Cases
    
    func testZeroValueAccepted() {
        let accepted = manager.updateUsage(newMinutes: 0)
        XCTAssertTrue(accepted, "Zero should be valid first value")
    }
    
    func testMultipleUpdatesWithinDay() {
        // Simulate full day with proper threshold intervals
        XCTAssertTrue(manager.updateUsage(newMinutes: 10))    // First: +10
        XCTAssertTrue(manager.updateUsage(newMinutes: 30))    // Low: +20
        XCTAssertTrue(manager.updateUsage(newMinutes: 60))    // Low: +30
        XCTAssertTrue(manager.updateUsage(newMinutes: 90))    // Low: +30
        XCTAssertTrue(manager.updateUsage(newMinutes: 120))   // Low: +30
        // Now at 120, transitions to mid-usage limits
        XCTAssertTrue(manager.updateUsage(newMinutes: 170))   // Mid: +50
        XCTAssertTrue(manager.updateUsage(newMinutes: 220))   // Mid: +50
        XCTAssertTrue(manager.updateUsage(newMinutes: 280))   // Mid: +60
        // Now at 280, still mid-usage
        XCTAssertTrue(manager.updateUsage(newMinutes: 340))   // High: +60
        // At 340, now high-usage limits apply (>300)
        XCTAssertTrue(manager.updateUsage(newMinutes: 420))   // High: +80
        
        XCTAssertEqual(manager.getCurrentMinutes(), 420)
    }
    
    func testFullDayHeavyUsage() {
        // Simulate 8 hours of usage
        manager.forceSetUsage(minutes: 60)   // Start at 1 hour
        XCTAssertTrue(manager.updateUsage(newMinutes: 90))    // +30
        XCTAssertTrue(manager.updateUsage(newMinutes: 120))   // +30
        XCTAssertTrue(manager.updateUsage(newMinutes: 180))   // Mid: +60
        XCTAssertTrue(manager.updateUsage(newMinutes: 240))   // Mid: +60
        XCTAssertTrue(manager.updateUsage(newMinutes: 300))   // Mid: +60
        XCTAssertTrue(manager.updateUsage(newMinutes: 380))   // High: +80
        XCTAssertTrue(manager.updateUsage(newMinutes: 460))   // High: +80
        
        XCTAssertEqual(manager.getCurrentMinutes(), 460)
    }
}
