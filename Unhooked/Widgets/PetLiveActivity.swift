//
//  PetLiveActivity.swift
//  Unhooked
//
//  Dynamic Island Live Activity with Pixel Pet
//

import SwiftUI
import ActivityKit
import WidgetKit

// MARK: - Dynamic Island Pixel Pet (Peeking)

struct DynamicIslandPixelPet: View {
    let species: String
    let stage: Int
    let size: CGFloat
    let peeking: Bool  // If true, only show head peeking from edge
    
    var body: some View {
        if peeking {
            // Peeking pet - offset to show just part of it
            PixelPetHead(species: species, scale: size / 10)
                .offset(y: -size * 0.2)  // Peek from top
        } else {
            PixelPetHead(species: species, scale: size / 10)
        }
    }
}

// Simplified pixel pet head for Dynamic Island
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
            // Cute cat head with ears - 10x8 pixels
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
            // Cute dog head with floppy ears - 10x8 pixels
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
        case "W": return .white
        case "O": return Color(red: 1.0, green: 0.65, blue: 0.0) // Orange (cat)
        case "G": return Color(red: 0.56, green: 0.93, blue: 0.56) // Light green (eyes)
        case "g": return Color(red: 0.13, green: 0.55, blue: 0.13) // Dark green (pupils)
        case "P": return Color(red: 1.0, green: 0.71, blue: 0.76) // Pink (nose/mouth)
        case "C": return Color(red: 1.0, green: 0.89, blue: 0.77) // Cream (dog)
        case "E": return Color(red: 0.55, green: 0.27, blue: 0.07) // Brown (ears)
        case "N": return Color(red: 0.2, green: 0.2, blue: 0.2) // Dark (nose)
        default: return .clear
        }
    }
}

// MARK: - Live Activity Widget

@available(iOS 16.2, *)
struct PetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PetActivityAttributes.self) { context in
            // Lock screen/banner UI
            liveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        DynamicIslandPixelPet(
                            species: context.state.petSpecies,
                            stage: context.state.petStage,
                            size: 40,
                            peeking: false
                        )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(context.state.petSpecies.capitalized)
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
                            Text("\(context.state.fullness)%")
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
                    HStack(spacing: 16) {
                        statBadge(
                            icon: "heart.fill",
                            value: "\(context.state.fullness)%",
                            color: .pink
                        )
                        
                        statBadge(
                            icon: "bolt.fill",
                            value: "\(context.state.energyBalance)",
                            color: .yellow
                        )
                        
                        Spacer()
                        
                        healthBadge(context: context)
                    }
                }
            } compactLeading: {
                // Compact leading: Show pixel pet head peeking
                DynamicIslandPixelPet(
                    species: context.state.petSpecies,
                    stage: context.state.petStage,
                    size: 24,
                    peeking: false
                )
                .padding(.leading, 2)
            } compactTrailing: {
                // Compact trailing: Energy count
                HStack(spacing: 2) {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(.yellow)
                    Text("\(context.state.energyBalance)")
                        .monospacedDigit()
                }
                .font(.caption2)
            } minimal: {
                // Minimal: Just the pixel pet peeking
                DynamicIslandPixelPet(
                    species: context.state.petSpecies,
                    stage: context.state.petStage,
                    size: 20,
                    peeking: true
                )
            }
        }
    }
    
    // MARK: - Lock Screen View
    
    private func liveActivityView(context: ActivityViewContext<PetActivityAttributes>) -> some View {
        HStack(spacing: 12) {
            // Pixel pet on lock screen
            DynamicIslandPixelPet(
                species: context.state.petSpecies,
                stage: context.state.petStage,
                size: 40,
                peeking: false
            )
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(context.state.petSpecies.capitalized) • Stage \(context.state.petStage)")
                    .font(.caption)
                    .fontWeight(.medium)
                
                HStack(spacing: 12) {
                    HStack(spacing: 3) {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.pink)
                        Text("\(context.state.fullness)%")
                    }
                    
                    HStack(spacing: 3) {
                        Image(systemName: "bolt.fill")
                            .foregroundStyle(.yellow)
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
    
    // MARK: - Helpers
    
    private func statBadge(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(value)
                .monospacedDigit()
        }
        .font(.caption2)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.2), in: Capsule())
    }
    
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

