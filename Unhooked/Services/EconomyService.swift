//
//  EconomyService.swift
//  Unhooked
//
//  Manages Energy awards, spending, and Gems
//

import Foundation
import SwiftData

@MainActor
class EconomyService {
    private let modelContext: ModelContext
    
    // Energy award parameters (tunable)
    private let maxDailyEnergy = 150
    private let gamma: Double = 1.0  // Exponent for award curve
    private let smoothingWindow = 2  // Days for moving average
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Daily Energy Award
    
    /// Calculate energy award from usage without recording (for preview)
    func calculateEnergyFromUsage(usageMinutes: Int, limitMinutes: Int) -> Int {
        guard limitMinutes > 0 else { return 0 }
        
        let r = Double(usageMinutes) / Double(limitMinutes)
        let rClamped = max(0.0, r)
        
        // Simple calculation without smoothing
        let energyAwarded = Int(round(Double(maxDailyEnergy) * pow(max(0.0, 1.0 - rClamped), gamma)))
        
        return energyAwarded
    }
    
    func calculateDailyEnergy(
        userId: UUID,
        usageMinutes: Int,
        limitMinutes: Int,
        date: String
    ) throws -> Int {
        guard limitMinutes > 0 else { return 0 }
        
        // Calculate raw ratio
        let r = Double(usageMinutes) / Double(limitMinutes)
        let rClamped = max(0.0, r)
        
        // Apply smoothing using previous days
        let rSmooth = try calculateSmoothedRatio(
            userId: userId,
            currentRatio: rClamped,
            date: date
        )
        
        // Award function: E_day = round(150 × max(0, 1 - r)^γ)
        let energyAwarded = Int(round(Double(maxDailyEnergy) * pow(max(0.0, 1.0 - rSmooth), gamma)))
        
        // Record stats
        let stats = DailyStats(
            userId: userId,
            date: date,
            usageMinutes: usageMinutes,
            limitMinutes: limitMinutes,
            rSmooth: rSmooth,
            energyAwarded: energyAwarded
        )
        modelContext.insert(stats)
        
        // Award to wallet
        try awardEnergy(userId: userId, amount: energyAwarded, reason: .dailyAward)
        
        try modelContext.save()
        
        print("💰 Daily Energy: \(energyAwarded) (usage: \(usageMinutes)/\(limitMinutes) min, r: \(String(format: "%.2f", rSmooth)))")
        
        return energyAwarded
    }
    
    private func calculateSmoothedRatio(
        userId: UUID,
        currentRatio: Double,
        date: String
    ) throws -> Double {
        let descriptor = FetchDescriptor<DailyStats>(
            predicate: #Predicate { $0.userId == userId },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        let recentStats = try modelContext.fetch(descriptor).prefix(smoothingWindow - 1)
        let ratios = [currentRatio] + recentStats.map { $0.rSmooth }
        
        return ratios.reduce(0.0, +) / Double(ratios.count)
    }
    
    // MARK: - Wallet Operations
    
    func getWallet(userId: UUID) throws -> Wallet {
        let descriptor = FetchDescriptor<Wallet>(
            predicate: #Predicate { $0.userId == userId }
        )
        
        if let wallet = try modelContext.fetch(descriptor).first {
            return wallet
        }
        
        // Create new wallet
        let wallet = Wallet(userId: userId)
        modelContext.insert(wallet)
        try modelContext.save()
        return wallet
    }
    
    func awardEnergy(userId: UUID, amount: Int, reason: TransactionReason) throws {
        let wallet = try getWallet(userId: userId)
        wallet.energyBalance += amount
        wallet.updatedAt = Date()
        
        let entry = LedgerEntry(
            userId: userId,
            currency: .energy,
            delta: amount,
            balanceAfter: wallet.energyBalance,
            reason: reason
        )
        modelContext.insert(entry)
        try modelContext.save()
    }
    
    func spendEnergy(
        userId: UUID,
        amount: Int,
        reason: TransactionReason,
        relatedItemId: String? = nil,
        idempotencyKey: String? = nil
    ) throws -> Bool {
        let wallet = try getWallet(userId: userId)
        
        guard wallet.energyBalance >= amount else {
            print("❌ Insufficient Energy: have \(wallet.energyBalance), need \(amount)")
            return false
        }
        
        wallet.energyBalance -= amount
        wallet.updatedAt = Date()
        
        let entry = LedgerEntry(
            userId: userId,
            currency: .energy,
            delta: -amount,
            balanceAfter: wallet.energyBalance,
            reason: reason,
            relatedItemId: relatedItemId,
            idempotencyKey: idempotencyKey
        )
        modelContext.insert(entry)
        try modelContext.save()
        
        return true
    }
    
    func awardGems(
        userId: UUID,
        amount: Int,
        reason: TransactionReason,
        idempotencyKey: String? = nil
    ) throws {
        let wallet = try getWallet(userId: userId)
        wallet.gemsBalance += amount
        wallet.updatedAt = Date()
        
        let entry = LedgerEntry(
            userId: userId,
            currency: .gems,
            delta: amount,
            balanceAfter: wallet.gemsBalance,
            reason: reason,
            idempotencyKey: idempotencyKey
        )
        modelContext.insert(entry)
        try modelContext.save()
    }
    
    func spendGems(
        userId: UUID,
        amount: Int,
        reason: TransactionReason,
        relatedItemId: String? = nil,
        idempotencyKey: String? = nil
    ) throws -> Bool {
        let wallet = try getWallet(userId: userId)
        
        guard wallet.gemsBalance >= amount else {
            print("❌ Insufficient Gems: have \(wallet.gemsBalance), need \(amount)")
            return false
        }
        
        wallet.gemsBalance -= amount
        wallet.updatedAt = Date()
        
        let entry = LedgerEntry(
            userId: userId,
            currency: .gems,
            delta: -amount,
            balanceAfter: wallet.gemsBalance,
            reason: reason,
            relatedItemId: relatedItemId,
            idempotencyKey: idempotencyKey
        )
        modelContext.insert(entry)
        try modelContext.save()
        
        return true
    }
    
    // MARK: - Daily Reset
    
    func performDailyReset(for pet: Pet) throws {
        // Apply growth if healthy and had buff yesterday
        if pet.growthEnabled && pet.dailyBuffAccumulated > 0 {
            let growthUnits = calculateGrowthUnits(baseBuff: pet.dailyBuffAccumulated)
            applyGrowth(to: pet, units: growthUnits)
        }
        
        // Reset daily counters
        pet.fedToday = false
        pet.lastFeedAmount = 0
        pet.dailyBuffAccumulated = 0.0
        pet.updatedAt = Date()
        
        try modelContext.save()
    }
    
    private func calculateGrowthUnits(baseBuff: Double) -> Int {
        // Simplified growth calculation
        // In production: base growth tied to under-limit adherence, modified by buff
        return Int(round(baseBuff * 10))  // Example: 0.25 buff = 2-3 growth units
    }
    
    private func applyGrowth(to pet: Pet, units: Int) {
        // Simplified stage progression
        // In production: track XP and stage thresholds
        if units > 0 {
            pet.stage += 1
            print("🌱 Growth! Stage \(pet.stage - 1) → \(pet.stage)")
        }
    }
}


