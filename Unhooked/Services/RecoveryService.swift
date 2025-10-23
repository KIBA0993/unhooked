//
//  RecoveryService.swift
//  Unhooked
//
//  Handles Cure/Revive/Restart with cooldowns and limits
//

import Foundation
import SwiftData

@MainActor
class RecoveryService {
    private let modelContext: ModelContext
    private let economyService: EconomyService
    private let healthService: HealthService
    
    init(
        modelContext: ModelContext,
        economyService: EconomyService,
        healthService: HealthService
    ) {
        self.modelContext = modelContext
        self.economyService = economyService
        self.healthService = healthService
    }
    
    // MARK: - Configuration
    
    func getConfig() throws -> RecoveryConfig {
        let descriptor = FetchDescriptor<RecoveryConfig>()
        
        if let config = try modelContext.fetch(descriptor).first {
            return config
        }
        
        // Create default config
        let config = RecoveryConfig()
        modelContext.insert(config)
        try modelContext.save()
        return config
    }
    
    // MARK: - Cure (Sick → Healthy)
    
    func cure(
        userId: UUID,
        pet: Pet,
        idempotencyKey: String
    ) throws -> RecoveryResult {
        let config = try getConfig()
        
        // Check if enabled
        guard config.enabled else {
            return .failure(.featureDisabled)
        }
        
        // Check state
        guard pet.healthState == .sick else {
            return .failure(.invalidState)
        }
        
        // Check cooldown
        if let violation = try checkCooldown(
            userId: userId,
            action: .cure,
            cooldownHours: config.cureCooldownHours
        ) {
            return .failure(.cooldownActive(nextAvailable: violation))
        }
        
        // Check limits
        if config.limitsEnforced {
            if try isLimitReached(
                userId: userId,
                action: .cure,
                maxCount: config.cureMaxPer30Days,
                windowDays: 30
            ) {
                return .failure(.limitReached)
            }
        }
        
        // Check gems
        let wallet = try economyService.getWallet(userId: userId)
        guard wallet.gemsBalance >= config.cureSickGems else {
            return .failure(.insufficientGems)
        }
        
        // Spend gems
        let success = try economyService.spendGems(
            userId: userId,
            amount: config.cureSickGems,
            reason: .cure,
            idempotencyKey: idempotencyKey
        )
        
        guard success else {
            return .failure(.insufficientGems)
        }
        
        // Apply cure
        try healthService.transitionToHealthy(pet, fragile: false)
        
        // Record action
        let action = RecoveryAction(
            userId: userId,
            petId: pet.id,
            action: .cure,
            gemsSpent: config.cureSickGems,
            idempotencyKey: idempotencyKey
        )
        modelContext.insert(action)
        try modelContext.save()
        
        print("💊 Cure successful! Pet is now healthy.")
        
        return .success(
            newState: .healthy,
            message: "All better. Take it easy today.",
            fragileUntil: nil
        )
    }
    
    // MARK: - Revive (Dead → Healthy with Fragile)
    
    func revive(
        userId: UUID,
        pet: Pet,
        idempotencyKey: String
    ) throws -> RecoveryResult {
        let config = try getConfig()
        
        guard config.enabled else {
            return .failure(.featureDisabled)
        }
        
        guard pet.healthState == .dead else {
            return .failure(.invalidState)
        }
        
        // Check cooldown
        if let violation = try checkCooldown(
            userId: userId,
            action: .revive,
            cooldownHours: config.reviveCooldownHours
        ) {
            return .failure(.cooldownActive(nextAvailable: violation))
        }
        
        // Check limits
        if config.limitsEnforced {
            if try isLimitReached(
                userId: userId,
                action: .revive,
                maxCount: config.reviveMaxPer90Days,
                windowDays: 90
            ) {
                return .failure(.limitReached)
            }
        }
        
        // Check gems
        let wallet = try economyService.getWallet(userId: userId)
        guard wallet.gemsBalance >= config.reviveDeadGems else {
            return .failure(.insufficientGems)
        }
        
        // Spend gems
        let success = try economyService.spendGems(
            userId: userId,
            amount: config.reviveDeadGems,
            reason: .revive,
            idempotencyKey: idempotencyKey
        )
        
        guard success else {
            return .failure(.insufficientGems)
        }
        
        // Apply revive with fragile state
        try healthService.transitionToHealthy(
            pet,
            fragile: true,
            fragileDays: config.fragileDays
        )
        
        // Record action
        let action = RecoveryAction(
            userId: userId,
            petId: pet.id,
            action: .revive,
            gemsSpent: config.reviveDeadGems,
            idempotencyKey: idempotencyKey
        )
        modelContext.insert(action)
        try modelContext.save()
        
        print("✨ Revive successful! Pet is fragile for \(config.fragileDays) days.")
        
        return .success(
            newState: .healthy,
            message: "Back with us. Be gentle for a few days.",
            fragileUntil: pet.fragileUntil
        )
    }
    
    // MARK: - Restart (New Pet)
    
    func restart(
        userId: UUID,
        oldPet: Pet,
        newSpecies: Species,
        idempotencyKey: String
    ) throws -> RestartResult {
        let config = try getConfig()
        
        guard config.enabled else {
            return .failure(.featureDisabled)
        }
        
        guard oldPet.healthState == .sick || oldPet.healthState == .dead else {
            return .failure(.invalidState)
        }
        
        // Check cooldown
        if let violation = try checkCooldown(
            userId: userId,
            action: .restart,
            cooldownHours: config.restartCooldownHours
        ) {
            return .failure(.cooldownActive(nextAvailable: violation))
        }
        
        // Check gems
        let wallet = try economyService.getWallet(userId: userId)
        guard wallet.gemsBalance >= config.restartGems else {
            return .failure(.insufficientGems)
        }
        
        // Spend gems
        let success = try economyService.spendGems(
            userId: userId,
            amount: config.restartGems,
            reason: .restart,
            idempotencyKey: idempotencyKey
        )
        
        guard success else {
            return .failure(.insufficientGems)
        }
        
        // Create memorial if dead
        if oldPet.healthState == .dead {
            try createMemorial(for: oldPet)
        }
        
        // Create new pet
        let newPet = Pet(
            userId: userId,
            species: newSpecies,
            stage: 0,
            healthState: .healthy
        )
        modelContext.insert(newPet)
        
        // Preserve cosmetics (query OwnedCosmetics for userId - they remain)
        
        // Record action
        let action = RecoveryAction(
            userId: userId,
            petId: oldPet.id,
            action: .restart,
            gemsSpent: config.restartGems,
            idempotencyKey: idempotencyKey
        )
        modelContext.insert(action)
        
        // Delete old pet
        modelContext.delete(oldPet)
        
        try modelContext.save()
        
        print("🔄 Restart successful! New \(newSpecies.rawValue) created.")
        
        return .success(newPet: newPet, message: "A fresh start begins now.")
    }
    
    // MARK: - Cooldown & Limit Checks
    
    private func checkCooldown(
        userId: UUID,
        action: RecoveryActionType,
        cooldownHours: Int
    ) throws -> Date? {
        let descriptor = FetchDescriptor<RecoveryAction>(
            predicate: #Predicate { $0.userId == userId && $0.action == action },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        guard let lastAction = try modelContext.fetch(descriptor).first else {
            return nil  // No previous action
        }
        
        let cooldownEnd = Calendar.current.date(
            byAdding: .hour,
            value: cooldownHours,
            to: lastAction.timestamp
        )!
        
        if Date() < cooldownEnd {
            return cooldownEnd
        }
        
        return nil
    }
    
    private func isLimitReached(
        userId: UUID,
        action: RecoveryActionType,
        maxCount: Int,
        windowDays: Int
    ) throws -> Bool {
        let windowStart = Calendar.current.date(
            byAdding: .day,
            value: -windowDays,
            to: Date()
        )!
        
        let descriptor = FetchDescriptor<RecoveryAction>(
            predicate: #Predicate { 
                $0.userId == userId && 
                $0.action == action && 
                $0.timestamp >= windowStart
            }
        )
        
        let count = try modelContext.fetchCount(descriptor)
        return count >= maxCount
    }
    
    // MARK: - Memorial
    
    private func createMemorial(for pet: Pet) throws {
        let memorialConfig = try getMemorialConfig()
        guard memorialConfig.enabled else { return }
        
        // Check max snapshots
        let descriptor = FetchDescriptor<Memorial>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        let allMemorials = try modelContext.fetch(descriptor)
        let existing = allMemorials.filter { $0.userId == pet.userId }
        
        if existing.count >= memorialConfig.maxSnapshotsPerUser {
            // Delete oldest
            if let oldest = existing.last {
                modelContext.delete(oldest)
            }
        }
        
        let memorial = Memorial(
            userId: pet.userId,
            petSpecies: pet.species,
            petStage: pet.stage,
            deathDate: pet.deadAt ?? Date()
        )
        modelContext.insert(memorial)
    }
    
    private func getMemorialConfig() throws -> MemorialConfig {
        let descriptor = FetchDescriptor<MemorialConfig>()
        
        if let config = try modelContext.fetch(descriptor).first {
            return config
        }
        
        let config = MemorialConfig()
        modelContext.insert(config)
        try modelContext.save()
        return config
    }
}

// MARK: - Result Types

enum RecoveryResult {
    case success(newState: HealthState, message: String, fragileUntil: Date?)
    case failure(RecoveryError)
}

enum RestartResult {
    case success(newPet: Pet, message: String)
    case failure(RecoveryError)
}

enum RecoveryError: Error {
    case featureDisabled
    case invalidState
    case cooldownActive(nextAvailable: Date)
    case limitReached
    case insufficientGems
}

