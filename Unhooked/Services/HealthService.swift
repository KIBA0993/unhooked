//
//  HealthService.swift
//  Unhooked
//
//  Manages health state transitions and checks
//

import Foundation
import SwiftData

@MainActor
class HealthService {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Health Checks at Daily Reset
    
    func performDailyHealthCheck(for pet: Pet) throws {
        let previousState = pet.healthState
        
        // Check if fed yesterday
        if !pet.fedToday {
            pet.consecutiveUnfedDays += 1
        } else {
            // Natural recovery check for Sick pets
            if pet.healthState == .sick {
                try checkNaturalRecovery(for: pet)
            }
            pet.consecutiveUnfedDays = 0
        }
        
        // State transitions based on consecutive unfed days
        if pet.consecutiveUnfedDays >= 7 {
            try transitionToDead(pet)
        } else if pet.consecutiveUnfedDays >= 3 && pet.healthState == .healthy {
            try transitionToSick(pet)
        }
        
        // Reset daily flags
        pet.fedToday = false
        pet.lastFeedAmount = 0
        pet.dailyBuffAccumulated = 0.0
        pet.updatedAt = Date()
        
        try modelContext.save()
        
        // Log state change if it occurred
        if previousState != pet.healthState {
            print("🏥 Health state changed: \(previousState) → \(pet.healthState)")
        }
    }
    
    // MARK: - Natural Recovery
    
    private func checkNaturalRecovery(for pet: Pet) throws {
        // For natural recovery from Sick:
        // Need 2 fed_today days in a rolling 3-day window
        // For now, simplified: if fed 2 days in a row, recover
        
        let descriptor = FetchDescriptor<DailyStats>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        let allStats = try modelContext.fetch(descriptor)
        let recentStats = allStats.filter { $0.userId == pet.userId }.prefix(3)
        
        // Count fed days (those with energy spent on food >= 100)
        // This is a simplification - in production we'd track fed_today explicitly
        let fedDaysInWindow = recentStats.filter { $0.energyAwarded > 0 }.count
        
        if fedDaysInWindow >= 2 {
            try transitionToHealthy(pet)
        }
    }
    
    // MARK: - State Transitions
    
    func transitionToSick(_ pet: Pet) throws {
        pet.healthState = .sick
        pet.updatedAt = Date()
        try modelContext.save()
        
        // Analytics
        logHealthTransition(pet: pet, to: .sick, reason: "consecutive_unfed")
    }
    
    func transitionToDead(_ pet: Pet) throws {
        pet.healthState = .dead
        pet.deadAt = Date()
        pet.updatedAt = Date()
        try modelContext.save()
        
        // Analytics
        logHealthTransition(pet: pet, to: .dead, reason: "consecutive_unfed")
    }
    
    func transitionToHealthy(_ pet: Pet, fragile: Bool = false, fragileDays: Int = 0) throws {
        pet.healthState = .healthy
        pet.consecutiveUnfedDays = 0
        
        if fragile && fragileDays > 0 {
            pet.fragileUntil = Calendar.current.date(byAdding: .day, value: fragileDays, to: Date())
        } else {
            pet.fragileUntil = nil
        }
        
        pet.updatedAt = Date()
        try modelContext.save()
        
        // Analytics
        logHealthTransition(pet: pet, to: .healthy, reason: fragile ? "revive_fragile" : "natural_recovery")
    }
    
    // MARK: - Visual Effects
    
    func getVisualEffects(for pet: Pet) -> HealthVisualEffects {
        switch pet.healthState {
        case .healthy:
            return HealthVisualEffects(
                idleAnimation: pet.isFragile ? "idle_cautious" : "idle_normal",
                overlayEffect: nil,
                soundEffect: nil
            )
        case .sick:
            return HealthVisualEffects(
                idleAnimation: "idle_low_energy",
                overlayEffect: .desaturate(amount: 0.1),
                soundEffect: "cough_sneeze_loop"
            )
        case .dead:
            return HealthVisualEffects(
                idleAnimation: "ghost_float",
                overlayEffect: .grayscale,
                soundEffect: nil
            )
        }
    }
    
    // MARK: - Analytics
    
    private func logHealthTransition(pet: Pet, to state: HealthState, reason: String) {
        // TODO: Implement analytics event
        print("📊 health_transition: \(state.rawValue), reason: \(reason)")
    }
}

// MARK: - Supporting Types

struct HealthVisualEffects {
    let idleAnimation: String
    let overlayEffect: OverlayEffect?
    let soundEffect: String?
    
    enum OverlayEffect {
        case desaturate(amount: Double)
        case grayscale
    }
}

