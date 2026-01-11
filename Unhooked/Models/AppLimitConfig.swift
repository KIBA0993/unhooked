//
//  AppLimitConfig.swift
//  Unhooked
//
//  App limit configuration and cooldown tracking
//

import Foundation
import SwiftData
import FamilyControls

@Model
final class AppLimitConfig {
    @Attribute(.unique) var id: UUID = UUID()
    var userId: UUID = UUID()
    var selectedApps: Data = Data()  // Encoded FamilyActivitySelection
    var limitMinutes: Int = 60
    var lastChangedAt: Date = Date()
    var earlyChangeUnlocked: Bool = false  // Single early change unlocked (resets after use)
    var changeCount: Int = 0  // Track how many times limit has been changed
    
    // Gem cost for one early change
    static let earlyChangeCost = 50
    
    init(userId: UUID, selectedApps: Data, limitMinutes: Int) {
        self.userId = userId
        self.selectedApps = selectedApps
        self.limitMinutes = limitMinutes
        self.lastChangedAt = Date()
        self.earlyChangeUnlocked = false
        self.changeCount = 0
    }
    
    // Check if this is the first time setting limit
    var isFirstTimeSetup: Bool {
        changeCount == 0
    }
    
    // Check if user can change limit
    var canChangeLimit: Bool {
        // First time is always free
        if isFirstTimeSetup {
            return true
        }
        
        // Single early change unlocked (paid for)
        if earlyChangeUnlocked {
            return true
        }
        
        // 7 calendar days have passed
        let daysSinceLastChange = Calendar.current.dateComponents([.day], from: lastChangedAt, to: Date()).day ?? 0
        return daysSinceLastChange >= 7
    }
    
    var daysUntilNextChange: Int {
        if earlyChangeUnlocked || isFirstTimeSetup {
            return 0
        }
        
        let daysSinceLastChange = Calendar.current.dateComponents([.day], from: lastChangedAt, to: Date()).day ?? 0
        return max(0, 7 - daysSinceLastChange)
    }
    
    /// Record that a change was made (consumes early unlock if active)
    func recordChange() {
        changeCount += 1
        lastChangedAt = Date()
        // Consume single-use unlock if it was active
        if earlyChangeUnlocked {
            earlyChangeUnlocked = false
        }
    }
}

