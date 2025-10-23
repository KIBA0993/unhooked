//
//  HomeView.swift
//  Unhooked
//
//  Main home screen with pet
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(AppViewModel.self) private var viewModel
    @State private var showingFoodSheet = false
    @State private var showingCosmeticsSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Wallet Header
                    walletHeader
                    
                    // Health Banner (if sick or dead)
                    if let pet = viewModel.currentPet {
                        if pet.isSick {
                            sickBanner
                        } else if pet.isDead {
                            deadBanner
                        }
                    }
                    
                    // Pet Display
                    petView
                    
                    Spacer()
                    
                    // Action Buttons
                    actionButtons
                }
            }
            .navigationTitle("Unhooked")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingFoodSheet) {
                FoodShopView()
                    .environment(viewModel)
            }
            .sheet(isPresented: $showingCosmeticsSheet) {
                CosmeticsShopView()
                    .environment(viewModel)
            }
        }
    }
    
    // MARK: - Wallet Header
    
    private var walletHeader: some View {
        HStack(spacing: 20) {
            // Energy
            HStack(spacing: 8) {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(.yellow)
                Text("\(viewModel.energyBalance)")
                    .font(.headline)
                    .monospacedDigit()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
            
            // Gems
            HStack(spacing: 8) {
                Image(systemName: "diamond.fill")
                    .foregroundStyle(.cyan)
                Text("\(viewModel.gemsBalance)")
                    .font(.headline)
                    .monospacedDigit()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Health Banners
    
    private var sickBanner: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "heart.text.square.fill")
                    .foregroundStyle(.orange)
                    .font(.title2)
                
                Text("Your friend is sick")
                    .font(.headline)
                
                Spacer()
            }
            
            Text("Feed twice in 3 days to recover, or visit the Vet now.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                Button {
                    showingFoodSheet = true
                } label: {
                    Label("Feed", systemImage: "takeoutbag.and.cup.and.straw.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                
                Button {
                    viewModel.showRecoveryOptions(for: .cure)
                } label: {
                    Label("Vet (120 Gems)", systemImage: "cross.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(.orange.opacity(0.1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Health Alert: Your friend is sick")
        .accessibilityHint("Feed twice in 3 days to recover, or visit the Vet for 120 Gems")
    }
    
    private var deadBanner: some View {
        VStack(spacing: 12) {
            Image(systemName: "cloud.fill")
                .font(.system(size: 40))
                .foregroundStyle(.gray)
            
            Text("Your friend has passed away")
                .font(.title3)
                .fontWeight(.medium)
            
            Text("You can revive them or start fresh with a new friend.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 12) {
                Button {
                    viewModel.showRecoveryOptions(for: .revive)
                } label: {
                    VStack(spacing: 4) {
                        Text("Revive")
                        Text("400 Gems")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                
                Button {
                    viewModel.showRecoveryOptions(for: .restart)
                } label: {
                    VStack(spacing: 4) {
                        Text("Start Over")
                        Text("200 Gems")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(.gray.opacity(0.1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Your friend has passed away")
        .accessibilityHint("Revive for 400 Gems or Start Over for 200 Gems")
    }
    
    // MARK: - Pet View
    
    private var petView: some View {
        VStack {
            if let pet = viewModel.currentPet {
                ZStack {
                    // Pet visualization
                    Circle()
                        .fill(pet.isDead ? .gray.opacity(0.3) : petColor(for: pet.species))
                        .frame(width: 200, height: 200)
                        .overlay {
                            VStack {
                                Text(pet.species == .cat ? "🐱" : "🐶")
                                    .font(.system(size: 80))
                                    .grayscale(pet.isDead ? 1.0 : 0.0)
                                    .opacity(pet.isDead ? 0.5 : 1.0)
                                
                                if pet.isFragile {
                                    Image(systemName: "bandage.fill")
                                        .foregroundStyle(.orange)
                                        .font(.caption)
                                }
                            }
                        }
                    
                    // Health overlay
                    if pet.isSick {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Image(systemName: "thermometer.medium")
                                    .foregroundStyle(.orange)
                                    .font(.title2)
                                    .padding(8)
                            }
                        }
                        .frame(width: 200, height: 200)
                    }
                }
                
                // Stats
                VStack(spacing: 8) {
                    Text("Stage \(pet.stage)")
                        .font(.headline)
                    
                    HStack(spacing: 16) {
                        StatBadge(
                            icon: "heart.fill",
                            value: "\(Int(pet.fullness))%",
                            color: .pink
                        )
                        
                        StatBadge(
                            icon: "face.smiling",
                            value: "\(pet.mood)/10",
                            color: .yellow
                        )
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                showingFoodSheet = true
            } label: {
                Label("Feed", systemImage: "takeoutbag.and.cup.and.straw.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.green, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
            }
            .disabled(viewModel.currentPet?.canFeed == false)
            
            Button {
                showingCosmeticsSheet = true
            } label: {
                Label("Cosmetics", systemImage: "paintpalette.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.purple.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.purple)
            }
        }
        .padding()
    }
    
    // MARK: - Helpers
    
    private func petColor(for species: Species) -> Color {
        switch species {
        case .cat: return .orange.opacity(0.3)
        case .dog: return .brown.opacity(0.3)
        }
    }
}

// MARK: - Stat Badge

struct StatBadge: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(value)
                .font(.subheadline)
                .monospacedDigit()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
    }
}

#Preview {
    HomeView()
        .environment(AppViewModel(modelContext: ModelContext(
            try! ModelContainer(for: Pet.self, DailyStats.self)
        )))
}

