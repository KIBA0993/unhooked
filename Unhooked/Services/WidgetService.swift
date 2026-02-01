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
        print("\n" + String(repeating: "=", count: 60))
        print("🔵 ATTEMPTING TO START LIVE ACTIVITY")
        print(String(repeating: "=", count: 60))
        
        // Check 1: Toggle enabled?
        print("\n📱 Check 1: App Settings")
        print("  - dynamicIslandEnabled: \(dynamicIslandEnabled)")
        
        guard dynamicIslandEnabled else { 
            print("❌ FAILED: Dynamic Island toggle is OFF in app settings")
            print("   Solution: Turn on the toggle in Settings > Widgets & Live Activity")
            print(String(repeating: "=", count: 60) + "\n")
            return 
        }
        print("  ✅ Toggle is ON")
        
        // Check 2: iOS permissions
        print("\n🔐 Check 2: iOS Permissions")
        let authInfo = ActivityAuthorizationInfo()
        print("  - areActivitiesEnabled: \(authInfo.areActivitiesEnabled)")
        
        guard authInfo.areActivitiesEnabled else {
            print("❌ FAILED: Live Activities not authorized in iOS Settings")
            print("   Solution: Open iOS Settings app > Unhooked > Enable 'Live Activities'")
            print(String(repeating: "=", count: 60) + "\n")
            return
        }
        print("  ✅ iOS permissions granted")
        
        // Check 3: Device capability
        print("\n📲 Check 3: Device Capability")
        print("  - Device: \(UIDevice.current.model)")
        print("  - System: \(UIDevice.current.systemVersion)")
        
        // Check 4: Stop existing activities
        print("\n🔄 Check 4: Cleaning up existing activities")
        let existingActivities = Activity<PetActivityAttributes>.activities
        print("  - Found \(existingActivities.count) existing activities")
        for activity in existingActivities {
            print("    - Ending activity: \(activity.id)")
            Task {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
        
        // Check 5: Create new activity
        print("\n✨ Check 5: Creating new Live Activity")
        let attributes = PetActivityAttributes(userId: pet.userId, petId: pet.id)
        
        // Calculate status levels
        let hungerLevel = Int(pet.fullness)
        let happinessLevel = pet.mood * 10  // mood is 1-10, convert to 0-100
        let energyLevel = pet.healthState == .dead ? 0 : (pet.healthState == .sick ? 30 : 80)
        let needsAttention = hungerLevel < 50 || happinessLevel < 50
        let isCritical = hungerLevel < 20 || pet.healthState == .sick || pet.healthState == .dead
        
        let initialState = PetActivityAttributes.ContentState(
            petSpecies: pet.species.rawValue,
            petStage: pet.stage,
            petName: pet.name.isEmpty ? pet.species.rawValue.capitalized : pet.name,
            healthState: pet.healthState.rawValue,
            hunger: hungerLevel,
            happiness: happinessLevel,
            energy: energyLevel,
            energyBalance: energyBalance,
            isFragile: pet.isFragile,
            isSleeping: false,
            needsAttention: needsAttention,
            isCritical: isCritical,
            currentAnimation: ""
        )
        
        print("  - Pet: \(pet.species.rawValue) (Stage \(pet.stage))")
        print("  - Health: \(pet.healthState.rawValue)")
        print("  - Energy: \(energyBalance)")
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
            
            print("\n🎉 SUCCESS! Live Activity created!")
            print("  - Activity ID: \(activity.id)")
            print("  - State: \(activity.activityState)")
            print("  - Content: \(activity.content)")
            print("\n💡 Look at the top of your screen near the status bar!")
            print("   You should see: \(pet.species == .cat ? "🐱" : "🐶")")
            print(String(repeating: "=", count: 60) + "\n")
        } catch {
            print("\n❌ FAILED TO CREATE LIVE ACTIVITY")
            print("  - Error: \(error.localizedDescription)")
            print("  - Full Error: \(error)")
            print("  - Error Type: \(type(of: error))")
            
            print("\n🔍 Possible reasons:")
            print("  1. Not on iPhone 14 Pro or later (Dynamic Island required)")
            print("  2. Live Activities disabled in iOS Settings > Unhooked")
            print("  3. PetLiveActivity not properly registered in widget extension")
            print("  4. Simulator may need restart")
            print(String(repeating: "=", count: 60) + "\n")
        }
    }
    
    @available(iOS 16.2, *)
    func updateLiveActivity(pet: Pet, energyBalance: Int, isSleeping: Bool = false, animation: String = "") {
        guard dynamicIslandEnabled else { return }
        
        // Calculate status levels
        let hungerLevel = Int(pet.fullness)
        let happinessLevel = pet.mood * 10
        let energyLevel = pet.healthState == .dead ? 0 : (pet.healthState == .sick ? 30 : 80)
        let needsAttention = hungerLevel < 50 || happinessLevel < 50
        let isCritical = hungerLevel < 20 || pet.healthState == .sick || pet.healthState == .dead
        
        var updatedState = PetActivityAttributes.ContentState(
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
            isCritical: isCritical,
            currentAnimation: animation
        )
        
        Task {
            for activity in Activity<PetActivityAttributes>.activities {
                await activity.update(
                    .init(state: updatedState, staleDate: nil)
                )
            }
        }
        
        print("🔄 Live Activity updated with animation: \(animation)")
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
        // Pet info
        let petSpecies: String
        let petStage: Int
        let petName: String
        let healthState: String
        
        // Status bars (0-100)
        let hunger: Int      // Fullness/hunger level
        let happiness: Int   // Mood level (mapped to 0-100)
        let energy: Int      // Pet energy/tiredness
        
        // Economy
        let energyBalance: Int  // Currency
        
        // Flags
        let isFragile: Bool
        let isSleeping: Bool
        let needsAttention: Bool  // Yellow status
        let isCritical: Bool      // Red status
        
        // Animation state (empty = idle, "eating", "playing", "petting")
        var currentAnimation: String = ""
        
        // Status color helper
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

