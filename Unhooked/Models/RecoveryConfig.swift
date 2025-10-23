//
//  RecoveryConfig.swift
//  Unhooked
//
//  Recovery system configuration (singleton)
//

import Foundation
import SwiftData

@Model
final class RecoveryConfig {
    @Attribute(.unique) var id: String = "singleton"
    
    // Costs (Gems)
    var cureSickGems: Int = 120
    var reviveDeadGems: Int = 400
    var restartGems: Int = 200
    
    // Cooldowns (hours)
    var cureCooldownHours: Int = 24
    var reviveCooldownHours: Int = 168  // 7 days
    var restartCooldownHours: Int = 24
    
    // Limits
    var cureMaxPer30Days: Int = 5
    var reviveMaxPer90Days: Int = 2
    
    // Fragile state
    var fragileDays: Int = 3
    var fragileBuffCap: Double = 0.15
    
    // Feature flags
    var enabled: Bool = true
    var limitsEnforced: Bool = true
    
    var updatedAt: Date
    
    init() {
        self.updatedAt = Date()
    }
}

@Model
final class RecoveryAction {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var petId: UUID
    var action: RecoveryActionType
    var gemsSpent: Int
    var timestamp: Date
    var idempotencyKey: String
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        petId: UUID,
        action: RecoveryActionType,
        gemsSpent: Int,
        idempotencyKey: String
    ) {
        self.id = id
        self.userId = userId
        self.petId = petId
        self.action = action
        self.gemsSpent = gemsSpent
        self.idempotencyKey = idempotencyKey
        self.timestamp = Date()
    }
}

enum RecoveryActionType: String, Codable {
    case cure
    case revive
    case restart
}


