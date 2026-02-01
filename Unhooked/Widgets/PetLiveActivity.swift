//
//  PetLiveActivity.swift
//  Unhooked
//
//  Dynamic Island Live Activity - Pet sits ON TOP of the island
//

import SwiftUI
import ActivityKit
import WidgetKit

// MARK: - Pixel Pet Head (for Dynamic Island)

struct PixelPetHead: View {
    let species: String
    let scale: CGFloat
    let mood: String  // "happy", "hungry", "sleeping", "playing", "sick"
    
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
        // Adjust eyes based on mood
        if species == "cat" {
            switch mood {
            case "sleeping":
                return catSleeping()
            case "hungry":
                return catHungry()
            case "sick":
                return catSick()
            default:
                return catHappy()
            }
        } else {
            switch mood {
            case "sleeping":
                return dogSleeping()
            case "hungry":
                return dogHungry()
            case "sick":
                return dogSick()
            default:
                return dogHappy()
            }
        }
    }
    
    // CAT SPRITES
    private func catHappy() -> [[String]] {
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
    }
    
    private func catSleeping() -> [[String]] {
        return [
            [".", "K", ".", ".", ".", ".", ".", ".", "K", "."],
            [".", "K", "K", ".", ".", ".", ".", "K", "K", "."],
            [".", "K", "O", "K", "K", "K", "K", "O", "K", "."],
            [".", "K", "O", "O", "O", "O", "O", "O", "K", "."],
            [".", "K", "O", "K", "K", "O", "K", "K", "K", "."],  // Closed eyes
            [".", "K", "O", "O", "O", "O", "O", "O", "K", "."],
            [".", "K", "O", "O", "P", "P", "O", "O", "K", "."],
            [".", ".", "K", "K", "K", "K", "K", "K", ".", "."],
        ]
    }
    
    private func catHungry() -> [[String]] {
        return [
            [".", "K", ".", ".", ".", ".", ".", ".", "K", "."],
            [".", "K", "K", ".", ".", ".", ".", "K", "K", "."],
            [".", "K", "O", "K", "K", "K", "K", "O", "K", "."],
            [".", "K", "O", "O", "O", "O", "O", "O", "K", "."],
            [".", "K", "O", "G", "O", "O", "G", "O", "K", "."],
            [".", "K", "O", "g", "O", "O", "g", "O", "K", "."],
            [".", "K", "O", "K", "K", "K", "K", "O", "K", "."],  // Open mouth
            [".", ".", "K", "K", "R", "R", "K", "K", ".", "."],
        ]
    }
    
    private func catSick() -> [[String]] {
        return [
            [".", "K", ".", ".", ".", ".", ".", ".", "K", "."],
            [".", "K", "K", ".", ".", ".", ".", "K", "K", "."],
            [".", "K", "O", "K", "K", "K", "K", "O", "K", "."],
            [".", "K", "O", "O", "O", "O", "O", "O", "K", "."],
            [".", "K", "O", "X", "O", "O", "X", "O", "K", "."],  // X eyes
            [".", "K", "O", "O", "O", "O", "O", "O", "K", "."],
            [".", "K", "O", "O", "~", "~", "O", "O", "K", "."],  // Wavy mouth
            [".", ".", "K", "K", "K", "K", "K", "K", ".", "."],
        ]
    }
    
    // DOG SPRITES
    private func dogHappy() -> [[String]] {
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
    
    private func dogSleeping() -> [[String]] {
        return [
            ["E", "E", ".", ".", ".", ".", ".", ".", "E", "E"],
            ["E", "O", "E", ".", ".", ".", ".", "E", "O", "E"],
            ["E", "E", "K", "K", "K", "K", "K", "K", "E", "E"],
            [".", "K", "C", "C", "C", "C", "C", "C", "K", "."],
            [".", "K", "C", "K", "K", "C", "K", "K", "K", "."],  // Closed eyes
            [".", "K", "C", "C", "C", "C", "C", "C", "K", "."],
            [".", "K", "C", "C", "N", "N", "C", "C", "K", "."],
            [".", ".", "K", "K", "K", "K", "K", "K", ".", "."],
        ]
    }
    
    private func dogHungry() -> [[String]] {
        return [
            ["E", "E", ".", ".", ".", ".", ".", ".", "E", "E"],
            ["E", "O", "E", ".", ".", ".", ".", "E", "O", "E"],
            ["E", "E", "K", "K", "K", "K", "K", "K", "E", "E"],
            [".", "K", "C", "C", "C", "C", "C", "C", "K", "."],
            [".", "K", "C", "G", "C", "C", "G", "C", "K", "."],
            [".", "K", "C", "g", "C", "C", "g", "C", "K", "."],
            [".", "K", "C", "K", "K", "K", "K", "C", "K", "."],  // Open mouth
            [".", ".", "K", "K", "R", "R", "K", "K", ".", "."],
        ]
    }
    
    private func dogSick() -> [[String]] {
        return [
            ["E", "E", ".", ".", ".", ".", ".", ".", "E", "E"],
            ["E", "O", "E", ".", ".", ".", ".", "E", "O", "E"],
            ["E", "E", "K", "K", "K", "K", "K", "K", "E", "E"],
            [".", "K", "C", "C", "C", "C", "C", "C", "K", "."],
            [".", "K", "C", "X", "C", "C", "X", "C", "K", "."],  // X eyes
            [".", "K", "C", "C", "C", "C", "C", "C", "K", "."],
            [".", "K", "C", "C", "~", "~", "C", "C", "K", "."],  // Wavy mouth
            [".", ".", "K", "K", "K", "K", "K", "K", ".", "."],
        ]
    }
    
    private func getColor(for pixel: String) -> Color {
        switch pixel {
        case ".": return .clear
        case "K": return .black
        case "O": return Color(red: 1.0, green: 0.65, blue: 0.0)  // Orange
        case "G": return Color(red: 0.56, green: 0.93, blue: 0.56)  // Light green
        case "g": return Color(red: 0.13, green: 0.55, blue: 0.13)  // Dark green
        case "P": return Color(red: 1.0, green: 0.71, blue: 0.76)  // Pink
        case "C": return Color(red: 1.0, green: 0.89, blue: 0.77)  // Cream
        case "E": return Color(red: 0.55, green: 0.27, blue: 0.07)  // Brown
        case "N": return Color(red: 0.2, green: 0.2, blue: 0.2)  // Dark nose
        case "R": return Color(red: 0.9, green: 0.3, blue: 0.3)  // Red tongue
        case "X": return Color(red: 0.4, green: 0.4, blue: 0.4)  // X eyes
        case "~": return Color(red: 0.6, green: 0.6, blue: 0.6)  // Wavy mouth
        default: return .clear
        }
    }
}

// MARK: - Status Dot
struct StatusDot: View {
    let color: Color
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 6, height: 6)
    }
}

// MARK: - Live Activity Widget

@available(iOS 16.2, *)
struct PetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PetActivityAttributes.self) { context in
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // EXPANDED STATE
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        PixelPetHead(
                            species: context.state.petSpecies,
                            scale: 4,
                            mood: getMood(context: context)
                        )
                        
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
                // PET SITTING ON TOP OF ISLAND
                // Frame is larger to contain the offset without clipping
                ZStack(alignment: .bottom) {
                    // Pet sprite with negative offset to sit ABOVE the island
                    PixelPetHead(
                        species: context.state.petSpecies,
                        scale: 2.8,
                        mood: getMood(context: context)
                    )
                    .offset(y: -18)  // Push UP to sit on top of island
                }
                .frame(width: 32, height: 44)  // Tall frame to contain offset
                .clipped()
                
            } compactTrailing: {
                // Status inside the pill
                HStack(spacing: 3) {
                    StatusDot(color: getStatusColor(context: context))
                    Text("\(context.state.energyBalance)")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                }
            } minimal: {
                // MINIMAL: Pet peeking
                ZStack(alignment: .bottom) {
                    PixelPetHead(
                        species: context.state.petSpecies,
                        scale: 2,
                        mood: getMood(context: context)
                    )
                    .offset(y: -12)
                }
                .frame(width: 24, height: 32)
                .clipped()
            }
        }
    }
    
    // MARK: - Mood based on state
    
    private func getMood(context: ActivityViewContext<PetActivityAttributes>) -> String {
        if context.state.healthState == "sick" { return "sick" }
        if context.state.isSleeping { return "sleeping" }
        if context.state.hunger < 30 { return "hungry" }
        if context.state.currentAnimation == "playing" { return "happy" }
        return "happy"
    }
    
    private func getStatusColor(context: ActivityViewContext<PetActivityAttributes>) -> Color {
        if context.state.isCritical { return .red }
        if context.state.needsAttention { return .orange }
        if context.state.isSleeping { return .cyan }
        return .green
    }
    
    // MARK: - Lock Screen View
    
    private func lockScreenView(context: ActivityViewContext<PetActivityAttributes>) -> some View {
        HStack(spacing: 12) {
            PixelPetHead(
                species: context.state.petSpecies,
                scale: 5,
                mood: getMood(context: context)
            )
            
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
