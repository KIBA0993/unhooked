//
//  HomeView.swift
//  Unhooked
//
//  Main home screen with pet - Exact Figma layout
//

import SwiftUI
import SwiftData
import FamilyControls
import DeviceActivity

struct HomeView: View {
    @Environment(AppViewModel.self) private var viewModel
    @Environment(\.modelContext) private var modelContext
    @State private var showingFoodSheet = false
    @State private var activeRecoveryAction: RecoveryActionType?
    @State private var showButtonTapAlert = false
    @State private var buttonTapMessage = ""
    @State private var showingSettings = false
    @State private var showingStageDetails = false
    @State private var showingDiagnostics = false
    @State private var appLimitSelection: FamilyActivitySelection?
    @State private var usageRefreshTrigger = UUID()
    @State private var showFeedingAnimation = false
    @State private var feedingFoodEmoji = "🍖"
    @State private var feedingVariant = 0
    
    private var pet: Pet? {
        viewModel.currentPet
    }
    
    private var stageInfo: (stage: Int, current: EvolutionStage, next: EvolutionStage?) {
        EvolutionStages.getCurrentStage(progress: pet?.growthProgress ?? 0)
    }
    
    private var petMood: PetMood {
        guard let pet = pet else { return .neutral }
        
        if pet.healthState == .dead || pet.healthState == .sick {
            return .sad
        }
        
        if pet.fullness > 70 && pet.mood >= 7 {
            return .happy
        }
        
        if pet.fullness < 30 {
            return .sad
        }
        
        return .neutral
    }
    
    @AppStorage("hasSeenTutorial") private var hasSeenTutorial = false
    @State private var selectedSpecies: Species? = nil
    @State private var showingNamingScreen = false
    @State private var showingTutorial = false
    
    var body: some View {
        ZStack {
            // Show species selection if no pet
            if pet == nil {
                if selectedSpecies == nil {
                    // Step 1: Choose species
                    SpeciesSelectionView(onSelect: { species in
                        selectedSpecies = species
                        showingNamingScreen = true
                    })
                } else if showingNamingScreen, let species = selectedSpecies {
                    // Step 2: Name the pet
                    PetNamingView(species: species, onComplete: { name in
                        viewModel.createNewPet(species: species, name: name)
                        showingNamingScreen = false
                        
                        // Show tutorial if first time
                        if !hasSeenTutorial {
                            showingTutorial = true
                        }
                    })
                }
            } else {
                // Show normal home view with pet
                petHomeView
                    .id(viewModel.refreshTrigger)  // Force refresh when recovery completes
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingFoodSheet) {
            FoodShopView(onFeedAnimationTrigger: { foodEmoji in
                triggerFeedingAnimation(foodEmoji: foodEmoji)
            })
            .environment(viewModel)
        }
        .fullScreenCover(isPresented: $showingSettings) {
            SettingsView()
                .environment(viewModel)
                .background(Color.clear)
        }
        .sheet(isPresented: $showingStageDetails) {
            stageDetailsView
        }
        .sheet(item: $activeRecoveryAction) { action in
            RecoveryModal(
                action: action,
                gems: viewModel.gemsBalance,
                onConfirm: {
                    print("✅ Confirm button tapped for \(action)")
                    Task { @MainActor in
                        viewModel.recoveryAction = action
                        print("🔄 Starting recovery for \(action)...")
                        let success = await viewModel.performRecovery()
                        print("🔄 Recovery returned: \(success)")
                        activeRecoveryAction = nil
                        
                        if success {
                            buttonTapMessage = "Recovery successful! Your pet is now healthy."
                        } else {
                            buttonTapMessage = "Recovery failed. Check console for details."
                        }
                        showButtonTapAlert = true
                    }
                }
            )
        }
        .alert("Button Tapped!", isPresented: $showButtonTapAlert) {
            Button("OK") { }
        } message: {
            Text(buttonTapMessage)
        }
        .fullScreenCover(isPresented: $showingTutorial) {
            TutorialView()
                .onDisappear {
                    hasSeenTutorial = true
                }
        }
        .sheet(isPresented: $showingDiagnostics) {
            UsageDiagnosticView()
        }
        .overlay(
            Group {
                if showFeedingAnimation {
                    FeedingAnimationView(
                        foodEmoji: feedingFoodEmoji,
                        variant: feedingVariant,
                        isActive: $showFeedingAnimation
                    )
                    .ignoresSafeArea()
                }
            }
        )
    }
    
    private var petHomeView: some View {
        ZStack {
            // Base gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.45, green: 0.53, blue: 0.93),
                    Color(red: 0.58, green: 0.4, blue: 0.93),
                    Color(red: 0.98, green: 0.64, blue: 0.93)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Main content
            VStack(spacing: 0) {
                // Daily Check-In - compact at top
                if let pet = pet {
                    DailyCheckIn(
                        currentUsage: pet.currentUsage,
                        currentLimit: pet.currentLimit,
                        energyBalance: viewModel.energyBalance,
                        onCheckIn: { usage, limit in
                            viewModel.updateUsage(usageMinutes: usage, limitMinutes: limit)
                        },
                        onRefresh: {
                            Task {
                                await viewModel.updateUsageFromScreenTime()
                            }
                        }
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
                
                // Pet Display Area - Takes remaining space
                ZStack {
                    // Animated background with decorations
                    PetBackground(stage: stageInfo.stage)
                    
                    // Health Banner (if needed) - floating at top
                    if let pet = pet, pet.healthState != .healthy {
                        VStack {
                            HealthBanner(
                                healthState: pet.healthState,
                                consecutiveUnfedDays: pet.consecutiveUnfedDays,
                                isFragile: pet.isFragile,
                                onFeed: { showingFoodSheet = true },
                                onCure: {
                                    print("🔧 Cure button tapped")
                                    activeRecoveryAction = .cure
                                },
                                onRevive: {
                                    print("💖 Revive button tapped")
                                    activeRecoveryAction = .revive
                                },
                                onRestart: {
                                    print("🔄 Restart button tapped")
                                    activeRecoveryAction = .restart
                                }
                            )
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            
                            Spacer()
                        }
                        .zIndex(40)
                    }
                    
                    // TOP-LEFT: Stats Badge
                    VStack {
                        HStack {
                            if let pet = pet {
                                statsOverlay(fullness: Int(pet.fullness), mood: pet.mood)
                            }
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding(.leading, 16)
                    .padding(.top, 16)
                    .allowsHitTesting(false)  // Don't block touches - just decorative
                    .zIndex(20)
                        
                    // TOP-RIGHT: Settings & Stage buttons  
                    VStack(spacing: 12) {
                        // Settings button
                        Button {
                            showingSettings = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.black)
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.9))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.black, lineWidth: 2)
                                )
                                .shadow(color: .black.opacity(0.3), radius: 0, x: 2, y: 2)
                        }
                        .buttonStyle(.plain)
                        
                        // Stage button
                        Button {
                            showingStageDetails = true
                        } label: {
                            Image(systemName: "star.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(
                                    LinearGradient(
                                        colors: [Color(red: 0.8, green: 0.5, blue: 1.0), Color(red: 1.0, green: 0.4, blue: 0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.black, lineWidth: 2)
                                )
                                .shadow(color: .black.opacity(0.3), radius: 0, x: 2, y: 2)
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(.trailing, 16)
                    .padding(.top, 16)
                    .zIndex(20)
                        
                    // CENTER: Pet (positioned on ground, above background)
                    if let pet = pet {
                        PixelPet(
                            stage: stageInfo.stage,
                            mood: petMood,
                            isActive: pet.healthState == .healthy,
                            petType: pet.species,
                            healthState: pet.healthState,
                            currentAnimation: viewModel.currentAnimation,
                            trickVariant: viewModel.trickVariant
                        )
                        .scaleEffect(1.5)
                        .frame(height: 120)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                        .padding(.bottom, 96)
                        .allowsHitTesting(false)  // Pet is decorative, don't block touches
                        .zIndex(10)
                    }
                        
                    // BOTTOM-LEFT: Feed Button
                    Button {
                        showingFoodSheet = true
                    } label: {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 0.0, green: 0.9, blue: 0.4), Color(red: 0.0, green: 0.7, blue: 0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.black, lineWidth: 3))
                            .shadow(color: .black.opacity(0.3), radius: 0, x: 4, y: 4)
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    .padding(.leading, 24)
                    .padding(.bottom, 24)
                    .zIndex(20)
                        
                    // BOTTOM-RIGHT: Pet Actions Menu
                    if let pet = pet {
                        PetActions(
                            healthState: pet.healthState,
                            mood: pet.mood,
                            onMoodChange: { delta in
                                viewModel.updateMood(delta: delta)
                            },
                            onTriggerAnimation: { animation, variant in
                                viewModel.triggerAnimation(animation, variant: variant)
                            }
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .padding(.trailing, 24)
                        .padding(.bottom, 24)
                        .zIndex(20)
                    }
                }
                .frame(maxHeight: .infinity)
                
                // Hidden: DeviceActivityReport tracker
                if let selection = appLimitSelection, !selection.applicationTokens.isEmpty {
                    ScreenTimeReportView(appSelection: selection)
                        .id(usageRefreshTrigger)
                }
            }
            
            // Debug Panel (DEBUG only)
            #if DEBUG
            if let pet = pet {
                VStack {
                    Spacer()
                    HStack {
                        DebugPanel(
                            currentGems: viewModel.gemsBalance,
                            currentUnfedDays: pet.consecutiveUnfedDays,
                            currentGrowthProgress: pet.growthProgress,
                            onAddGems: { amount in
                                viewModel.debugAddGems(amount)
                            },
                            onSetUnfedDays: { days in
                                viewModel.debugSetUnfedDays(days)
                            },
                            onSetGrowthProgress: { progress in
                                viewModel.debugSetGrowthProgress(progress)
                            },
                            onResetGame: {
                                viewModel.debugResetGame()
                            },
                            onSetTestState: { state in
                                viewModel.debugSetTestState(state.rawValue.lowercased())
                            },
                            onClearUsageData: {
                                // Clear App Group data
                                ScreenTimeUsageManager.shared.clearUsageData()
                                // Also reset the pet's usage display
                                viewModel.resetUsageDisplay()
                            },
                            onTestUsageRefresh: {
                                print("🧪 Manual usage refresh triggered")
                                usageRefreshTrigger = UUID()
                            },
                            onShowDiagnostics: {
                                showingDiagnostics = true
                            },
                            onManualSetUsage: { minutes in
                                viewModel.screenTimeService.manuallySetUsage(minutes: minutes)
                                usageRefreshTrigger = UUID()  // Trigger UI update
                            },
                            onTestAppGroup: {
                                testAppGroupIO()
                            },
                            onRestartMonitoring: {
                                restartMonitoring()
                            }
                        )
                        .padding(.leading, 16)
                        .padding(.bottom, 100)
                        
                        Spacer()
                    }
                }
                .zIndex(50)
            }
            #endif
            
            // Hidden: DeviceActivityReport tracker for automatic usage updates
            // This triggers the report extension to query Screen Time data
            if let selection = appLimitSelection, !selection.applicationTokens.isEmpty {
                ScreenTimeReportView(appSelection: selection)
                    .id(usageRefreshTrigger)  // Force recreation on manual refresh
            }
        }
        .onAppear {
            loadAppLimitConfig()
        }
    }
    
    
    private func loadAppLimitConfig() {
        let userId = viewModel.userId
        let descriptor = FetchDescriptor<AppLimitConfig>(
            predicate: #Predicate<AppLimitConfig> { config in
                config.userId == userId
            }
        )
        
        do {
            if let config = try modelContext.fetch(descriptor).first,
               let decoded = try? JSONDecoder().decode(FamilyActivitySelection.self, from: config.selectedApps) {
                appLimitSelection = decoded
                print("✅ Loaded app limit selection for DeviceActivityReport")
                print("   Apps: \(decoded.applicationTokens.count)")
                print("   Limit: \(config.limitMinutes) minutes")
                
                // Start monitoring automatically if we have a saved selection
                // Wait a moment to ensure authorization is initialized
                if !decoded.applicationTokens.isEmpty {
                    Task {
                        // Wait for authorization to be checked
                        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
                        
                        // Verify authorization before starting
                        let isAuthorized = await viewModel.screenTimeService.checkAuthorizationStatusWithRetry()
                        
                        if isAuthorized {
                            print("🚀 Auto-starting Screen Time monitoring (authorization confirmed)...")
                            await MainActor.run {
                                viewModel.screenTimeService.startMonitoring(with: decoded)
                            }
                        } else {
                            print("⚠️ Cannot start monitoring - authorization not granted")
                        }
                    }
                }
            } else {
                print("ℹ️ No app limit config found")
            }
        } catch {
            print("❌ Failed to load app limit config: \(error)")
        }
    }
    
    private func testAppGroupIO() {
        print("🧪 === APP GROUP I/O TEST ===")
        let manager = ScreenTimeUsageManager.shared
        let testMinutes = 42
        
        // Write test data
        print("📝 Step 1: Writing \(testMinutes) minutes...")
        let testData = ScreenTimeUsageData(date: Date(), totalMinutes: testMinutes)
        manager.saveUsage(testData)
        
        // Small delay to ensure write completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Read it back
            print("📖 Step 2: Reading back...")
            if let readData = manager.loadUsage() {
                print("✅ SUCCESS! Read back: \(readData.totalMinutes) minutes")
                print("   Date: \(readData.dateString)")
                print("   Last Updated: \(readData.lastUpdated)")
                print("   Is Today: \(readData.isToday)")
                
                if readData.totalMinutes == testMinutes {
                    print("🎉 PERFECT MATCH! App Group is working!")
                } else {
                    print("⚠️ Data mismatch: wrote \(testMinutes), read \(readData.totalMinutes)")
                }
            } else {
                print("❌ FAILED: Could not read back data")
                print("   This means App Group is NOT working")
            }
            print("🧪 === TEST COMPLETE ===")
        }
    }
    
    private func restartMonitoring() {
        print("🔄 === FULL MONITORING RESET ===")
        
        // 1. Stop current monitoring
        viewModel.screenTimeService.stopMonitoring()
        print("✅ Stopped existing monitoring")
        
        // 2. Clear all usage data
        ScreenTimeUsageManager.shared.clearUsageData()
        viewModel.resetUsageDisplay()
        print("✅ Cleared all usage data")
        
        // 3. Wait then restart
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if let selection = self.appLimitSelection {
                print("🚀 Restarting monitoring with selection...")
                self.viewModel.screenTimeService.startMonitoring(with: selection)
                print("✅ Monitoring restarted fresh!")
                print("   Usage should now show 0")
                print("   Use your selected app for 5+ minutes to test")
            } else {
                print("⚠️ No app selection found - loading config...")
                self.loadAppLimitConfig()
            }
        }
    }
    
    func triggerFeedingAnimation(foodEmoji: String) {
        feedingFoodEmoji = foodEmoji
        feedingVariant = Int.random(in: 0...2)  // Random animation variant
        showFeedingAnimation = true
    }
    
    // MARK: - Stats Overlay (Top-Left)
    
    @ViewBuilder
    private func statsOverlay(fullness: Int, mood: Int) -> some View {
        HStack(spacing: 12) {
            // Fullness
            HStack(spacing: 6) {
                Text("🍖")
                    .font(.system(size: 16))
                Text("\(fullness)%")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.4))
                .frame(width: 1, height: 16)
            
            // Mood
            HStack(spacing: 6) {
                let moodEmoji = mood >= 4 ? "😊" : mood >= 2 ? "😐" : "😢"
                Text(moodEmoji)
                    .font(.system(size: 16))
                Text("\(mood)/5")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Color.black.opacity(0.4)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.5), lineWidth: 2)
                )
        )
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 4)
    }
    
    // MARK: - Stage Details View
    
    @ViewBuilder
    private var stageDetailsView: some View {
        VStack(spacing: 20) {
            Text("Evolution Progress")
                .font(.system(size: 24, weight: .bold))
            
            // Current Stage Badge
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Text(stageInfo.current.name.uppercased())
                        .font(.system(size: 20, weight: .bold))
                    
                    Text(stageInfo.current.emoji)
                        .font(.system(size: 20))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.8, green: 0.5, blue: 1.0), Color(red: 1.0, green: 0.4, blue: 0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black, lineWidth: 2)
                )
                
                Text("Stage \(stageInfo.stage + 1) of 5")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            // Progress Bar
            if let pet = pet, let nextThreshold = stageInfo.next?.threshold {
                ProgressBar(
                    current: pet.growthProgress,
                    max: nextThreshold,
                    label: "Growth Progress",
                    color: .purple
                )
                .padding(.horizontal)
            }
            
            // Progress Info
            VStack(spacing: 8) {
                HStack {
                    Text("Current Progress:")
                        .foregroundColor(.gray)
                    Spacer()
                    Text("\(pet?.growthProgress ?? 0)")
                        .fontWeight(.bold)
                }
                
                if let nextThreshold = stageInfo.next?.threshold {
                    HStack {
                        Text("Next Stage At:")
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(nextThreshold)")
                            .fontWeight(.bold)
                    }
                } else {
                    Text("🎉 Max Stage Reached!")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(red: 0.8, green: 0.5, blue: 1.0))
                }
            }
            .padding()
            .background(Color(red: 0.95, green: 0.9, blue: 1.0))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black, lineWidth: 2)
            )
            .padding(.horizontal)
            
            Spacer()
            
            Button("Close") {
                showingStageDetails = false
            }
            .font(.system(size: 16, weight: .bold))
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black, lineWidth: 2)
            )
            .padding(.horizontal)
        }
        .padding()
        .presentationDetents([.medium])
    }
}

#Preview {
    HomeView()
        .environment(AppViewModel(modelContext: ModelContext(
            try! ModelContainer(for: Pet.self, DailyStats.self, Wallet.self, LedgerEntry.self)
        )))
}
