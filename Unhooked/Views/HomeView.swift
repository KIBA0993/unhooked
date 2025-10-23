//
//  HomeView.swift
//  Unhooked
//
//  Main home screen with pet - Redesigned with retro aesthetic
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(AppViewModel.self) private var viewModel
    @State private var showingFoodSheet = false
    @State private var showingRecoverySheet = false
    
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
    
    var body: some View {
        ZStack {
            // Background - solid light lavender
            RetroColors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    // Health Banner (if needed)
                    if let pet = pet {
                        HealthBanner(
                            healthState: pet.healthState,
                            consecutiveUnfedDays: pet.consecutiveUnfedDays,
                            isFragile: pet.isFragile,
                            onFeed: {
                                showingFoodSheet = true
                            },
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
                    }
                    
                    // Main Pet Card
                    VStack(spacing: 0) {
                        petCard
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            
            // Debug Panel (DEBUG only)
            #if DEBUG
            if let pet = pet {
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
            }
            #endif
        }
        .sheet(isPresented: $showingFoodSheet) {
            FoodShopView()
                .environment(viewModel)
        }
        .sheet(isPresented: $showingRecoverySheet) {
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
    }
    
    // MARK: - Pet Card
    
    private var petCard: some View {
        VStack(spacing: 16) {
            // Header with currency and stage
            HStack(alignment: .top) {
                CurrencyDisplay(
                    energy: viewModel.energyBalance,
                    gems: viewModel.gemsBalance
                )
                
                Spacer()
                
                if let pet = pet {
                    StageIndicator(
                        currentStage: stageInfo.stage,
                        growthProgress: pet.growthProgress,
                        species: pet.species
                    )
                }
            }
            
            // Daily Check-In
            if let pet = pet {
                DailyCheckIn(
                    currentUsage: pet.currentUsage,
                    currentLimit: pet.currentLimit,
                    onCheckIn: { usage, limit in
                        viewModel.updateUsage(usageMinutes: usage, limitMinutes: limit)
                    }
                )
            }
            
            // Stage Name Badge
            HStack {
                Spacer()
                
                HStack(spacing: 8) {
                    Text(stageInfo.current.name.uppercased())
                        .font(.system(size: 18, weight: .black))
                    
                    Text(stageInfo.current.emoji)
                        .font(.system(size: 22))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(RetroColors.purple)
                .foregroundColor(.black)
                .retroBorder(width: 4, cornerRadius: 24)
                .retroShadow(offset: 4)
                
                Spacer()
            }
            
            // Pet Display
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
                .frame(height: 200)
                .padding(.vertical, 20)
            }
            
            // Growth Progress
            if let pet = pet, let nextThreshold = stageInfo.next?.threshold {
                ProgressBar(
                    current: pet.growthProgress,
                    max: nextThreshold,
                    label: "Growth Progress",
                    color: .purple
                )
            } else if let pet = pet {
                // Max stage reached
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Text("🎉 Max Stage!")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.purple)
                        Text("Growth: \(pet.growthProgress)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
            }
            
            // Pet Actions
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
            }
            
            // Stats & Feed Button
            if let pet = pet {
                HStack(spacing: 12) {
                    // Fullness
                    VStack(spacing: 6) {
                        Text("FULLNESS")
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(.black)
                        Text("\(Int(pet.fullness))%")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(.black)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 90)
                    .background(RetroColors.lightBlue)
                    .retroBorder(width: 4, cornerRadius: 12)
                    .retroShadow(offset: 4)
                    
                    // Mood
                    VStack(spacing: 6) {
                        Text("MOOD")
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(.black)
                        Text("\(pet.mood)/5")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(.black)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 90)
                    .background(RetroColors.lightPink)
                    .retroBorder(width: 4, cornerRadius: 12)
                    .retroShadow(offset: 4)
                    
                    // Feed Button
                    Button {
                        showingFoodSheet = true
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "fork.knife")
                                .font(.system(size: 28))
                            Text("FEED")
                                .font(.system(size: 14, weight: .black))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 90)
                        .background(RetroColors.green)
                        .foregroundColor(.black)
                        .retroBorder(width: 4, cornerRadius: 12)
                        .retroShadow(offset: 4)
                    }
                    .buttonStyle(.plain)
                    .disabled(pet.canFeed == false)
                }
            }
        }
        .padding(24)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(.black, lineWidth: 5)
        )
        .shadow(color: .black, radius: 0, x: 6, y: 6)
    }
    
    // MARK: - Daily Status Card
    
    private func dailyStatusCard(pet: Pet) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(.white)
                Text("Daily Status")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .textCase(.uppercase)
                Spacer()
            }
            
            VStack(spacing: 8) {
                statusRow(
                    label: "Fed Today",
                    value: pet.fedToday ? "✅ Yes" : "❌ No",
                    valueColor: pet.fedToday ? .green : .red
                )
                
                statusRow(
                    label: "Food Spending",
                    value: "\(pet.todayFoodSpend) E",
                    valueColor: .white
                )
                
                statusRow(
                    label: "Today's Buff",
                    value: "+\(Int(pet.dailyBuffAccumulated * 100))%",
                    valueColor: .white
                )
                
                statusRow(
                    label: "Unfed Streak",
                    value: "\(pet.consecutiveUnfedDays) days",
                    valueColor: pet.consecutiveUnfedDays >= 3 ? .red : .green
                )
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color(red: 0.3, green: 0.35, blue: 0.4), Color(red: 0.2, green: 0.25, blue: 0.35)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .foregroundColor(.white)
        .retroBorder(width: 4, cornerRadius: 16)
        .retroShadow(offset: 6)
    }
    
    private func statusRow(label: String, value: String, valueColor: Color) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundColor(valueColor)
        }
    }
}

#Preview {
    HomeView()
        .environment(AppViewModel(modelContext: ModelContext(
            try! ModelContainer(for: Pet.self, DailyStats.self, Wallet.self, LedgerEntry.self)
        )))
}
