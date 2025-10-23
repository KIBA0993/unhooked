//
//  Pet.swift
//  Unhooked
//
//  Core pet model with health state machine
//

import Foundation
import SwiftData

@Model
final class Pet {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var species: Species
    var stage: Int
    var healthState: HealthState
    var consecutiveUnfedDays: Int
    var fragileUntil: Date?
    var deadAt: Date?
    var createdAt: Date
    var updatedAt: Date
    
    // Stats
    var fullness: Double = 100.0  // 0-100%
    var mood: Int = 5  // 1-10 scale
    
    // Growth & Evolution
    var growthProgress: Int = 0  // Progress towards next evolution stage
    
    // Daily tracking
    var fedToday: Bool = false
    var lastFeedAmount: Int = 0
    var dailyBuffAccumulated: Double = 0.0
    var todayFoodSpend: Int = 0  // Total energy spent on food today
    var lastEnergyAward: Int = 0  // Last daily energy award amount
    
    // Usage tracking
    var currentUsage: Int = 0  // Minutes of screen time today
    var currentLimit: Int = 0  // Daily limit in minutes
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        species: Species,
        stage: Int = 0,
        healthState: HealthState = .healthy,
        consecutiveUnfedDays: Int = 0
    ) {
        self.id = id
        self.userId = userId
        self.species = species
        self.stage = stage
        self.healthState = healthState
        self.consecutiveUnfedDays = consecutiveUnfedDays
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // MARK: - Health State Checks
    
    var isSick: Bool { healthState == .sick }
    var isDead: Bool { healthState == .dead }
    var isHealthy: Bool { healthState == .healthy }
    var isFragile: Bool {
        guard let fragileUntil = fragileUntil else { return false }
        return Date() < fragileUntil
    }
    
    // MARK: - Buff Caps
    
    var dailyBuffCap: Double {
        switch healthState {
        case .healthy:
            return isFragile ? 0.15 : 0.25
        case .sick:
            return 0.10
        case .dead:
            return 0.0
        }
    }
    
    // MARK: - Action Availability
    
    var canFeed: Bool {
        healthState != .dead
    }
    
    var canTrick: Bool {
        healthState == .healthy
    }
    
    var canPet: Bool {
        true  // Always available, but behavior changes by state
    }
    
    var canGroom: Bool {
        healthState != .dead
    }
    
    var canNap: Bool {
        healthState != .dead
    }
    
    var growthEnabled: Bool {
        healthState == .healthy
    }
}

// MARK: - Enums

enum Species: String, Codable {
    case cat
    case dog
}

enum HealthState: String, Codable {
    case healthy
    case sick
    case dead
}


