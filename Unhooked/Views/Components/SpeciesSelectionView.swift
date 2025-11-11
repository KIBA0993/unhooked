//
//  SpeciesSelectionView.swift
//  Unhooked
//
//  Species selection screen with pixel art pets
//

import SwiftUI

struct SpeciesSelectionView: View {
    let onSelect: (Species) -> Void
    
    @State private var hoveredSpecies: Species? = nil
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.4, green: 0.6, blue: 1.0),
                    Color(red: 0.73, green: 0.33, blue: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Title
                VStack(spacing: 12) {
                    Text("Choose Your Friend")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    
                    Text("Who will you care for?")
                        .font(.system(size: 18))
                        .foregroundStyle(.white.opacity(0.9))
                }
                
                // Species buttons with pixel pets
                HStack(spacing: 32) {
                    // Cat button
                    Button {
                        onSelect(.cat)
                    } label: {
                        speciesCard(species: .cat)
                    }
                    .buttonStyle(.plain)
                    
                    // Dog button
                    Button {
                        onSelect(.dog)
                    } label: {
                        speciesCard(species: .dog)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 20)
                
                Spacer()
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private func speciesCard(species: Species) -> some View {
        VStack(spacing: 20) {
            // Pixel pet container
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.white)
                    .frame(width: 140, height: 140)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.black, lineWidth: 3)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                
                PixelPet(
                    stage: 0,
                    mood: .happy,
                    isActive: true,
                    petType: species,
                    healthState: .healthy,
                    currentAnimation: .idle,
                    trickVariant: 0
                )
                .scaleEffect(2.2)
            }
            
            // Label
            VStack(spacing: 4) {
                Text(species == .cat ? "🐱" : "🐶")
                    .font(.system(size: 32))
                
                Text(species == .cat ? "Cat" : "Dog")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                )
        )
    }
}

#Preview {
    SpeciesSelectionView(onSelect: { _ in })
}

