//
//  FeatureFlagService.swift
//  Unhooked
//
//  Feature flags and experiments
//

import Foundation
import SwiftData

@MainActor
class FeatureFlagService {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Flag Access
    
    func isEnabled(_ flagKey: String, defaultValue: Bool = false) -> Bool {
        do {
            let descriptor = FetchDescriptor<FeatureFlag>(
                predicate: #Predicate { $0.key == flagKey }
            )
            
            if let flag = try modelContext.fetch(descriptor).first {
                return flag.enabled
            }
            
            return defaultValue
        } catch {
            print("❌ Error fetching flag \(flagKey): \(error)")
            return defaultValue
        }
    }
    
    func getValue(_ flagKey: String, defaultValue: String = "") -> String {
        do {
            let descriptor = FetchDescriptor<FeatureFlag>(
                predicate: #Predicate { $0.key == flagKey }
            )
            
            if let flag = try modelContext.fetch(descriptor).first {
                return flag.value ?? defaultValue
            }
            
            return defaultValue
        } catch {
            print("❌ Error fetching flag \(flagKey): \(error)")
            return defaultValue
        }
    }
    
    // MARK: - Flag Management
    
    func setFlag(
        key: String,
        enabled: Bool,
        value: String? = nil,
        description: String? = nil
    ) throws {
        let descriptor = FetchDescriptor<FeatureFlag>(
            predicate: #Predicate { $0.key == key }
        )
        
        if let existing = try modelContext.fetch(descriptor).first {
            existing.enabled = enabled
            existing.value = value
            if let description = description {
                existing.flagDescription = description
            }
            existing.updatedAt = Date()
        } else {
            let flag = FeatureFlag(
                key: key,
                enabled: enabled,
                value: value,
                description: description
            )
            modelContext.insert(flag)
        }
        
        try modelContext.save()
        print("🚩 Flag updated: \(key) = \(enabled)")
    }
    
    func getAllFlags() throws -> [FeatureFlag] {
        let descriptor = FetchDescriptor<FeatureFlag>(
            sortBy: [SortDescriptor(\.key)]
        )
        
        return try modelContext.fetch(descriptor)
    }
    
    // MARK: - Seed Default Flags
    
    func seedDefaultFlags() throws {
        let defaults: [(String, Bool, String?)] = [
            ("recovery.enabled", true, "Master switch for recovery features"),
            ("recovery.limits_enforced", true, "Enforce recovery limits (MUST be ON in prod)"),
            ("food.species_scoping_enabled", true, "Enable species-specific food filtering"),
            ("ambience.weather_lite", false, "Show weather ambience (default OFF)"),
            ("cosmetics.dual_currency", true, "Allow Energy+Gems for cosmetics"),
            ("memorial.enabled", true, "Enable memorial snapshots"),
            ("analytics.enabled", true, "Enable analytics tracking")
        ]
        
        for (key, enabled, description) in defaults {
            // Only seed if doesn't exist
            let descriptor = FetchDescriptor<FeatureFlag>(
                predicate: #Predicate { $0.key == key }
            )
            
            if try modelContext.fetch(descriptor).isEmpty {
                let flag = FeatureFlag(
                    key: key,
                    enabled: enabled,
                    description: description
                )
                modelContext.insert(flag)
            }
        }
        
        try modelContext.save()
        print("✅ Default feature flags seeded")
    }
}

// MARK: - Model

@Model
final class FeatureFlag {
    @Attribute(.unique) var key: String
    var enabled: Bool
    var value: String?
    var flagDescription: String?
    var createdAt: Date
    var updatedAt: Date
    
    init(
        key: String,
        enabled: Bool,
        value: String? = nil,
        description: String? = nil
    ) {
        self.key = key
        self.enabled = enabled
        self.value = value
        self.flagDescription = description
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}


