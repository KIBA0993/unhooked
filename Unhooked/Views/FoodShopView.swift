//
//  FoodShopView.swift
//  Unhooked
//
//  Food shop with species filtering
//

import SwiftUI
import SwiftData

struct FoodShopView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) private var viewModel
    @Environment(\.modelContext) private var modelContext
    
    @State private var availableItems: [FoodCatalogItem] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                if isLoading {
                    ProgressView()
                } else {
                    foodList
                }
            }
            .navigationTitle("Food Shop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .foregroundStyle(.yellow)
                        Text("\(viewModel.energyBalance)")
                            .monospacedDigit()
                    }
                    .font(.subheadline)
                }
            }
            .task {
                await loadItems()
            }
        }
    }
    
    private var foodList: some View {
        List {
            if let pet = viewModel.currentPet {
                Section {
                    ForEach(availableItems, id: \.itemId) { item in
                        FoodItemRow(
                            item: item,
                            pet: pet,
                            canAfford: viewModel.energyBalance >= item.priceEnergy,
                            onPurchase: {
                                Task {
                                    await viewModel.feedPet(foodItemId: item.itemId)
                                    await loadItems()  // Refresh
                                }
                            }
                        )
                    }
                } header: {
                    Text("Available for \(pet.species.rawValue.capitalized)")
                } footer: {
                    if pet.isSick {
                        Text("Feeding while sick has a reduced buff cap (+0.10)")
                            .font(.caption)
                    } else if pet.isFragile {
                        Text("Fragile state: buff cap limited to +0.15")
                            .font(.caption)
                    }
                }
            }
        }
    }
    
    private func loadItems() async {
        isLoading = true
        defer { isLoading = false }
        
        guard let pet = viewModel.currentPet else { return }
        
        do {
            let foodService = FoodService(
                modelContext: modelContext,
                economyService: EconomyService(modelContext: modelContext)
            )
            availableItems = try foodService.getAvailableFoodItems(for: pet.species)
        } catch {
            print("❌ Failed to load food items: \(error)")
        }
    }
}

// MARK: - Food Item Row

struct FoodItemRow: View {
    let item: FoodCatalogItem
    let pet: Pet
    let canAfford: Bool
    let onPurchase: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Circle()
                .fill(.green.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay {
                    Image(systemName: "fork.knife")
                        .foregroundStyle(.green)
                }
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                
                let stats = item.effectiveStats(for: pet.species)
                HStack(spacing: 12) {
                    StatLabel(icon: "plus", value: "\(stats.fullness)%", color: .pink)
                    StatLabel(icon: "face.smiling", value: "+\(stats.mood)", color: .yellow)
                    if stats.buff > 0 {
                        StatLabel(icon: "arrow.up", value: "+\(String(format: "%.2f", stats.buff))", color: .blue)
                    }
                }
                .font(.caption)
            }
            
            Spacer()
            
            // Price & Buy
            Button {
                onPurchase()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(.yellow)
                    Text("\(item.priceEnergy)")
                        .monospacedDigit()
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(canAfford ? Color.green : Color.gray, in: Capsule())
                .foregroundStyle(.white)
            }
            .disabled(!canAfford || !pet.canFeed)
        }
        .padding(.vertical, 4)
        .opacity(canAfford && pet.canFeed ? 1.0 : 0.5)
    }
}

struct StatLabel: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(value)
        }
    }
}

#Preview {
    FoodShopView()
        .environment(AppViewModel(modelContext: ModelContext(
            try! ModelContainer(for: Pet.self, FoodCatalogItem.self)
        )))
}


