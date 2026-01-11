//
//  AnalyticsService.swift
//  Unhooked
//
//  Analytics event tracking
//

import Foundation
import SwiftData

@MainActor
class AnalyticsService {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Recovery Events
    
    func trackRecoveryViewed(state: HealthState) {
        let event = AnalyticsEvent(
            eventName: "recovery_viewed",
            properties: ["state": state.rawValue]
        )
        saveEvent(event)
    }
    
    func trackRecoveryAttempted(
        action: RecoveryActionType,
        result: String,
        reason: String? = nil
    ) {
        var properties: [String: String] = [
            "action": action.rawValue,
            "result": result
        ]
        if let reason = reason {
            properties["reason"] = reason
        }
        
        let event = AnalyticsEvent(
            eventName: "recovery_attempted",
            properties: properties
        )
        saveEvent(event)
    }
    
    func trackRecoveryCompleted(
        action: RecoveryActionType,
        costGems: Int,
        cooldownNextAt: Date
    ) {
        let event = AnalyticsEvent(
            eventName: "recovery_completed",
            properties: [
                "action": action.rawValue,
                "cost_gems": String(costGems),
                "cooldown_next_at": ISO8601DateFormatter().string(from: cooldownNextAt)
            ]
        )
        saveEvent(event)
    }
    
    // MARK: - Memorial Events
    
    func trackMemorialSaved(hasSnapshot: Bool) {
        let event = AnalyticsEvent(
            eventName: "memorial_saved",
            properties: ["has_snapshot": String(hasSnapshot)]
        )
        saveEvent(event)
    }
    
    // MARK: - Food Events
    
    func trackSpeciesFoodPurchase(
        itemId: String,
        speciesScope: SpeciesScope,
        effectiveSpecies: Species,
        priceEnergy: Int
    ) {
        let event = AnalyticsEvent(
            eventName: "species_food_purchase",
            properties: [
                "item_id": itemId,
                "species_scope": speciesScope.rawValue,
                "effective_species": effectiveSpecies.rawValue,
                "price_energy": String(priceEnergy)
            ]
        )
        saveEvent(event)
    }
    
    // MARK: - IAP Events
    
    func trackIAPValidated(store: String, amountUSD: Double) {
        let event = AnalyticsEvent(
            eventName: "iap_validated",
            properties: [
                "store": store,
                "amount_usd": String(format: "%.2f", amountUSD)
            ]
        )
        saveEvent(event)
    }
    
    func trackRefundProcessed(amountUSD: Double) {
        let event = AnalyticsEvent(
            eventName: "refund_processed",
            properties: [
                "amount_usd": String(format: "%.2f", amountUSD)
            ]
        )
        saveEvent(event)
    }
    
    // MARK: - Health KPIs
    
    func trackDailyHealthSnapshot(
        totalUsers: Int,
        sickCount: Int,
        deadCount: Int,
        date: String
    ) {
        let event = AnalyticsEvent(
            eventName: "daily_health_snapshot",
            properties: [
                "total_users": String(totalUsers),
                "sick_count": String(sickCount),
                "dead_count": String(deadCount),
                "sick_pct": String(format: "%.2f", Double(sickCount) / Double(totalUsers) * 100),
                "dead_pct": String(format: "%.2f", Double(deadCount) / Double(totalUsers) * 100),
                "date": date
            ]
        )
        saveEvent(event)
    }
    
    // MARK: - Custom Events
    
    func track(eventName: String, properties: [String: String] = [:]) {
        let event = AnalyticsEvent(
            eventName: eventName,
            properties: properties
        )
        saveEvent(event)
    }
    
    // MARK: - Persistence
    
    private func saveEvent(_ event: AnalyticsEvent) {
        modelContext.insert(event)
        
        do {
            try modelContext.save()
            print("📊 Analytics: \(event.eventName)")
        } catch {
            print("❌ Failed to save analytics event: \(error)")
        }
    }
    
    // MARK: - Export (for backend sync)
    
    func getUnsentEvents(limit: Int = 100) throws -> [AnalyticsEvent] {
        var descriptor = FetchDescriptor<AnalyticsEvent>(
            predicate: #Predicate { !$0.sent },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        descriptor.fetchLimit = limit
        
        return try modelContext.fetch(descriptor)
    }
    
    func markEventsSent(_ eventIds: [UUID]) throws {
        for id in eventIds {
            let descriptor = FetchDescriptor<AnalyticsEvent>(
                predicate: #Predicate { $0.id == id }
            )
            
            if let event = try modelContext.fetch(descriptor).first {
                event.sent = true
                event.sentAt = Date()
            }
        }
        
        try modelContext.save()
    }
}

// MARK: - Model

@Model
final class AnalyticsEvent {
    @Attribute(.unique) var id: UUID = UUID()
    var eventName: String = ""
    var propertiesData: Data = Data()
    var sent: Bool = false
    var sentAt: Date?
    var createdAt: Date = Date()
    
    init(eventName: String, properties: [String: String] = [:]) {
        self.id = UUID()
        self.eventName = eventName
        self.propertiesData = (try? JSONEncoder().encode(properties)) ?? Data()
        self.createdAt = Date()
    }
    
    var properties: [String: String] {
        (try? JSONDecoder().decode([String: String].self, from: propertiesData)) ?? [:]
    }
}

