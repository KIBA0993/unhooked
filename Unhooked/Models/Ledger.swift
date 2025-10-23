//
//  Ledger.swift
//  Unhooked
//
//  Immutable append-only ledger for currency transactions
//

import Foundation
import SwiftData

@Model
final class LedgerEntry {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var currency: Currency
    var delta: Int  // Positive for gains, negative for spending
    var balanceAfter: Int
    var reason: TransactionReason
    var relatedItemId: String?  // Food item, cosmetic, etc.
    var idempotencyKey: String?
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        currency: Currency,
        delta: Int,
        balanceAfter: Int,
        reason: TransactionReason,
        relatedItemId: String? = nil,
        idempotencyKey: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.currency = currency
        self.delta = delta
        self.balanceAfter = balanceAfter
        self.reason = reason
        self.relatedItemId = relatedItemId
        self.idempotencyKey = idempotencyKey
        self.createdAt = Date()
    }
}

@Model
final class Wallet {
    @Attribute(.unique) var userId: UUID
    var energyBalance: Int = 0
    var gemsBalance: Int = 0
    var updatedAt: Date
    
    init(userId: UUID) {
        self.userId = userId
        self.updatedAt = Date()
    }
}

enum Currency: String, Codable {
    case energy = "E"
    case gems = "Gems"
}

enum TransactionReason: String, Codable {
    case dailyAward = "daily_award"
    case food = "food"
    case cosmetic = "cosmetic"
    case cure = "cure"
    case revive = "revive"
    case restart = "restart"
    case iapPurchase = "iap_purchase"
    case refund = "refund"
    case adjustment = "adjustment"
    case debug = "debug"
}


