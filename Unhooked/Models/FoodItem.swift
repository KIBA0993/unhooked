//
//  FoodItem.swift
//  Unhooked
//
//  Food catalog with species-specific support
//

import Foundation
import SwiftData

@Model
final class FoodCatalogItem {
    @Attribute(.unique) var itemId: String
    var title: String
    var priceEnergy: Int  // 25-150
    var speciesScope: SpeciesScope
    
    // Default stats
    var defaultFullnessDelta: Int  // 10-60%
    var defaultMoodDelta: Int  // 1-3
    var defaultBuffFrac: Double  // 0.00-0.15
    
    // Species-specific overrides (stored as JSON)
    var speciesOverridesData: Data?
    
    // Seasonal
    var seasonalStartUTC: Date?
    var seasonalEndUTC: Date?
    
    var isEnabled: Bool = true
    var createdAt: Date
    var updatedAt: Date
    
    init(
        itemId: String,
        title: String,
        priceEnergy: Int,
        speciesScope: SpeciesScope,
        defaultFullnessDelta: Int,
        defaultMoodDelta: Int,
        defaultBuffFrac: Double
    ) {
        self.itemId = itemId
        self.title = title
        self.priceEnergy = priceEnergy
        self.speciesScope = speciesScope
        self.defaultFullnessDelta = defaultFullnessDelta
        self.defaultMoodDelta = defaultMoodDelta
        self.defaultBuffFrac = defaultBuffFrac
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // MARK: - Species Override Logic
    
    var speciesOverrides: [Species: FoodOverride] {
        get {
            guard let data = speciesOverridesData else { return [:] }
            return (try? JSONDecoder().decode([Species: FoodOverride].self, from: data)) ?? [:]
        }
        set {
            speciesOverridesData = try? JSONEncoder().encode(newValue)
        }
    }
    
    func effectiveStats(for species: Species) -> (fullness: Int, mood: Int, buff: Double, animationId: String?) {
        if let override = speciesOverrides[species] {
            return (
                fullness: override.fullnessDelta ?? defaultFullnessDelta,
                mood: override.moodDelta ?? defaultMoodDelta,
                buff: override.buffFrac ?? defaultBuffFrac,
                animationId: override.feedAnimationId
            )
        }
        return (defaultFullnessDelta, defaultMoodDelta, defaultBuffFrac, nil)
    }
    
    func isAvailable(for species: Species, at date: Date = Date()) -> Bool {
        guard isEnabled else { return false }
        
        // Check species scope
        switch speciesScope {
        case .cat where species != .cat:
            return false
        case .dog where species != .dog:
            return false
        case .both, .cat, .dog:
            break
        }
        
        // Check seasonal window
        if let start = seasonalStartUTC, let end = seasonalEndUTC {
            return date >= start && date <= end
        }
        
        return true
    }
}

// MARK: - Supporting Types

enum SpeciesScope: String, Codable {
    case cat
    case dog
    case both
}

struct FoodOverride: Codable {
    var fullnessDelta: Int?
    var moodDelta: Int?
    var buffFrac: Double?
    var feedAnimationId: String?
}


