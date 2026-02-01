//
//  UnhookedApp.swift
//  Unhooked
//
//  Created by Simon Chen on 10/16/25.
//

import SwiftUI
import SwiftData

@main
struct UnhookedApp: App {
    @State private var viewModel: AppViewModel?
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            // Core models
            Pet.self,
            DailyStats.self,
            Wallet.self,
            LedgerEntry.self,
            
            // Food & Cosmetics
            FoodCatalogItem.self,
            CosmeticItem.self,
            OwnedCosmetic.self,
            
            // Recovery & Health
            RecoveryConfig.self,
            RecoveryAction.self,
            
            // Memorial
            Memorial.self,
            MemorialConfig.self,
            
            // IAP
            IAPurchase.self,
            
            // Analytics & Flags
            AnalyticsEvent.self,
            FeatureFlag.self,
            
            // App Limit
            AppLimitConfig.self
        ])
        
        // Use local storage only (CloudKit disabled for now)
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        print("📱 Local storage only")

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            print("❌ Failed to create ModelContainer: \(error)")
            print("🔄 Attempting to recover by deleting corrupted database...")
            
            // Try to delete the corrupted database files
            let fileManager = FileManager.default
            if let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                let defaultStore = appSupport.appendingPathComponent("default.store")
                let defaultStoreShm = appSupport.appendingPathComponent("default.store-shm")
                let defaultStoreWal = appSupport.appendingPathComponent("default.store-wal")
                
                for url in [defaultStore, defaultStoreShm, defaultStoreWal] {
                    try? fileManager.removeItem(at: url)
                    print("🗑️ Deleted: \(url.lastPathComponent)")
                }
            }
            
            // Retry with fresh database
            do {
                print("🔄 Retrying ModelContainer creation...")
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                print("❌ Recovery failed, using in-memory storage: \(error)")
                // Last resort: use in-memory storage
                let inMemoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                do {
                    return try ModelContainer(for: schema, configurations: [inMemoryConfig])
                } catch {
                    fatalError("Could not create ModelContainer even in-memory: \(error)")
                }
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            if let viewModel = viewModel {
                MainTabView()
                    .environment(viewModel)
                    .onOpenURL { url in
                        handleDeepLink(url: url, viewModel: viewModel)
                    }
            } else {
                ProgressView()
                    .onAppear {
                        viewModel = AppViewModel(modelContext: sharedModelContainer.mainContext)
                    }
            }
        }
        .modelContainer(sharedModelContainer)
    }
    
    // MARK: - Deep Link Handling for Dynamic Island Actions
    
    private func handleDeepLink(url: URL, viewModel: AppViewModel) {
        print("🔗 Deep link received: \(url)")
        
        guard url.scheme == "unhooked" else { return }
        
        // Handle action URLs: unhooked://action/feed, unhooked://action/play, etc.
        if url.host == "action", let action = url.pathComponents.last {
            Task { @MainActor in
                await handleDynamicIslandAction(action: action, viewModel: viewModel)
            }
        }
    }
    
    @MainActor
    private func handleDynamicIslandAction(action: String, viewModel: AppViewModel) async {
        print("🎮 Dynamic Island action: \(action)")
        
        guard let pet = viewModel.currentPet else { return }
        
        // Update the Live Activity to show animation
        if #available(iOS 16.2, *) {
            viewModel.widgetService.updateLiveActivity(
                pet: pet,
                energyBalance: viewModel.energyBalance,
                animation: action == "feed" ? "eating" : (action == "play" ? "playing" : (action == "pet" ? "petting" : ""))
            )
        }
        
        // Perform the actual action
        switch action {
        case "feed":
            // Quick feed with default food
            viewModel.triggerAnimation(.eating)
            
        case "play":
            viewModel.triggerAnimation(.trick)
            
        case "pet":
            viewModel.triggerAnimation(.pet)
            
        default:
            break
        }
        
        // Clear the animation after 2 seconds
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        if #available(iOS 16.2, *) {
            viewModel.widgetService.updateLiveActivity(
                pet: pet,
                energyBalance: viewModel.energyBalance,
                animation: ""
            )
        }
    }
}
