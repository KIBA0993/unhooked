//
//  ScreenTimeService.swift
//  Unhooked
//
//  Screen Time API integration for usage tracking
//

import Foundation
import Combine
import FamilyControls
import DeviceActivity

@MainActor
class ScreenTimeService: ObservableObject {
    @Published var isAuthorized = false
    @Published var dailyLimit: Int = 180  // minutes, default 3 hours
    @Published var todayUsage: Int = 0     // minutes
    
    private let activityCenter = DeviceActivityCenter()
    private let usageManager = ScreenTimeUsageManager.shared
    private let activityName = DeviceActivityName("unhooked_daily")
    
    // MARK: - Authorization
    
    func requestAuthorization() async {
        print("📱 Requesting Screen Time authorization...")
        
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
            print("✅ Authorization result: \(isAuthorized ? "approved" : "denied")")
        } catch {
            print("❌ Authorization failed: \(error)")
            isAuthorized = false
        }
    }
    
    func checkAuthorizationStatus() {
        isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
    }
    
    func checkAuthorizationStatusWithRetry() async -> Bool {
        // Check multiple times as iOS can be slow to report status
        for attempt in 1...3 {
            checkAuthorizationStatus()
            if isAuthorized { return true }
            print("📱 Auth check attempt \(attempt): \(isAuthorized)")
            try? await Task.sleep(nanoseconds: 500_000_000)
        }
        return isAuthorized
    }
    
    // MARK: - Monitoring Control
    
    /// Start monitoring with selected apps and threshold events
    func startMonitoring(with selection: FamilyActivitySelection) {
        guard isAuthorized else {
            print("⚠️ Cannot start monitoring: not authorized")
            return
        }
        
        guard !selection.applicationTokens.isEmpty else {
            print("⚠️ Cannot start monitoring: no apps selected")
            return
        }
        
        // Stop any existing monitoring first
        stopMonitoring()
        
        // Build threshold events to cover full day usage
        var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]
        
        // 5-minute intervals from 5 to 120 mins (first 2 hours - most critical)
        for mins in stride(from: 5, through: 120, by: 5) {
            let eventName = DeviceActivityEvent.Name("threshold_\(mins)min")
            events[eventName] = DeviceActivityEvent(
                applications: selection.applicationTokens,
                threshold: DateComponents(minute: mins)
            )
        }
        
        // 10-minute intervals from 130 to 300 mins (2-5 hours)
        for mins in stride(from: 130, through: 300, by: 10) {
            let eventName = DeviceActivityEvent.Name("threshold_\(mins)min")
            events[eventName] = DeviceActivityEvent(
                applications: selection.applicationTokens,
                threshold: DateComponents(minute: mins)
            )
        }
        
        // 15-minute intervals from 315 to 480 mins (5-8 hours)
        for mins in stride(from: 315, through: 480, by: 15) {
            let eventName = DeviceActivityEvent.Name("threshold_\(mins)min")
            events[eventName] = DeviceActivityEvent(
                applications: selection.applicationTokens,
                threshold: DateComponents(minute: mins)
            )
        }
        
        print("📱 Setting up \(events.count) threshold events (5-480 mins)")
        
        // Schedule for the entire day in local timezone
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0, second: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59, second: 59),
            repeats: true,
            warningTime: nil
        )
        
        do {
            try activityCenter.startMonitoring(
                activityName,
                during: schedule,
                events: events
            )
            print("✅ Started monitoring with \(events.count) thresholds")
            print("   Apps: \(selection.applicationTokens.count)")
            
            // Load any existing usage data for today
            updateUsageFromStorage()
            
        } catch {
            print("❌ Failed to start monitoring: \(error)")
        }
    }
    
    /// Start monitoring without app selection (legacy - no events)
    func startMonitoring() {
        guard isAuthorized else {
            print("⚠️ Cannot start monitoring: not authorized")
            return
        }
        
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        
        do {
            try activityCenter.startMonitoring(activityName, during: schedule)
            print("✅ Started basic monitoring (no events)")
        } catch {
            print("❌ Failed to start monitoring: \(error)")
        }
    }
    
    func stopMonitoring() {
        activityCenter.stopMonitoring([activityName])
        print("🛑 Stopped monitoring")
    }
    
    // MARK: - Usage Data
    
    /// Update usage from App Group storage
    func updateUsageFromStorage() {
        todayUsage = usageManager.getCurrentMinutes()
        print("📊 Usage from storage: \(todayUsage) mins")
    }
    
    func getTodayUsage() async -> Int {
        updateUsageFromStorage()
        return todayUsage
    }
    
    func setDailyLimit(minutes: Int) {
        dailyLimit = max(30, min(480, minutes))
        print("📱 Daily limit set to \(dailyLimit) minutes")
    }
    
    /// Manual usage entry (for testing/debugging)
    func manuallySetUsage(minutes: Int) {
        usageManager.forceSetUsage(minutes: minutes)
        todayUsage = minutes
        print("🔧 Manually set usage to \(minutes) minutes")
    }
    
    /// Clear usage and reset
    func resetUsage() {
        usageManager.clearUsageData()
        todayUsage = 0
        print("🗑️ Reset usage to 0")
    }
}
