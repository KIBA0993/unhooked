//
//  MemorialView.swift
//  Unhooked
//
//  Memorial gallery for deceased pets
//

import SwiftUI
import SwiftData

struct MemorialView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Memorial.createdAt, order: .reverse) private var memorials: [Memorial]
    
    var body: some View {
        NavigationStack {
            ZStack {
                if memorials.isEmpty {
                    emptyState
                } else {
                    memorialList
                }
            }
            .navigationTitle("Memories")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "cloud")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("No memories yet")
                .font(.title3)
                .fontWeight(.medium)
            
            Text("Your departed friends will be remembered here")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private var memorialList: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(memorials) { memorial in
                    MemorialCard(memorial: memorial)
                }
            }
            .padding()
        }
    }
}

struct MemorialCard: View {
    let memorial: Memorial
    
    var body: some View {
        VStack(spacing: 12) {
            // Pet representation
            RoundedRectangle(cornerRadius: 12)
                .fill(.gray.opacity(0.2))
                .frame(height: 150)
                .overlay {
                    VStack(spacing: 8) {
                        Text(memorial.petSpecies == .cat ? "🐱" : "🐶")
                            .font(.system(size: 50))
                            .grayscale(1.0)
                            .opacity(0.5)
                        
                        Image(systemName: "cloud.fill")
                            .font(.title3)
                            .foregroundStyle(.gray)
                    }
                }
            
            // Details
            VStack(spacing: 4) {
                if let name = memorial.petName {
                    Text(name)
                        .font(.headline)
                } else {
                    Text("\(memorial.petSpecies.rawValue.capitalized)")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                
                Text("Stage \(memorial.petStage)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(memorial.deathDate, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Memorial for \(memorial.petSpecies.rawValue) at stage \(memorial.petStage)")
    }
}

#Preview {
    MemorialView()
        .modelContainer(for: Memorial.self, inMemory: true)
}

