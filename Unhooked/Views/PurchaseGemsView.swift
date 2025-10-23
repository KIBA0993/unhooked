//
//  PurchaseGemsView.swift
//  Unhooked
//
//  IAP gem purchase flow
//

import SwiftUI
import SwiftData
import StoreKit

struct PurchaseGemsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) private var viewModel
    
    var body: some View {
        List {
            Section {
                ForEach(viewModel.iapService.gemProducts, id: \.id) { product in
                    GemProductRow(product: product) {
                        Task {
                            await viewModel.purchaseGems(productId: product.id)
                        }
                    }
                }
            } header: {
                Text("Gem Packages")
            } footer: {
                Text("Gems can be used for recovery actions and premium cosmetics. They never provide gameplay advantages.")
                    .font(.caption)
            }
            
            Section {
                Link("Restore Purchases", destination: URL(string: "restore://purchases")!)
                    .foregroundStyle(.blue)
            }
        }
        .navigationTitle("Buy Gems")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

struct GemProductRow: View {
    let product: Product
    let onPurchase: () -> Void
    
    var body: some View {
        Button {
            onPurchase()
        } label: {
            HStack {
                // Icon
                Image(systemName: "diamond.fill")
                    .font(.title2)
                    .foregroundStyle(.cyan)
                    .frame(width: 44)
                
                // Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.displayName)
                        .font(.headline)
                    
                    if !product.description.isEmpty {
                        Text(product.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // Price
                Text(product.displayPrice)
                    .font(.headline)
                    .foregroundStyle(.blue)
            }
            .padding(.vertical, 4)
        }
        .foregroundStyle(.primary)
    }
}

#Preview {
    NavigationStack {
        PurchaseGemsView()
            .environment(AppViewModel(modelContext: ModelContext(
                try! ModelContainer(for: Pet.self)
            )))
    }
}

