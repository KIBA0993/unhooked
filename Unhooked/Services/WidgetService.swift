//
//  WidgetService.swift
//  Unhooked
//
//  Manages widget and Live Activity updates
//

import Foundation
import SwiftUI
import SwiftData
import ActivityKit
import WidgetKit

@MainActor
class WidgetService {
    private let modelContext: ModelContext
    
    private var widgetEnabled: Bool {
        UserDefaults.standard.bool(forKey: "widget.enabled")
    }
    
    private var dynamicIslandEnabled: Bool {
        UserDefaults.standard.bool(forKey: "dynamicIsland.enabled")
    }
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Widget Updates
    
    func updateWidgets(pet: Pet, energyBalance: Int, gemsBalance: Int) {
        guard widgetEnabled else { return }
        
        let widgetData = PetWidgetData(
            petSpecies: pet.species,
            petStage: pet.stage,
            healthState: pet.healthState,
            fullness: Int(pet.fullness),
            mood: pet.mood,
            energyBalance: energyBalance,
            gemsBalance: gemsBalance,
            isFragile: pet.isFragile,
            lastUpdate: Date()
        )
        
        saveWidgetData(widgetData)
        WidgetCenter.shared.reloadAllTimelines()
        print("🔄 Widgets updated")
    }
    
    private func saveWidgetData(_ data: PetWidgetData) {
        guard let appGroup = UserDefaults(suiteName: "group.com.kookytrove.unhooked") else {
            print("⚠️ Failed to access App Group")
            return
        }
        
        if let encoded = try? JSONEncoder().encode(data) {
            appGroup.set(encoded, forKey: "petWidgetData")
            appGroup.synchronize()
        }
    }
    
    // MARK: - Dynamic Island (Live Activity)
    
    @available(iOS 16.2, *)
    func startLiveActivity(pet: Pet, energyBalance: Int) {
        print("🔵 Starting Live Activity...")
        
        guard dynamicIslandEnabled else { 
            print("❌ Dynamic Island toggle is OFF")
            return 
        }
        
        let authInfo = ActivityAuthorizationInfo()
        guard authInfo.areActivitiesEnabled else {
            print("❌ Live Activities not authorized")
            return
        }
        
        // Stop existing activities
        for activity in Activity<PetActivityAttributes>.activities {
            Task { await activity.end(nil, dismissalPolicy: .immediate) }
        }
        
        // Create new activity
        let attributes = PetActivityAttributes(userId: pet.userId, petId: pet.id)
        let initialState = createContentState(pet: pet, energyBalance: energyBalance)
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
            print("🎉 Live Activity created: \(activity.id)")
        } catch {
            print("❌ Failed to create Live Activity: \(error)")
        }
    }
    
    @available(iOS 16.2, *)
    func updateLiveActivity(pet: Pet, energyBalance: Int, isSleeping: Bool = false) {
        guard dynamicIslandEnabled else { return }
        
        let updatedState = createContentState(pet: pet, energyBalance: energyBalance, isSleeping: isSleeping)
        
        Task {
            for activity in Activity<PetActivityAttributes>.activities {
                await activity.update(.init(state: updatedState, staleDate: nil))
            }
        }
        print("🔄 Live Activity updated")
    }
    
    @available(iOS 16.2, *)
    private func createContentState(pet: Pet, energyBalance: Int, isSleeping: Bool = false) -> PetActivityAttributes.ContentState {
        let hungerLevel = Int(pet.fullness)
        let happinessLevel = pet.mood * 10
        let energyLevel = pet.healthState == .dead ? 0 : (pet.healthState == .sick ? 30 : 80)
        let needsAttention = hungerLevel < 50 || happinessLevel < 50
        let isCritical = hungerLevel < 20 || pet.healthState == .sick || pet.healthState == .dead
        
        return PetActivityAttributes.ContentState(
            petSpecies: pet.species.rawValue,
            petStage: pet.stage,
            petName: pet.name.isEmpty ? pet.species.rawValue.capitalized : pet.name,
            healthState: pet.healthState.rawValue,
            hunger: hungerLevel,
            happiness: happinessLevel,
            energy: energyLevel,
            energyBalance: energyBalance,
            isFragile: pet.isFragile,
            isSleeping: isSleeping,
            needsAttention: needsAttention,
            isCritical: isCritical
        )
    }
    
    @available(iOS 16.2, *)
    func stopLiveActivity() {
        Task {
            for activity in Activity<PetActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }
}

// MARK: - Widget Data Model

struct PetWidgetData: Codable {
    let petSpecies: Species
    let petStage: Int
    let healthState: HealthState
    let fullness: Int
    let mood: Int
    let energyBalance: Int
    let gemsBalance: Int
    let isFragile: Bool
    let lastUpdate: Date
}

// MARK: - Live Activity Attributes

@available(iOS 16.2, *)
struct PetActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Pet info
        let petSpecies: String
        let petStage: Int
        let petName: String
        let healthState: String
        
        // Status bars (0-100)
        let hunger: Int
        let happiness: Int
        let energy: Int
        
        // Economy
        let energyBalance: Int
        
        // Flags
        let isFragile: Bool
        let isSleeping: Bool
        let needsAttention: Bool
        let isCritical: Bool
        
        var statusColor: String {
            if isCritical { return "red" }
            if needsAttention { return "yellow" }
            if isSleeping { return "blue" }
            return "green"
        }
    }
    
    let userId: UUID
    let petId: UUID
}
