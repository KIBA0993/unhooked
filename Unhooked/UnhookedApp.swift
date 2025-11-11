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
        
        // Try CloudKit sync first, fall back to local-only if unavailable
        let modelConfiguration: ModelConfiguration
        
        // Check if CloudKit is available (user signed into iCloud)
        if FileManager.default.ubiquityIdentityToken != nil {
            // iCloud available - enable CloudKit sync
            modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .private("iCloud.com.unhooked.app")
            )
            print("☁️ iCloud sync enabled")
        } else {
            // iCloud not available - use local storage only
            modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            print("📱 Local storage only (iCloud not available)")
        }

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            if let viewModel = viewModel {
                MainTabView()
                    .environment(viewModel)
            } else {
                ProgressView()
                    .onAppear {
                        viewModel = AppViewModel(modelContext: sharedModelContainer.mainContext)
                    }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
