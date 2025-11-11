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
    var userId: UUID
    var selectedApps: Data  // Encoded FamilyActivitySelection
    var limitMinutes: Int
    var lastChangedAt: Date
    var hasUnlockedUnlimitedChanges: Bool
    
    init(userId: UUID, selectedApps: Data, limitMinutes: Int) {
        self.userId = userId
        self.selectedApps = selectedApps
        self.limitMinutes = limitMinutes
        self.lastChangedAt = Date()
        self.hasUnlockedUnlimitedChanges = false
    }
    
    // Check if user can change limit
    var canChangeLimit: Bool {
        if hasUnlockedUnlimitedChanges {
            return true
        }
        
        let daysSinceLastChange = Calendar.current.dateComponents([.day], from: lastChangedAt, to: Date()).day ?? 0
        return daysSinceLastChange >= 7
    }
    
    var daysUntilNextChange: Int {
        if hasUnlockedUnlimitedChanges {
            return 0
        }
        
        let daysSinceLastChange = Calendar.current.dateComponents([.day], from: lastChangedAt, to: Date()).day ?? 0
        return max(0, 7 - daysSinceLastChange)
    }
}

