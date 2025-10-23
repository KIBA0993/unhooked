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
    
    // MARK: - Authorization
    
    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
            print("✅ Screen Time authorized: \(isAuthorized)")
        } catch {
            print("❌ Screen Time authorization failed: \(error)")
            isAuthorized = false
        }
    }
    
    func checkAuthorizationStatus() {
        isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
    }
    
    // MARK: - Usage Tracking
    
    func startMonitoring() {
        guard isAuthorized else {
            print("⚠️ Cannot start monitoring: not authorized")
            return
        }
        
        // Set up device activity monitoring
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        
        let activityName = DeviceActivityName("daily_usage")
        
        do {
            try activityCenter.startMonitoring(activityName, during: schedule)
            print("✅ Started monitoring daily usage")
        } catch {
            print("❌ Failed to start monitoring: \(error)")
        }
    }
    
    func stopMonitoring() {
        let activityName = DeviceActivityName("daily_usage")
        activityCenter.stopMonitoring([activityName])
        print("🛑 Stopped monitoring")
    }
    
    // MARK: - Usage Data
    
    func getTodayUsage() async -> Int {
        // In production, this would query the DeviceActivity framework
        // For now, returning simulated data
        
        // Note: Actual implementation would use DeviceActivityReport
        // to get real usage data from Screen Time API
        
        return todayUsage
    }
    
    func setDailyLimit(minutes: Int) {
        dailyLimit = max(30, min(480, minutes))  // Clamp between 30 min - 8 hours
        print("📱 Daily limit set to \(dailyLimit) minutes")
    }
    
    // MARK: - Energy Calculation Trigger
    
    func checkDailyReset(completion: @escaping (Int, Int) -> Void) async {
        let usage = await getTodayUsage()
        completion(usage, dailyLimit)
    }
}

// Note: DeviceActivity extension for monitoring would be implemented in a separate extension target
// This requires DeviceActivityReport capabilities and proper entitlements

