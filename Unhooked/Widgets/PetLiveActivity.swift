//
//  PetLiveActivity.swift
//  Unhooked
//
//  Dynamic Island - Pet ABOVE island using EXPANDED state trick
//  The expanded state auto-shows on iPhone 14 Pro+ and allows overflow
//

import SwiftUI
import ActivityKit
import WidgetKit

// MARK: - Pixel Pet Sprite

struct PixelPetSprite: View {
    let species: String
    let scale: CGFloat
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(getPixels().indices, id: \.self) { rowIndex in
                HStack(spacing: 0) {
                    ForEach(getPixels()[rowIndex].indices, id: \.self) { colIndex in
                        Rectangle()
                            .fill(getColor(for: getPixels()[rowIndex][colIndex]))
                            .frame(width: scale, height: scale)
                    }
                }
            }
        }
    }
    
    private func getPixels() -> [[String]] {
        if species == "cat" {
            return [
                [".", "K", ".", ".", ".", ".", ".", ".", "K", "."],
                [".", "K", "K", ".", ".", ".", ".", "K", "K", "."],
                [".", "K", "O", "K", "K", "K", "K", "O", "K", "."],
                [".", "K", "O", "O", "O", "O", "O", "O", "K", "."],
                [".", "K", "O", "G", "O", "O", "G", "O", "K", "."],
                [".", "K", "O", "g", "O", "O", "g", "O", "K", "."],
                [".", "K", "O", "O", "P", "P", "O", "O", "K", "."],
                [".", ".", "K", "K", "K", "K", "K", "K", ".", "."],
            ]
        } else {
            return [
                ["E", "E", ".", ".", ".", ".", ".", ".", "E", "E"],
                ["E", "O", "E", ".", ".", ".", ".", "E", "O", "E"],
                ["E", "E", "K", "K", "K", "K", "K", "K", "E", "E"],
                [".", "K", "C", "C", "C", "C", "C", "C", "K", "."],
                [".", "K", "C", "G", "C", "C", "G", "C", "K", "."],
                [".", "K", "C", "g", "C", "C", "g", "C", "K", "."],
                [".", "K", "C", "C", "N", "N", "C", "C", "K", "."],
                [".", ".", "K", "K", "K", "K", "K", "K", ".", "."],
            ]
        }
    }
    
    private func getColor(for pixel: String) -> Color {
        switch pixel {
        case ".": return .clear
        case "K": return .black
        case "O": return Color(red: 1.0, green: 0.65, blue: 0.0)
        case "G": return Color(red: 0.56, green: 0.93, blue: 0.56)
        case "g": return Color(red: 0.13, green: 0.55, blue: 0.13)
        case "P": return Color(red: 1.0, green: 0.71, blue: 0.76)
        case "C": return Color(red: 1.0, green: 0.89, blue: 0.77)
        case "E": return Color(red: 0.55, green: 0.27, blue: 0.07)
        case "N": return Color(red: 0.2, green: 0.2, blue: 0.2)
        default: return .clear
        }
    }
}

// MARK: - Live Activity

@available(iOS 16.2, *)
struct PetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PetActivityAttributes.self) { context in
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // ================================================
                // EXPANDED STATE - This is where pet appears ABOVE
                // The expanded state auto-shows on iPhone 14 Pro+
                // ================================================
                
                DynamicIslandExpandedRegion(.leading) {
                    // Pet ABOVE the island using ZStack + negative offset
                    ZStack(alignment: .topLeading) {
                        // Invisible container extending beyond visible region
                        Color.clear
                            .frame(width: 120, height: 140)
                        
                        // Pet with negative offset pushes ABOVE the black area
                        VStack(spacing: 0) {
                            PixelPetSprite(species: context.state.petSpecies, scale: 5)
                                .offset(y: -65)  // 🎯 THE KEY: Negative offset!
                                .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 3)
                            
                            Spacer()
                        }
                        .frame(height: 140)
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                            Text("\(context.state.energyBalance)")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        Text("\(context.state.hunger)% Full")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                DynamicIslandExpandedRegion(.center) {
                    // Can be empty or show pet name
                    Color.clear
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 12) {
                        Link(destination: URL(string: "unhooked://action/feed")!) {
                            actionButton(icon: "🍎", label: "Feed")
                        }
                        Link(destination: URL(string: "unhooked://action/play")!) {
                            actionButton(icon: "🎾", label: "Play")
                        }
                        Link(destination: URL(string: "unhooked://action/pet")!) {
                            actionButton(icon: "✋", label: "Pet")
                        }
                    }
                    .padding(.horizontal)
                }
                
            } compactLeading: {
                // Simple icon when collapsed - prompts user to expand
                PixelPetSprite(species: context.state.petSpecies, scale: 2.5)
                    .frame(width: 28, height: 28)
                
            } compactTrailing: {
                HStack(spacing: 2) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                    Text("\(context.state.energyBalance)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                
            } minimal: {
                PixelPetSprite(species: context.state.petSpecies, scale: 2)
                    .frame(width: 22, height: 22)
            }
        }
    }
    
    // MARK: - Action Button
    @ViewBuilder
    func actionButton(icon: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(icon)
                .font(.system(size: 20))
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Lock Screen View
    private func lockScreenView(context: ActivityViewContext<PetActivityAttributes>) -> some View {
        HStack(spacing: 12) {
            PixelPetSprite(species: context.state.petSpecies, scale: 5)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(context.state.petName) • Stage \(context.state.petStage)")
                    .font(.caption).fontWeight(.medium)
                HStack(spacing: 12) {
                    HStack(spacing: 3) {
                        Image(systemName: "heart.fill").foregroundStyle(.pink)
                        Text("\(context.state.hunger)%")
                    }
                    HStack(spacing: 3) {
                        Image(systemName: "bolt.fill").foregroundStyle(.yellow)
                        Text("\(context.state.energyBalance)")
                    }
                }
                .font(.caption2)
            }
            
            Spacer()
            
            let healthColor: Color = context.state.healthState == "healthy" ? .green : .orange
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                Text(context.state.healthState.capitalized)
            }
            .font(.caption2)
            .foregroundStyle(healthColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(healthColor.opacity(0.2), in: Capsule())
        }
        .padding()
        .background(Color(.systemBackground))
    }
}
