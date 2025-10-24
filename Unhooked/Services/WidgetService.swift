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
        let attributes = PetActivityAttributes(userId: pet.userId)
        let initialState = PetActivityAttributes.ContentState(
            petSpecies: pet.species.rawValue,
            petStage: pet.stage,
            healthState: pet.healthState.rawValue,
            fullness: Int(pet.fullness),
            energyBalance: energyBalance,
            isFragile: pet.isFragile
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
            print("  - Details: \(error)")
            
            if let activityError = error as? ActivityKitError {
                print("  - Activity Error Type: \(activityError)")
            }
            
            print("\n🔍 Possible reasons:")
            print("  1. Not on iPhone 14 Pro or later (Dynamic Island required)")
            print("  2. Live Activities disabled in iOS Settings > Unhooked")
            print("  3. PetLiveActivity not properly registered in widget extension")
            print(String(repeating: "=", count: 60) + "\n")
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

