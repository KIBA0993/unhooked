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
            
            // Load wallet
            wallet = try economyService.getWallet(userId: userId)
            updateBalances()
            
            // Load IAP products
            await iapService.loadProducts()
            
            // Start transaction observer
            iapService.startTransactionObserver(userId: userId)
            
            print("✅ App initialized")
        } catch {
            print("❌ Initialization error: \(error)")
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
                
                // Play animation if available
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
    
    func performRecovery() async {
        guard let pet = currentPet,
              let action = recoveryAction else { return }
        
        do {
            let idempotencyKey = UUID().uuidString
            
            switch action {
            case .cure:
                let result = try recoveryService.cure(
                    userId: userId,
                    pet: pet,
                    idempotencyKey: idempotencyKey
                )
                
                handleRecoveryResult(result, action: .cure)
                
            case .revive:
                let result = try recoveryService.revive(
                    userId: userId,
                    pet: pet,
                    idempotencyKey: idempotencyKey
                )
                
                handleRecoveryResult(result, action: .revive)
                
            case .restart:
                // Would show species selection first
                let restartResult = try recoveryService.restart(
                    userId: userId,
                    oldPet: pet,
                    newSpecies: .cat,  // Default, would be user choice
                    idempotencyKey: idempotencyKey
                )
                
                switch restartResult {
                case .success(let newPet, let message):
                    currentPet = newPet
                    updateBalances()
                    showRecoveryModal = false
                    print("✅ \(message)")
                    
                case .failure(let error):
                    handleRecoveryError(error)
                }
            }
        } catch {
            print("❌ Recovery error: \(error)")
        }
    }
    
    private func handleRecoveryResult(_ result: RecoveryResult, action: RecoveryActionType) {
        switch result {
        case .success(_, let message, _):
            updateBalances()
            showRecoveryModal = false
            print("✅ \(message)")
            
            analyticsService.trackRecoveryCompleted(
                action: action,
                costGems: 0,  // Would get from config
                cooldownNextAt: Date().addingTimeInterval(86400)
            )
            
        case .failure(let error):
            handleRecoveryError(error)
        }
    }
    
    private func handleRecoveryError(_ error: RecoveryError) {
        switch error {
        case .cooldownActive(let nextAvailable):
            print("⏰ Cooldown active until \(nextAvailable)")
        case .limitReached:
            print("🚫 Limit reached")
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

