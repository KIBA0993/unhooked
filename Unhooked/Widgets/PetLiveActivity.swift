//
//  PetLiveActivity.swift
//  Unhooked
//
//  Dynamic Island Live Activity with Pixel Pet
//

import SwiftUI
import ActivityKit
import WidgetKit

// MARK: - Pixel Pet Head (for Dynamic Island)

struct PixelPetHead: View {
    let species: String
    let scale: CGFloat
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(getHeadPixels().indices, id: \.self) { rowIndex in
                HStack(spacing: 0) {
                    ForEach(getHeadPixels()[rowIndex].indices, id: \.self) { colIndex in
                        let pixel = getHeadPixels()[rowIndex][colIndex]
                        Rectangle()
                            .fill(getColor(for: pixel))
                            .frame(width: scale, height: scale)
                    }
                }
            }
        }
    }
    
    private func getHeadPixels() -> [[String]] {
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

// MARK: - Live Activity Widget

@available(iOS 16.2, *)
struct PetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PetActivityAttributes.self) { context in
            // Lock screen banner
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // EXPANDED STATE
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        PixelPetHead(species: context.state.petSpecies, scale: 4)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(context.state.petName)
                                .font(.caption)
                                .fontWeight(.semibold)
                            Text("Stage \(context.state.petStage)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 3) {
                            Image(systemName: "heart.fill")
                                .foregroundStyle(.pink)
                            Text("\(context.state.hunger)%")
                        }
                        HStack(spacing: 3) {
                            Image(systemName: "bolt.fill")
                                .foregroundStyle(.yellow)
                            Text("\(context.state.energyBalance)")
                        }
                    }
                    .font(.caption2)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    // ACTION BUTTONS
                    HStack(spacing: 12) {
                        Link(destination: URL(string: "unhooked://action/feed")!) {
                            VStack(spacing: 2) {
                                Text("🍎").font(.system(size: 16))
                                Text("Feed").font(.system(size: 9))
                            }
                            .frame(width: 44, height: 36)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        Link(destination: URL(string: "unhooked://action/play")!) {
                            VStack(spacing: 2) {
                                Text("🎾").font(.system(size: 16))
                                Text("Play").font(.system(size: 9))
                            }
                            .frame(width: 44, height: 36)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        Link(destination: URL(string: "unhooked://action/pet")!) {
                            VStack(spacing: 2) {
                                Text("✋").font(.system(size: 16))
                                Text("Pet").font(.system(size: 9))
                            }
                            .frame(width: 44, height: 36)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        Spacer()
                        
                        healthBadge(context: context)
                    }
                }
            } compactLeading: {
                // COMPACT: Pet peeking above - use frame + offset
                ZStack {
                    PixelPetHead(species: context.state.petSpecies, scale: 2.5)
                        .offset(y: -8) // Push up to peek above
                }
                .frame(width: 28, height: 28)
                .clipped()
            } compactTrailing: {
                HStack(spacing: 2) {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(.yellow)
                    Text("\(context.state.energyBalance)")
                        .monospacedDigit()
                }
                .font(.caption2)
            } minimal: {
                // MINIMAL: Pet peeking
                ZStack {
                    PixelPetHead(species: context.state.petSpecies, scale: 2)
                        .offset(y: -6)
                }
                .frame(width: 22, height: 22)
                .clipped()
            }
        }
    }
    
    // MARK: - Lock Screen View
    
    private func lockScreenView(context: ActivityViewContext<PetActivityAttributes>) -> some View {
        HStack(spacing: 12) {
            PixelPetHead(species: context.state.petSpecies, scale: 5)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(context.state.petName) • Stage \(context.state.petStage)")
                    .font(.caption)
                    .fontWeight(.medium)
                
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
            
            healthBadge(context: context)
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Health Badge
    
    private func healthBadge(context: ActivityViewContext<PetActivityAttributes>) -> some View {
        let state = context.state.healthState
        let color: Color = state == "healthy" ? .green : (state == "sick" ? .orange : .gray)
        let icon = state == "healthy" ? "checkmark.circle.fill" : (state == "sick" ? "thermometer.medium" : "cloud.fill")
        
        return HStack(spacing: 4) {
            Image(systemName: icon)
            Text(state.capitalized)
        }
        .font(.caption2)
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.2), in: Capsule())
    }
}
