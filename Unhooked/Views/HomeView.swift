//
//  HomeView.swift
//  Unhooked
//
//  Main home screen with pet - Exact Figma layout
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(AppViewModel.self) private var viewModel
    @State private var showingFoodSheet = false
    @State private var showingRecoverySheet = false
    @State private var showingSettings = false
    @State private var showingStageDetails = false
    
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
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingFoodSheet) {
            FoodShopView()
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
        .sheet(isPresented: $showingRecoverySheet) {
            recoveryView
        }
        .fullScreenCover(isPresented: $showingTutorial) {
            TutorialView()
                .onDisappear {
                    hasSeenTutorial = true
                }
        }
    }
    
    private var petHomeView: some View {
        ZStack {
            // FULLSCREEN ANIMATED BACKGROUND
            PetBackground(stage: stageInfo.stage)
                .ignoresSafeArea()
            
            // FULLSCREEN OVERLAY LAYOUT
            VStack(spacing: 0) {
                // TOP: Daily Check-in bar
                if let pet = pet {
                    DailyCheckIn(
                        currentUsage: pet.currentUsage,
                        currentLimit: pet.currentLimit,
                        onCheckIn: { usage, limit in
                            viewModel.updateUsage(usageMinutes: usage, limitMinutes: limit)
                        }
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
                
                // MIDDLE: Pet display area (takes up remaining space)
                ZStack {
                    // Health Banner (if needed) - floating at top
                    if let pet = pet, pet.healthState != .healthy {
                        VStack {
                            HealthBanner(
                                healthState: pet.healthState,
                                consecutiveUnfedDays: pet.consecutiveUnfedDays,
                                isFragile: pet.isFragile,
                                onFeed: { showingFoodSheet = true },
                                onCure: {
                                    viewModel.showRecoveryOptions(for: .cure)
                                    showingRecoverySheet = true
                                },
                                onRevive: {
                                    viewModel.showRecoveryOptions(for: .revive)
                                    showingRecoverySheet = true
                                },
                                onRestart: {
                                    viewModel.showRecoveryOptions(for: .restart)
                                    showingRecoverySheet = true
                                }
                            )
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            
                            Spacer()
                        }
                        .zIndex(40)
                    }
                    
                    // TOP-LEFT: Stats Badge (Fullness & Mood)
                    VStack {
                        HStack {
                            if let pet = pet {
                                statsOverlay(fullness: Int(pet.fullness), mood: pet.mood)
                            }
                            Spacer()
                        }
                        .padding(.leading, 16)
                        .padding(.top, 16)
                        
                        Spacer()
                    }
                    .zIndex(20)
                    
                    // TOP-RIGHT: Settings & Stage buttons
                    VStack {
                        HStack {
                            Spacer()
                            
                            VStack(spacing: 8) {
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
                                
                                // Stage indicator button
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
                        }
                        .padding(.trailing, 16)
                        .padding(.top, 16)
                        
                        Spacer()
                    }
                    .zIndex(20)
                    
                    // CENTER: Pet (positioned on ground)
                    VStack {
                        Spacer()
                        
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
                            .scaleEffect(1.5) // Smaller pet size
                            .frame(height: 120)
                            .padding(.bottom, 80) // Position above ground
                        }
                    }
                    .zIndex(10)
                    
                    // BOTTOM-LEFT: Feed button
                    VStack {
                        Spacer()
                        
                        HStack {
                            Button {
                                showingFoodSheet = true
                            } label: {
                                Image(systemName: "fork.knife")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 56, height: 56)
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
                            .padding(.leading, 24)
                            .padding(.bottom, 24)
                            
                            Spacer()
                        }
                    }
                    .zIndex(20)
                    
                    // BOTTOM-RIGHT: Pet Actions menu
                    VStack {
                        Spacer()
                        
                        HStack {
                            Spacer()
                            
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
                                .padding(.trailing, 24)
                                .padding(.bottom, 24)
                            }
                        }
                    }
                    .zIndex(20)
                }
                .frame(maxHeight: .infinity)
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
        }
    }
    
    @ViewBuilder
    private var recoveryView: some View {
        if let action = viewModel.recoveryAction {
            RecoveryModal(
                action: action,
                gems: viewModel.gemsBalance,
                onConfirm: {
                    Task {
                        await viewModel.performRecovery()
                    }
                }
            )
        }
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
