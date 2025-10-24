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
    
    // Widget preferences (using UserDefaults for service layer)
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
        
        // Create shared data for widgets
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
        
        // Save to App Group for widget access
        saveWidgetData(widgetData)
        
        // Trigger widget reload
        WidgetCenter.shared.reloadAllTimelines()
        
        print("🔄 Widgets updated")
    }
    
    private func saveWidgetData(_ data: PetWidgetData) {
        guard let appGroup = UserDefaults(suiteName: "group.com.kiba.unhooked.shared") else {
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
        guard dynamicIslandEnabled else { return }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("⚠️ Live Activities not enabled")
            return
        }
        
        // Stop any existing activity
        stopLiveActivity()
        
        let attributes = PetActivityAttributes(userId: pet.userId)
        let initialState = PetActivityAttributes.ContentState(
            petSpecies: pet.species.rawValue,
            petStage: pet.stage,
            healthState: pet.healthState.rawValue,
            fullness: Int(pet.fullness),
            energyBalance: energyBalance,
            isFragile: pet.isFragile
        )
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
            
            print("✨ Live Activity started: \(activity.id)")
        } catch {
            print("❌ Failed to start Live Activity: \(error)")
        }
    }
    
    @available(iOS 16.2, *)
    func updateLiveActivity(pet: Pet, energyBalance: Int) {
        guard dynamicIslandEnabled else { return }
        
        let updatedState = PetActivityAttributes.ContentState(
            petSpecies: pet.species.rawValue,
            petStage: pet.stage,
            healthState: pet.healthState.rawValue,
            fullness: Int(pet.fullness),
            energyBalance: energyBalance,
            isFragile: pet.isFragile
        )
        
        Task {
            for activity in Activity<PetActivityAttributes>.activities {
                await activity.update(
                    .init(state: updatedState, staleDate: nil)
                )
            }
        }
        
        print("🔄 Live Activity updated")
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

// MARK: - Live Activity

@available(iOS 16.2, *)
struct PetActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        let petSpecies: String
        let petStage: Int
        let healthState: String
        let fullness: Int
        let energyBalance: Int
        let isFragile: Bool
    }
    
    let userId: UUID
}

