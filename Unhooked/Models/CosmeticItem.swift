//
//  CosmeticItem.swift
//  Unhooked
//
//  Cosmetics with dual currency pricing
//

import Foundation
import SwiftData

@Model
final class CosmeticItem {
    @Attribute(.unique) var itemId: String = ""
    var title: String = ""
    var category: CosmeticCategory = CosmeticCategory.accessory
    var priceEnergy: Int?  // nil if not available for Energy
    var priceGems: Int?     // nil if not available for Gems
    var imageAssetName: String = ""
    var isEnabled: Bool = true
    var seasonalStartUTC: Date?
    var seasonalEndUTC: Date?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    init(
        itemId: String,
        title: String,
        category: CosmeticCategory,
        priceEnergy: Int? = nil,
        priceGems: Int? = nil,
        imageAssetName: String
    ) {
        self.itemId = itemId
        self.title = title
        self.category = category
        self.priceEnergy = priceEnergy
        self.priceGems = priceGems
        self.imageAssetName = imageAssetName
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var isAvailable: Bool {
        guard isEnabled else { return false }
        
        if let start = seasonalStartUTC, let end = seasonalEndUTC {
            let now = Date()
            return now >= start && now <= end
        }
        
        return true
    }
}

@Model
final class OwnedCosmetic {
    @Attribute(.unique) var id: UUID = UUID()
    var userId: UUID = UUID()
    var itemId: String = ""
    var purchasedWithCurrency: Currency = Currency.energy
    var purchaseDate: Date = Date()
    
    init(userId: UUID, itemId: String, purchasedWithCurrency: Currency) {
        self.id = UUID()
        self.userId = userId
        self.itemId = itemId
        self.purchasedWithCurrency = purchasedWithCurrency
        self.purchaseDate = Date()
    }
}

enum CosmeticCategory: String, Codable {
    case outfit
    case roomDecor
    case palette
    case accessory
}


