//
//  DailyStats.swift
//  Unhooked
//
//  Tracks daily usage and energy awards
//

import Foundation
import SwiftData

@Model
final class DailyStats {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var date: String  // yyyy-MM-dd format
    var usageMinutes: Int
    var limitMinutes: Int
    var rSmooth: Double  // Smoothed ratio r
    var energyAwarded: Int
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        date: String,
        usageMinutes: Int,
        limitMinutes: Int,
        rSmooth: Double,
        energyAwarded: Int
    ) {
        self.id = id
        self.userId = userId
        self.date = date
        self.usageMinutes = usageMinutes
        self.limitMinutes = limitMinutes
        self.rSmooth = rSmooth
        self.energyAwarded = energyAwarded
        self.createdAt = Date()
    }
    
    var ratio: Double {
        guard limitMinutes > 0 else { return 1.0 }
        return Double(usageMinutes) / Double(limitMinutes)
    }
}


