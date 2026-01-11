//
//  AppViewModel.swift
//  Unhooked
//
//  Main app coordinator
//

import Foundation
import SwiftUI
import SwiftData
import StoreKit

@MainActor
@Observable
class AppViewModel {
    // Services
    let modelContext: ModelContext  // Public for app limit config
    private let healthService: HealthService
    let economyService: EconomyService  // Public for app limit IAP
    private let foodService: FoodService
    private let recoveryService: RecoveryService
    private let cosmeticsService: CosmeticsService
    let iapService: IAPService  // Public for view access
    private let analyticsService: AnalyticsService
    private let featureFlagService: FeatureFlagService
    let widgetService: WidgetService  // Public for manual widget refresh
    let screenTimeService: ScreenTimeService  // Public for usage tracking
    
    // Persistent user identifier (syncs across devices via iCloud)
    let userId: UUID = {  // Public for app limit config
        let key = "com.unhooked.persistentUserId"
        
        // Use NSUbiquitousKeyValueStore for iCloud sync
        let iCloudStore = NSUbiquitousKeyValueStore.default
        
        // Try to load existing UUID from iCloud first
        if let stored = iCloudStore.string(forKey: key),
           let uuid = UUID(uuidString: stored) {
            // Also save to UserDefaults as backup
            UserDefaults.standard.set(stored, forKey: key)
            return uuid
        }
        
        // Fall back to UserDefaults if iCloud not available
        if let stored = UserDefaults.standard.string(forKey: key),
           let uuid = UUID(uuidString: stored) {
            // Save to iCloud for future sync
            iCloudStore.set(stored, forKey: key)
            iCloudStore.synchronize()
            return uuid
        }
        
        // Create new UUID and persist to both stores
        let newId = UUID()
        let idString = newId.uuidString
        
        iCloudStore.set(idString, forKey: key)
        iCloudStore.synchronize()
        UserDefaults.standard.set(idString, forKey: key)
        
        print("🆔 Created persistent userId: \(newId)")
        return newId
    }()
    
    // State
    var currentPet: Pet?
    var wallet: Wallet?
    var energyBalance: Int = 0
    var gemsBalance: Int = 0
    
    // UI State
    var showFoodShop = false
    var showCosmeticsShop = false
    var showRecoveryModal = false
    var recoveryAction: RecoveryActionType?
    var currentAnimation: PetAnimation = .idle
    var trickVariant: Int = 0
    
    // UI Refresh trigger - increment to force view updates
    var refreshTrigger: Int = 0
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        
        // Initialize services
        self.healthService = HealthService(modelContext: modelContext)
        self.economyService = EconomyService(modelContext: modelContext)
        self.foodService = FoodService(
            modelContext: modelContext,
            economyService: economyService
        )
        self.recoveryService = RecoveryService(
            modelContext: modelContext,
            economyService: economyService,
            healthService: healthService
        )
        self.cosmeticsService = CosmeticsService(
            modelContext: modelContext,
            economyService: economyService
        )
        self.iapService = IAPService(
            modelContext: modelContext,
            economyService: economyService
        )
        self.analyticsService = AnalyticsService(modelContext: modelContext)
        self.featureFlagService = FeatureFlagService(modelContext: modelContext)
        self.widgetService = WidgetService(modelContext: modelContext)
        self.screenTimeService = ScreenTimeService()
        
        Task {
            await initialize()
        }
    }
    
    // MARK: - Initialization
    
    func initialize() async {
        do {
            // Seed defaults
            try featureFlagService.seedDefaultFlags()
            try foodService.seedCatalog()
            
            // Load or create pet
            currentPet = try loadOrCreatePet()
            
            // Sync app limit from config to pet
            try syncAppLimitToPet()
            
            // Load wallet
            wallet = try economyService.getWallet(userId: userId)
            updateBalances()
            
            // Load IAP products
            await iapService.loadProducts()
            
            // Start transaction observer
            iapService.startTransactionObserver(userId: userId)
            
            // Start Live Activity (Dynamic Island)
            if let pet = currentPet, #available(iOS 16.2, *) {
                widgetService.startLiveActivity(pet: pet, energyBalance: energyBalance)
            }
            
            // Check for daily reset immediately on app launch
            await checkAndPerformDailyReset()
            
            // Start periodic Screen Time usage updates (every 5 minutes)
            startPeriodicUsageSync()
            
            print("✅ App initialized")
        } catch {
            print("❌ Initialization error: \(error)")
        }
    }
    
    private func startPeriodicUsageSync() {
        // Update usage every 5 minutes AND check for daily reset
        Task {
            while !Task.isCancelled {
                // Check if day has changed (daily reset at midnight)
                await checkAndPerformDailyReset()
                
                // Update current usage
                await updateUsageFromScreenTime()
                
                try? await Task.sleep(nanoseconds: 300_000_000_000) // 5 minutes
            }
        }
    }
    
    private func checkAndPerformDailyReset() async {
        guard let pet = currentPet else { return }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Check if lastResetDate is nil or from a previous day
        if pet.lastResetDate == nil || !calendar.isDate(pet.lastResetDate!, inSameDayAs: today) {
            print("🌅 New day detected! Performing daily reset...")
            print("   Last reset: \(pet.lastResetDate?.description ?? "never")")
            print("   Today: \(today)")
            
            // Get yesterday's usage data for the energy award
            let usageMinutes = pet.currentUsage
            let limitMinutes = pet.currentLimit > 0 ? pet.currentLimit : 120 // Default 2h if not set
            
            print("   Yesterday's usage: \(usageMinutes)/\(limitMinutes) minutes")
            
            // Perform the daily reset which awards energy based on yesterday's performance
            await performDailyReset(usageMinutes: usageMinutes, limitMinutes: limitMinutes)
            
            // Update lastResetDate to today
            pet.lastResetDate = today
            pet.currentUsage = 0 // Reset usage counter for new day
            
            try? modelContext.save()
            
            print("✅ Daily reset complete! Energy awarded based on yesterday's usage")
        }
    }
    
    private func loadOrCreatePet() throws -> Pet {
        let descriptor = FetchDescriptor<Pet>(
            predicate: #Predicate { $0.userId == userId },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        if let pet = try modelContext.fetch(descriptor).first {
            return pet
        }
        
        // Create first pet
        let pet = Pet(userId: userId, species: .cat)
        modelContext.insert(pet)
        try modelContext.save()
        
        print("🐱 Created first pet!")
        return pet
    }
    
    private func syncAppLimitToPet() throws {
        guard let pet = currentPet else { return }
        
        // Load app limit config
        let descriptor = FetchDescriptor<AppLimitConfig>(
            predicate: #Predicate { $0.userId == userId }
        )
        
        if let config = try modelContext.fetch(descriptor).first {
            // Sync limit from config to pet
            pet.currentLimit = config.limitMinutes
            try modelContext.save()
            print("✅ Synced app limit to pet: \(config.limitMinutes) minutes")
        } else {
            print("ℹ️ No app limit config found")
        }
    }
    
    func refreshPet() async {
        do {
            let descriptor = FetchDescriptor<Pet>(
                predicate: #Predicate { $0.userId == userId },
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            
            if let pet = try modelContext.fetch(descriptor).first {
                await MainActor.run {
                    currentPet = pet
                    print("🔄 Pet refreshed - currentLimit: \(pet.currentLimit)")
                }
                
                // Also update usage from Screen Time
                await updateUsageFromScreenTime()
            }
        } catch {
            print("❌ Failed to refresh pet: \(error)")
        }
    }
    
    /// Synchronously refresh the current pet from database (for use after recovery)
    func refreshCurrentPet() {
        do {
            let descriptor = FetchDescriptor<Pet>(
                predicate: #Predicate { $0.userId == userId },
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            
            if let pet = try modelContext.fetch(descriptor).first {
                let oldHealthState = currentPet?.healthState
                
                // The pet object is the same (SwiftData identity), 
                // so we need to force a view refresh by incrementing trigger
                refreshTrigger += 1
                
                // Also reassign to ensure currentPet is up to date
                currentPet = pet
                
                print("🔄 Pet refreshed - health: \(oldHealthState?.rawValue ?? "nil") → \(pet.healthState.rawValue)")
                print("   refreshTrigger: \(refreshTrigger)")
            }
        } catch {
            print("❌ Failed to refresh pet: \(error)")
        }
    }
    
    /// Update the pet's current usage from Screen Time shared data
    func updateUsageFromScreenTime() async {
        print("🔄 updateUsageFromScreenTime() called")
        guard let pet = currentPet else {
            print("❌ No current pet found")
            return
        }
        
        let usageManager = ScreenTimeUsageManager.shared
        print("📱 Attempting to load usage data from App Group...")
        
        if let usage = usageManager.loadUsage() {
            print("✅ Loaded usage data: \(usage.totalMinutes) minutes, date: \(usage.dateString)")
            if usage.isToday {
                let oldUsage = pet.currentUsage
                pet.currentUsage = usage.totalMinutes
                try? modelContext.save()
                print("📊 Updated pet usage: \(oldUsage) → \(usage.totalMinutes) minutes")
                
                // Force UI update by reassigning currentPet
                // This triggers @Observable to notify views
                await MainActor.run {
                    let tempPet = currentPet
                    currentPet = nil
                    currentPet = tempPet
                    print("🔄 Forced view refresh")
                }
            } else {
                print("⚠️ Usage data is from previous day, not updating")
            }
        } else {
            print("❌ No usage data found in App Group")
        }
    }
    
    private func updateBalances() {
        energyBalance = wallet?.energyBalance ?? 0
        gemsBalance = wallet?.gemsBalance ?? 0
        
        // Update widgets
        if let pet = currentPet {
            widgetService.updateWidgets(
                pet: pet,
                energyBalance: energyBalance,
                gemsBalance: gemsBalance
            )
            
            // Update Live Activity (Dynamic Island)
            if #available(iOS 16.2, *) {
                widgetService.updateLiveActivity(pet: pet, energyBalance: energyBalance)
            }
        }
    }
    
    // MARK: - Daily Reset
    
    func performDailyReset(usageMinutes: Int, limitMinutes: Int) async {
        guard let pet = currentPet else { return }
        
        do {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let today = dateFormatter.string(from: Date())
            
            // Calculate and award energy
            let energy = try economyService.calculateDailyEnergy(
                userId: userId,
                usageMinutes: usageMinutes,
                limitMinutes: limitMinutes,
                date: today
            )
            
            // Perform health check
            try healthService.performDailyHealthCheck(for: pet)
            
            // Economy reset
            try economyService.performDailyReset(for: pet)
            
            updateBalances()
            
            print("🌅 Daily reset complete! Awarded \(energy) Energy")
        } catch {
            print("❌ Daily reset error: \(error)")
        }
    }
    
    // MARK: - Usage Tracking
    
    func updateUsage(usageMinutes: Int, limitMinutes: Int) {
        guard let pet = currentPet else { return }
        
        pet.currentUsage = usageMinutes
        pet.currentLimit = limitMinutes
        
        // Calculate and store energy award (will be applied at daily reset)
        let energyAwarded = economyService.calculateEnergyFromUsage(
            usageMinutes: usageMinutes,
            limitMinutes: limitMinutes
        )
        pet.lastEnergyAward = energyAwarded
        
        do {
            try modelContext.save()
            print("📊 Usage updated: \(usageMinutes)/\(limitMinutes) min → \(energyAwarded) Energy")
        } catch {
            print("❌ Failed to update usage: \(error)")
        }
    }
    
    /// Reset the usage display to 0 (for debugging/clearing stale data)
    func resetUsageDisplay() {
        guard let pet = currentPet else { return }
        
        pet.currentUsage = 0
        screenTimeService.todayUsage = 0
        
        do {
            try modelContext.save()
            print("🗑️ Usage display reset to 0")
        } catch {
            print("❌ Failed to reset usage: \(error)")
        }
    }
    
    // MARK: - Pet Actions
    
    func feedPet(foodItemId: String) async {
        guard let pet = currentPet else { return }
        
        do {
            let result = try foodService.purchaseFood(
                userId: userId,
                pet: pet,
                itemId: foodItemId,
                idempotencyKey: UUID().uuidString
            )
            
            switch result {
            case .success(let fullnessDelta, _, _, let animationId):
                updateBalances()
                print("✅ Fed pet: +\(fullnessDelta)% fullness")
                
                // Trigger eating animation
                await MainActor.run {
                    triggerAnimation(.eating)
                }
                
                // Play food-specific animation if available
                if let animId = animationId {
                    print("🎬 Play animation: \(animId)")
                }
                
            case .failure(let error):
                handleError(error)
            }
        } catch {
            print("❌ Feed error: \(error)")
        }
    }
    
    func triggerAnimation(_ animation: PetAnimation, variant: Int? = nil) {
        currentAnimation = animation
        if let v = variant {
            trickVariant = v
        }
        
        // Reset to idle after animation duration
        let duration: Double = {
            switch animation {
            case .idle: return 0
            case .trick: return 1.2
            case .pet: return 0.6
            case .nap: return 4.5
            case .eating: return 1.2
            }
        }()
        
        if duration > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                self.currentAnimation = .idle
            }
        }
    }
    
    func updateMood(delta: Int) {
        guard let pet = currentPet else { return }
        
        pet.mood = max(0, min(10, pet.mood + delta))
        
        do {
            try modelContext.save()
        } catch {
            print("❌ Failed to update mood: \(error)")
        }
    }
    
    // MARK: - Recovery Actions
    
    func showRecoveryOptions(for action: RecoveryActionType) {
        recoveryAction = action
        showRecoveryModal = true
        analyticsService.trackRecoveryViewed(state: currentPet?.healthState ?? .healthy)
    }
    
    /// Returns true if recovery was successful
    func performRecovery() async -> Bool {
        print("🔄 performRecovery() called")
        print("   currentPet: \(currentPet != nil ? "exists" : "nil")")
        print("   currentPet.healthState: \(currentPet?.healthState.rawValue ?? "nil")")
        print("   recoveryAction: \(String(describing: recoveryAction))")
        print("   gemsBalance: \(gemsBalance)")
        
        guard let pet = currentPet,
              let action = recoveryAction else {
            print("❌ Guard failed - pet: \(currentPet != nil), action: \(recoveryAction != nil)")
            return false
        }
        
        print("✅ Guard passed - pet exists, action: \(action)")
        
        do {
            let idempotencyKey = UUID().uuidString
            print("🔑 Idempotency key: \(idempotencyKey)")
            print("🔄 Calling recoveryService.\(action)...")
            
            switch action {
            case .cure:
                let result = try recoveryService.cure(
                    userId: userId,
                    pet: pet,
                    idempotencyKey: idempotencyKey
                )
                print("📋 Cure result: \(result)")
                return handleRecoveryResult(result, action: .cure)
                
            case .revive:
                let result = try recoveryService.revive(
                    userId: userId,
                    pet: pet,
                    idempotencyKey: idempotencyKey
                )
                print("📋 Revive result: \(result)")
                return handleRecoveryResult(result, action: .revive)
                
            case .restart:
                let restartResult = try recoveryService.restart(
                    userId: userId,
                    oldPet: pet,
                    newSpecies: pet.species,
                    idempotencyKey: idempotencyKey
                )
                print("📋 Restart result: \(restartResult)")
                
                switch restartResult {
                case .success(let newPet, let message):
                    currentPet = newPet
                    refreshTrigger += 1
                    updateBalances()
                    showRecoveryModal = false
                    recoveryAction = nil
                    print("✅ \(message) - New pet created!")
                    return true
                    
                case .failure(let error):
                    handleRecoveryError(error)
                    return false
                }
            }
        } catch {
            print("❌ Recovery EXCEPTION: \(error)")
            return false
        }
    }
    
    @discardableResult
    private func handleRecoveryResult(_ result: RecoveryResult, action: RecoveryActionType) -> Bool {
        switch result {
        case .success(let newState, let message, _):
            print("✅ Recovery SUCCESS: \(message)")
            print("   New health state: \(newState)")
            
            // Force refresh the pet from database to get updated state
            refreshCurrentPet()
            
            if let pet = currentPet {
                print("   Pet after refresh - health: \(pet.healthState), fragile: \(pet.isFragile)")
            }
            
            updateBalances()
            showRecoveryModal = false
            recoveryAction = nil
            
            analyticsService.trackRecoveryCompleted(
                action: action,
                costGems: 0,
                cooldownNextAt: Date().addingTimeInterval(86400)
            )
            return true
            
        case .failure(let error):
            print("❌ Recovery FAILED: \(error)")
            handleRecoveryError(error)
            return false
        }
    }
    
    private func handleRecoveryError(_ error: RecoveryError) {
        switch error {
        case .insufficientGems:
            print("💎 Not enough Gems")
        case .invalidState:
            print("❌ Invalid state for this action")
        case .featureDisabled:
            print("🚫 Feature disabled")
        }
        
        analyticsService.trackRecoveryAttempted(
            action: recoveryAction ?? .cure,
            result: "failure",
            reason: String(describing: error)
        )
    }
    
    // MARK: - IAP
    
    func purchaseGems(productId: String) async {
        guard let product = iapService.gemProducts.first(where: { $0.id == productId }) else {
            return
        }
        
        do {
            let result = try await iapService.purchase(
                userId: userId,
                product: product,
                idempotencyKey: UUID().uuidString
            )
            
            switch result {
            case .success(let gems):
                updateBalances()
                print("✅ Purchased \(gems) Gems!")
                
            case .failure(let error):
                print("❌ Purchase failed: \(error)")
            }
        } catch {
            print("❌ IAP error: \(error)")
        }
    }
    
    // MARK: - Helpers
    
    private func handleError(_ error: Error) {
        print("❌ Error: \(error)")
    }
    
    var petVisualEffects: HealthVisualEffects? {
        guard let pet = currentPet else { return nil }
        return healthService.getVisualEffects(for: pet)
    }
    
    // MARK: - Debug Functions
    
    #if DEBUG
    func debugAddGems(_ amount: Int) {
        do {
            try economyService.awardGems(
                userId: userId,
                amount: amount,
                reason: .debug,
                idempotencyKey: UUID().uuidString
            )
            updateBalances()
            print("🐛 DEBUG: Added \(amount) Gems")
        } catch {
            print("❌ Debug add gems error: \(error)")
        }
    }
    
    func debugSetUnfedDays(_ days: Int) {
        guard let pet = currentPet else { return }
        
        pet.consecutiveUnfedDays = days
        
        // Update health state based on days
        if days >= 4 {
            pet.healthState = .dead
            pet.deadAt = Date()
        } else if days >= 2 {
            pet.healthState = .sick
            pet.deadAt = nil
        } else {
            pet.healthState = .healthy
            pet.deadAt = nil
        }
        
        do {
            try modelContext.save()
            print("🐛 DEBUG: Set unfed days to \(days)")
        } catch {
            print("❌ Debug set unfed days error: \(error)")
        }
    }
    
    func debugSetGrowthProgress(_ progress: Int) {
        guard let pet = currentPet else { return }
        
        pet.growthProgress = progress
        
        do {
            try modelContext.save()
            print("🐛 DEBUG: Set growth progress to \(progress)")
        } catch {
            print("❌ Debug set growth error: \(error)")
        }
    }
    
    func debugResetGame() {
        print("🔄 DEBUG: Resetting game...")
        
        // Delete current pet
        if let pet = currentPet {
            print("   Deleting current pet")
            modelContext.delete(pet)
        }
        
        // Reset wallet
        do {
            let wallet = try economyService.getWallet(userId: userId)
            wallet.energyBalance = 50
            wallet.gemsBalance = 0
            
            // DON'T create new pet - let user choose species
            try modelContext.save()
            
            // Set current pet to nil - this will trigger species selection
            currentPet = nil
            updateBalances()
            
            print("✅ DEBUG: Game reset! User will choose new pet.")
        } catch {
            print("❌ Debug reset error: \(error)")
        }
    }
    
    // MARK: - Pet Creation
    
    func createNewPet(species: Species, name: String) {
        print("🐾 Creating new \(species.rawValue) named '\(name)'...")
        
        let newPet = Pet(userId: userId, species: species)
        newPet.name = name
        modelContext.insert(newPet)
        
        do {
            try modelContext.save()
            currentPet = newPet
            updateBalances()
            
            // Start Live Activity for new pet
            if #available(iOS 16.2, *) {
                widgetService.startLiveActivity(pet: newPet, energyBalance: energyBalance)
            }
            
            print("✅ New \(species.rawValue) '\(name)' created!")
        } catch {
            print("❌ Failed to create pet: \(error)")
        }
    }
    
    func debugSetTestState(_ state: String) {
        guard let pet = currentPet else { return }
        
        switch state {
        case "healthy":
            pet.healthState = .healthy
            pet.consecutiveUnfedDays = 0
            pet.deadAt = nil
            pet.fragileUntil = nil
            pet.fullness = 80
            pet.mood = 5
            pet.growthProgress = 20
            do {
                try economyService.awardGems(userId: userId, amount: 50, reason: .debug, idempotencyKey: UUID().uuidString)
                try economyService.awardEnergy(userId: userId, amount: 100, reason: .debug)
            } catch {}
            
        case "sick":
            pet.healthState = .sick
            pet.consecutiveUnfedDays = 2
            pet.deadAt = nil
            pet.fullness = 20
            pet.mood = 2
            pet.growthProgress = 50
            do {
                try economyService.awardGems(userId: userId, amount: 150, reason: .debug, idempotencyKey: UUID().uuidString)
                try economyService.awardEnergy(userId: userId, amount: 150, reason: .debug)
            } catch {}
            
        case "dead":
            pet.healthState = .dead
            pet.consecutiveUnfedDays = 4
            pet.deadAt = Date()
            pet.fullness = 0
            pet.mood = 0
            pet.growthProgress = 75
            do {
                try economyService.awardGems(userId: userId, amount: 500, reason: .debug, idempotencyKey: UUID().uuidString)
            } catch {}
            
        case "advanced":
            pet.healthState = .healthy
            pet.consecutiveUnfedDays = 0
            pet.deadAt = nil
            pet.fragileUntil = nil
            pet.fullness = 90
            pet.mood = 8
            pet.growthProgress = 350
            do {
                try economyService.awardGems(userId: userId, amount: 200, reason: .debug, idempotencyKey: UUID().uuidString)
                try economyService.awardEnergy(userId: userId, amount: 200, reason: .debug)
            } catch {}
            
        default:
            break
        }
        
        do {
            try modelContext.save()
            updateBalances()
            print("🐛 DEBUG: Set test state to \(state)")
        } catch {
            print("❌ Debug set test state error: \(error)")
        }
    }
    #endif
}

