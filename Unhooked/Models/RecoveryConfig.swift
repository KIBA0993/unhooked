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
    
    // Fragile state (after revive)
    var fragileDays: Int = 3
    var fragileBuffCap: Double = 0.15
    
    // Feature flag
    var enabled: Bool = true
    
    var updatedAt: Date = Date()
    
    init() {
        // All defaults are set inline
    }
}

@Model
final class RecoveryAction {
    @Attribute(.unique) var id: UUID = UUID()
    var userId: UUID = UUID()
    var petId: UUID = UUID()
    var action: RecoveryActionType = RecoveryActionType.cure
    var gemsSpent: Int = 0
    var timestamp: Date = Date()
    var idempotencyKey: String = ""
    
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

enum RecoveryActionType: String, Codable, Identifiable {
    case cure
    case revive
    case restart
    
    var id: String { rawValue }
}


