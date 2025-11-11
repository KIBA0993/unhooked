//
//  SpeciesSelectionView.swift
//  Unhooked
//
//  Species selection screen for choosing cat or dog
//

import SwiftUI

struct SpeciesSelectionView: View {
    let onSelect: (Species) -> Void
    
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
                    
                    Text("Who will you care for?")
                        .font(.system(size: 18))
                        .foregroundStyle(.white.opacity(0.9))
                }
                
                // Species buttons
                HStack(spacing: 24) {
                    // Cat button
                    Button {
                        onSelect(.cat)
                    } label: {
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(.white)
                                    .frame(width: 120, height: 120)
                                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
                                
                                Text("🐱")
                                    .font(.system(size: 60))
                            }
                            
                            Text("Cat")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    // Dog button
                    Button {
                        onSelect(.dog)
                    } label: {
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(.white)
                                    .frame(width: 120, height: 120)
                                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
                                
                                Text("🐶")
                                    .font(.system(size: 60))
                            }
                            
                            Text("Dog")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 20)
                
                Text("You can change this later")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.7))
                
                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    SpeciesSelectionView(onSelect: { _ in })
}

