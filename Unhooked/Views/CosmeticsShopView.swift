//
//  CosmeticsShopView.swift
//  Unhooked
//
//  Cosmetics store with dual currency
//

import SwiftUI
import SwiftData

struct CosmeticsShopView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) private var viewModel
    @Environment(\.modelContext) private var modelContext
    
    @State private var availableItems: [CosmeticItem] = []
    @State private var ownedItemIds: Set<String> = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                if isLoading {
                    ProgressView()
                } else {
                    cosmeticsList
                }
            }
            .navigationTitle("Cosmetics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "bolt.fill")
                                .foregroundStyle(.yellow)
                            Text("\(viewModel.energyBalance)")
                                .monospacedDigit()
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "diamond.fill")
                                .foregroundStyle(.cyan)
                            Text("\(viewModel.gemsBalance)")
                                .monospacedDigit()
                        }
                    }
                    .font(.subheadline)
                }
            }
            .task {
                await loadItems()
            }
        }
    }
    
    private var cosmeticsList: some View {
        List {
            ForEach(CosmeticCategory.allCases, id: \.self) { category in
                let items = availableItems.filter { $0.category == category }
                
                if !items.isEmpty {
                    Section(category.displayName) {
                        ForEach(items, id: \.itemId) { item in
                            CosmeticItemRow(
                                item: item,
                                isOwned: ownedItemIds.contains(item.itemId),
                                energyBalance: viewModel.energyBalance,
                                gemsBalance: viewModel.gemsBalance
                            )
                        }
                    }
                }
            }
        }
    }
    
    private func loadItems() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let service = CosmeticsService(
                modelContext: modelContext,
                economyService: EconomyService(modelContext: modelContext)
            )
            
            availableItems = try service.getAvailableCosmetics()
            
            // Load owned items (simplified - using UUID as userId)
            let userId = UUID()  // Would get from auth
            let owned = try service.getOwnedCosmetics(userId: userId)
            ownedItemIds = Set(owned.map { $0.itemId })
        } catch {
            print("❌ Failed to load cosmetics: \(error)")
        }
    }
}

// MARK: - Cosmetic Item Row

struct CosmeticItemRow: View {
    let item: CosmeticItem
    let isOwned: Bool
    let energyBalance: Int
    let gemsBalance: Int
    
    var body: some View {
        HStack(spacing: 12) {
            // Preview
            RoundedRectangle(cornerRadius: 8)
                .fill(.purple.opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.purple)
                }
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                
                Text(item.category.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                // Pricing
                HStack(spacing: 8) {
                    if let energyPrice = item.priceEnergy {
                        PriceTag(
                            icon: "bolt.fill",
                            price: energyPrice,
                            color: .yellow,
                            canAfford: energyBalance >= energyPrice
                        )
                    }
                    
                    if let gemsPrice = item.priceGems {
                        PriceTag(
                            icon: "diamond.fill",
                            price: gemsPrice,
                            color: .cyan,
                            canAfford: gemsBalance >= gemsPrice
                        )
                    }
                }
            }
            
            Spacer()
            
            // Status
            if isOwned {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title3)
            }
        }
        .padding(.vertical, 4)
        .opacity(isOwned ? 0.5 : 1.0)
    }
}

struct PriceTag: View {
    let icon: String
    let price: Int
    let color: Color
    let canAfford: Bool
    
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text("\(price)")
                .monospacedDigit()
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(canAfford ? color.opacity(0.2) : Color.gray.opacity(0.2), in: Capsule())
        .foregroundStyle(canAfford ? .primary : .secondary)
    }
}

// MARK: - Category Extension

extension CosmeticCategory {
    static var allCases: [CosmeticCategory] {
        [.outfit, .roomDecor, .palette, .accessory]
    }
    
    var displayName: String {
        switch self {
        case .outfit: return "Outfits"
        case .roomDecor: return "Room Decor"
        case .palette: return "Color Palettes"
        case .accessory: return "Accessories"
        }
    }
}

#Preview {
    CosmeticsShopView()
        .environment(AppViewModel(modelContext: ModelContext(
            try! ModelContainer(for: CosmeticItem.self, OwnedCosmetic.self)
        )))
}

