//
//  ScreenTimeUsage.swift
//  Unhooked
//
//  Shared data structure for Screen Time usage tracking
//

import Foundation

/// Shared usage data structure that can be saved to App Group
struct ScreenTimeUsageData: Codable, Equatable {
    var dateString: String  // Store as "YYYY-MM-DD" for reliable day comparison
    var totalMinutes: Int
    var lastUpdated: Date
    
    init(date: Date = Date(), totalMinutes: Int = 0) {
        self.dateString = Self.formatDate(date)
        self.totalMinutes = totalMinutes
        self.lastUpdated = date
    }
    
    /// Format date as YYYY-MM-DD string for reliable comparison
    static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        return formatter.string(from: date)
    }
    
    /// Get today's date string
    static var todayString: String {
        formatDate(Date())
    }
    
    /// Check if this data is for today
    var isToday: Bool {
        dateString == Self.todayString
    }
}

/// Manager for reading/writing usage data via App Group
class ScreenTimeUsageManager {
    static let shared = ScreenTimeUsageManager()
    
    private let appGroupID = "group.com.kookytrove.unhooked"
    private let usageKey = "screentime.usage.v3"  // v3 format
    
    // For testing - allow injection of custom UserDefaults
    var userDefaultsOverride: UserDefaults?
    
    private var userDefaults: UserDefaults? {
        userDefaultsOverride ?? UserDefaults(suiteName: appGroupID)
    }
    
    // MARK: - Core Operations
    
    /// Load usage data - returns nil if no data or data is stale
    func loadUsage() -> ScreenTimeUsageData? {
        guard let defaults = userDefaults else {
            print("❌ loadUsage: Failed to get UserDefaults")
            return nil
        }
        
        guard let data = defaults.data(forKey: usageKey) else {
            print("📖 loadUsage: No data found")
            return nil
        }
        
        guard let decoded = try? JSONDecoder().decode(ScreenTimeUsageData.self, from: data) else {
            print("❌ loadUsage: Failed to decode, clearing corrupted data")
            defaults.removeObject(forKey: usageKey)
            return nil
        }
        
        // CRITICAL: If data is not from today, return nil (not stale data)
        if !decoded.isToday {
            print("📖 loadUsage: Data is from \(decoded.dateString), not today (\(ScreenTimeUsageData.todayString)) - returning nil")
            // Clear the stale data
            defaults.removeObject(forKey: usageKey)
            defaults.synchronize()
            return nil
        }
        
        print("📖 loadUsage: Loaded \(decoded.totalMinutes) mins for \(decoded.dateString)")
        return decoded
    }
    
    /// Save usage data - only saves if data is for today
    func saveUsage(_ data: ScreenTimeUsageData) {
        guard data.isToday else {
            print("❌ saveUsage: Rejecting save - data is not for today")
            return
        }
        
        guard let defaults = userDefaults else {
            print("❌ saveUsage: Failed to get UserDefaults")
            return
        }
        
        guard let encoded = try? JSONEncoder().encode(data) else {
            print("❌ saveUsage: Failed to encode data")
            return
        }
        
        defaults.set(encoded, forKey: usageKey)
        defaults.synchronize()
        print("💾 saveUsage: Saved \(data.totalMinutes) mins for \(data.dateString)")
    }
    
    /// Update usage with a new threshold value
    /// Returns true if update was accepted, false if rejected
    @discardableResult
    func updateUsage(newMinutes: Int) -> Bool {
        let current = loadUsage()
        let currentMinutes = current?.totalMinutes ?? 0
        
        print("📊 updateUsage: current=\(currentMinutes), new=\(newMinutes)")
        
        // Rule 1: Never go backwards
        if newMinutes < currentMinutes {
            print("❌ Rejected: \(newMinutes) < current \(currentMinutes)")
            return false
        }
        
        // Rule 2: Cap max increase based on current usage level
        let increase = newMinutes - currentMinutes
        
        // Dynamic max based on where we are in the day:
        // - First update (0 mins): max 60 (catch delayed first threshold)
        // - 0-120 mins: max 30 (5-min intervals, allow 6 skipped)
        // - 120-300 mins: max 60 (10-min intervals, allow 6 skipped)
        // - 300+ mins: max 90 (15-min intervals, allow 6 skipped)
        let maxAllowedIncrease: Int
        if currentMinutes == 0 {
            maxAllowedIncrease = 60
        } else if currentMinutes <= 120 {
            maxAllowedIncrease = 30
        } else if currentMinutes <= 300 {
            maxAllowedIncrease = 60
        } else {
            maxAllowedIncrease = 90
        }
        
        if increase > maxAllowedIncrease {
            print("❌ Rejected: increase \(increase) > max \(maxAllowedIncrease) (at \(currentMinutes) mins)")
            return false
        }
        
        // Accept the update
        let newData = ScreenTimeUsageData(date: Date(), totalMinutes: newMinutes)
        saveUsage(newData)
        print("✅ Accepted: \(currentMinutes) -> \(newMinutes) mins (+\(increase))")
        return true
    }
    
    /// Clear all usage data
    func clearUsageData() {
        guard let defaults = userDefaults else {
            print("❌ clearUsageData: Failed to get UserDefaults")
            return
        }
        
        defaults.removeObject(forKey: usageKey)
        defaults.synchronize()
        print("🗑️ clearUsageData: Cleared")
    }
    
    /// Get current usage minutes (0 if no data for today)
    func getCurrentMinutes() -> Int {
        return loadUsage()?.totalMinutes ?? 0
    }
    
    /// Force set usage (for debugging only - bypasses all checks)
    func forceSetUsage(minutes: Int) {
        let data = ScreenTimeUsageData(date: Date(), totalMinutes: minutes)
        
        guard let defaults = userDefaults else { return }
        guard let encoded = try? JSONEncoder().encode(data) else { return }
        
        defaults.set(encoded, forKey: usageKey)
        defaults.synchronize()
        print("🔧 forceSetUsage: Set to \(minutes) mins")
    }
    
    /// Test App Group access
    func testAppGroupAccess() -> Bool {
        guard let defaults = userDefaults else {
            print("❌ testAppGroupAccess: Cannot access App Group")
            return false
        }
        
        let testKey = "test.access"
        let testValue = UUID().uuidString
        
        defaults.set(testValue, forKey: testKey)
        defaults.synchronize()
        
        let readValue = defaults.string(forKey: testKey)
        defaults.removeObject(forKey: testKey)
        
        let success = readValue == testValue
        print(success ? "✅ App Group access working" : "❌ App Group access failed")
        return success
    }
}
