//
//  FoodShopView.swift
//  Unhooked
//
//  Food shop with retro Figma design
//

import SwiftUI
import SwiftData

struct FoodShopView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) private var viewModel
    @Environment(\.modelContext) private var modelContext
    
    @State private var availableItems: [FoodCatalogItem] = []
    @State private var isLoading = true
    
    private var pet: Pet? {
        viewModel.currentPet
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Currency Display at top
                    HStack(spacing: 12) {
                        // Energy
                        HStack(spacing: 8) {
                            Text("⚡")
                                .font(.system(size: 20))
                            VStack(alignment: .leading, spacing: 0) {
                                Text("ENERGY")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.black.opacity(0.7))
                                Text("\(viewModel.energyBalance)")
                                    .font(.system(size: 16, weight: .bold))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 1.0, green: 0.9, blue: 0.2), Color(red: 1.0, green: 0.8, blue: 0.25)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .retroBorder(width: 3, cornerRadius: 12)
                        .retroShadow(offset: 3)
                        
                        // Gems
                        HStack(spacing: 8) {
                            Text("💎")
                                .font(.system(size: 20))
                            VStack(alignment: .leading, spacing: 0) {
                                Text("GEMS")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.black.opacity(0.7))
                                Text("\(viewModel.gemsBalance)")
                                    .font(.system(size: 16, weight: .bold))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.4, green: 0.9, blue: 0.9), Color(red: 0.3, green: 0.8, blue: 0.9)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .retroBorder(width: 3, cornerRadius: 12)
                        .retroShadow(offset: 3)
                    }
                    .padding(.horizontal)
                    
                    // Health State Warning
                    if let pet = pet, pet.healthState == .sick {
                        Text("⚠️ Feed to Recover!")
                            .font(.system(size: 14, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color(red: 1.0, green: 0.76, blue: 0.3))
                            .retroBorder(width: 2, cornerRadius: 8)
                            .padding(.horizontal)
                    }
                    
                    if let pet = pet, pet.healthState == .dead {
                        VStack(spacing: 8) {
                            Text("Food is not available for departed friends")
                                .font(.system(size: 14, weight: .bold))
                                .multilineTextAlignment(.center)
                                .padding()
                        }
                        .frame(maxWidth: .infinity)
                        .background(Color(red: 1.0, green: 0.8, blue: 0.8))
                        .retroBorder(width: 2, cornerRadius: 12)
                        .padding(.horizontal)
                    }
                    
                    // Food Items
                    if isLoading {
                        ProgressView()
                            .padding()
                    } else {
                        ForEach(availableItems) { item in
                            FoodItemCard(
                                item: item,
                                energy: viewModel.energyBalance,
                                canFeed: pet?.healthState != .dead,
                                onPurchase: {
                                    Task {
                                        await purchaseFood(item)
                                    }
                                }
                            )
                            .padding(.horizontal)
                        }
                    }
                    
                    // Energy Balance Info
                    VStack(spacing: 8) {
                        HStack {
                            Text("Your Energy:")
                                .font(.system(size: 16, weight: .bold))
                            Spacer()
                            Text("\(viewModel.energyBalance) E")
                                .font(.system(size: 24, weight: .bold))
                        }
                        
                        Text("💡 Spend ≥100 E on food today to mark as \"fed\" and maintain health")
                            .font(.system(size: 11))
                            .foregroundColor(.black.opacity(0.8))
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color(red: 1.0, green: 0.76, blue: 0.2), Color(red: 1.0, green: 0.8, blue: 0.25)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .retroBorder(width: 3, cornerRadius: 12)
                    .retroShadow(offset: 4)
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }
                .padding(.top)
            }
            .background(Color(red: 0.97, green: 0.97, blue: 0.97))
            .navigationTitle("Food Shop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                }
            }
            .task {
                await loadItems()
            }
        }
    }
    
    private func loadItems() async {
        guard let pet = pet else {
            isLoading = false
            return
        }
        
        // Query all enabled food items from SwiftData
        let descriptor = FetchDescriptor<FoodCatalogItem>(
            predicate: #Predicate<FoodCatalogItem> { item in
                item.isEnabled
            }
        )
        
        do {
            let allItems = try modelContext.fetch(descriptor)
            availableItems = allItems.filter { $0.isAvailable(for: pet.species) }
        } catch {
            print("Error loading food items: \(error)")
        }
        
        isLoading = false
    }
    
    private func purchaseFood(_ item: FoodCatalogItem) async {
        await viewModel.feedPet(foodItemId: item.itemId)
    }
}

// MARK: - Emoji Helper

extension FoodCatalogItem {
    var emoji: String {
        // Map item titles to emojis matching Figma design
        switch title {
        // Cat foods
        case "Tuna Treats": return "🐟"
        case "Chicken Bites": return "🍗"
        case "Salmon Bowl": return "🍱"
        case "Catnip Feast": return "🌿"
        
        // Dog foods
        case "Crunch Biscuit": return "🦴"
        case "Turkey Jerky": return "🥓"
        case "Beef Stew": return "🍲"
        case "Birthday Bones": return "🎉"
        
        // Both species
        case "Veggie Medley": return "🥗"
        
        // Fallback for custom items
        case _ where title.lowercased().contains("tuna"): return "🐟"
        case _ where title.lowercased().contains("chicken"): return "🍗"
        case _ where title.lowercased().contains("salmon"): return "🍱"
        case _ where title.lowercased().contains("fish"): return "🐟"
        case _ where title.lowercased().contains("biscuit"): return "🦴"
        case _ where title.lowercased().contains("bone"): return "🦴"
        case _ where title.lowercased().contains("jerky"): return "🥓"
        case _ where title.lowercased().contains("stew"): return "🍲"
        case _ where title.lowercased().contains("veggie"): return "🥗"
        case _ where title.lowercased().contains("catnip"): return "🌿"
        default: return "🍖"
        }
    }
    
    var isSeasonal: Bool {
        seasonalStartUTC != nil && seasonalEndUTC != nil
    }
}

// MARK: - Food Item Card

struct FoodItemCard: View {
    let item: FoodCatalogItem
    let energy: Int
    let canFeed: Bool
    let onPurchase: () -> Void
    
    @State private var showInfo = false
    
    private var canAfford: Bool {
        energy >= item.priceEnergy
    }
    
    private var isDisabled: Bool {
        !canFeed || !canAfford
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Left side: Emoji, Title, Seasonal Badge, Info Button (all in one row)
            HStack(spacing: 8) {
                Text(item.emoji)
                    .font(.system(size: 24))
                
                Text(item.title)
                    .font(.system(size: 16, weight: .bold))
                
                if item.isSeasonal {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 0.96, green: 0.64, blue: 0.38))
                }
                
                // Info button
                Button {
                    showInfo.toggle()
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 14))
                        .foregroundColor(Color.gray.opacity(0.7))
                        .padding(4)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showInfo, arrowEdge: .trailing) {
                    foodInfoPopover
                        .presentationCompactAdaptation(.popover)
                }
            }
            
            Spacer()
            
            // Right side: Price badge and Feed button (vertical stack)
            VStack(spacing: 8) {
                // Price badge
                Text("\(item.priceEnergy) E")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color(red: 1.0, green: 0.8, blue: 0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.black, lineWidth: 2)
                    )
                
                // Feed button
                Button(action: onPurchase) {
                    Text(canAfford ? "Feed" : "Not Enough E")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(canAfford && canFeed ? .black : .white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(
                            canAfford && canFeed ?
                            LinearGradient(
                                colors: [Color(red: 0.4, green: 0.9, blue: 0.4), Color(red: 0.13, green: 0.86, blue: 0.6)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ) :
                            LinearGradient(colors: [Color.gray.opacity(0.5)], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.black, lineWidth: 2)
                        )
                        .shadow(color: .black, radius: 0, x: 2, y: 2)
                }
                .buttonStyle(.plain)
                .disabled(isDisabled)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.black, lineWidth: 3)
        )
        .opacity(isDisabled ? 0.5 : 1.0)
    }
    
    private var foodInfoPopover: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Food Effects")
                .font(.system(size: 14, weight: .bold))
                .padding(.bottom, 4)
            
            Divider()
            
            HStack(spacing: 8) {
                // Fullness
                VStack(spacing: 2) {
                    Text("Fullness")
                        .font(.system(size: 10))
                        .foregroundColor(.gray.opacity(0.7))
                    Text("+\(item.defaultFullnessDelta)%")
                        .font(.system(size: 12, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.black, lineWidth: 1)
                )
                
                // Mood
                VStack(spacing: 2) {
                    Text("Mood")
                        .font(.system(size: 10))
                        .foregroundColor(.gray.opacity(0.7))
                    Text("+\(item.defaultMoodDelta)")
                        .font(.system(size: 12, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .background(Color.pink.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.black, lineWidth: 1)
                )
                
                // Buff
                VStack(spacing: 2) {
                    Text("Buff")
                        .font(.system(size: 10))
                        .foregroundColor(.gray.opacity(0.7))
                    Text("+\(Int(item.defaultBuffFrac * 100))%")
                        .font(.system(size: 12, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .background(Color.purple.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.black, lineWidth: 1)
                )
            }
        }
        .padding(12)
        .frame(width: 300)
    }
}

#Preview {
    FoodShopView()
        .environment(AppViewModel(modelContext: ModelContext(
            try! ModelContainer(for: Pet.self, DailyStats.self, Wallet.self, LedgerEntry.self)
        )))
}
