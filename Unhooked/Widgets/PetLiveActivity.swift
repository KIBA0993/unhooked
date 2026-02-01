//
//  PetLiveActivity.swift
//  Unhooked
//
//  Dynamic Island Live Activity - Pixel Pet
//

import SwiftUI
import ActivityKit
import WidgetKit
import AppIntents

// MARK: - Pixel Pet Sprite

struct PixelPetSprite: View {
    let species: String
    let scale: CGFloat
    let isEating: Bool
    let isPlaying: Bool
    let isPetting: Bool
    
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
            return isEating ? catEating() : catNormal()
        } else {
            return isEating ? dogEating() : dogNormal()
        }
    }
    
    private func catNormal() -> [[String]] {
        return [
            [".", "K", ".", ".", ".", ".", ".", ".", "K", "."],
            [".", "K", "K", "K", "K", "K", "K", "K", "K", "."],
            [".", "K", "O", "O", "O", "O", "O", "O", "K", "."],
            [".", "K", "O", "G", "O", "O", "G", "O", "K", "."],
            [".", "K", "O", "g", "O", "O", "g", "O", "K", "."],
            [".", "K", "O", "O", "P", "P", "O", "O", "K", "."],
            [".", ".", "K", "K", "K", "K", "K", "K", ".", "."],
            [".", ".", ".", "K", ".", ".", "K", ".", ".", "."],
        ]
    }
    
    private func catEating() -> [[String]] {
        return [
            [".", "K", ".", ".", ".", ".", ".", ".", "K", "."],
            [".", "K", "K", "K", "K", "K", "K", "K", "K", "."],
            [".", "K", "O", "O", "O", "O", "O", "O", "K", "."],
            [".", "K", "O", "K", "O", "O", "K", "O", "K", "."],
            [".", "K", "O", "O", "O", "O", "O", "O", "K", "."],
            [".", "K", "O", "K", "R", "R", "K", "O", "K", "."],
            [".", ".", "K", "K", "K", "K", "K", "K", ".", "."],
            [".", ".", ".", "K", ".", ".", "K", ".", ".", "."],
        ]
    }
    
    private func dogNormal() -> [[String]] {
        return [
            ["E", "E", ".", ".", ".", ".", ".", ".", "E", "E"],
            ["E", "B", "E", "K", "K", "K", "K", "E", "B", "E"],
            [".", "K", "C", "C", "C", "C", "C", "C", "K", "."],
            [".", "K", "C", "G", "C", "C", "G", "C", "K", "."],
            [".", "K", "C", "g", "C", "C", "g", "C", "K", "."],
            [".", "K", "C", "C", "N", "N", "C", "C", "K", "."],
            [".", ".", "K", "K", "K", "K", "K", "K", ".", "."],
            [".", ".", ".", "K", ".", ".", "K", ".", ".", "."],
        ]
    }
    
    private func dogEating() -> [[String]] {
        return [
            ["E", "E", ".", ".", ".", ".", ".", ".", "E", "E"],
            ["E", "B", "E", "K", "K", "K", "K", "E", "B", "E"],
            [".", "K", "C", "C", "C", "C", "C", "C", "K", "."],
            [".", "K", "C", "K", "C", "C", "K", "C", "K", "."],
            [".", "K", "C", "C", "C", "C", "C", "C", "K", "."],
            [".", "K", "C", "K", "R", "R", "K", "C", "K", "."],
            [".", ".", "K", "K", "K", "K", "K", "K", ".", "."],
            [".", ".", ".", "K", ".", ".", "K", ".", ".", "."],
        ]
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
        case "B": return Color(red: 0.4, green: 0.2, blue: 0.1)
        case "N": return Color(red: 0.2, green: 0.2, blue: 0.2)
        case "R": return Color(red: 0.9, green: 0.3, blue: 0.3)
        default: return .clear
        }
    }
}

// MARK: - Status Dot
struct StatusDot: View {
    let status: String
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
    }
    
    private var color: Color {
        switch status {
        case "red": return .red
        case "yellow": return .yellow
        case "blue": return .cyan
        default: return .green
        }
    }
}

// MARK: - Status Bar
struct StatusBar: View {
    let icon: String
    let value: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Text(icon).font(.system(size: 10))
            
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 50, height: 6)
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: 50 * CGFloat(value) / 100, height: 6)
            }
            
            Text("\(value)")
                .font(.system(size: 9, design: .monospaced))
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
                // EXPANDED
                DynamicIslandExpandedRegion(.leading) {
                    VStack(spacing: 4) {
                        ZStack {
                            PixelPetSprite(
                                species: context.state.petSpecies,
                                scale: 4.5,
                                isEating: context.state.currentAnimation == "eating",
                                isPlaying: context.state.currentAnimation == "playing",
                                isPetting: context.state.currentAnimation == "petting"
                            )
                            
                            if context.state.currentAnimation == "petting" {
                                Text("❤️").font(.system(size: 14)).offset(x: 25, y: -10)
                            }
                            if context.state.currentAnimation == "playing" {
                                Text("⭐").font(.system(size: 14)).offset(x: -20, y: -10)
                            }
                            if context.state.currentAnimation == "eating" {
                                Text("🍎").font(.system(size: 14)).offset(x: 25, y: 5)
                            }
                        }
                        Text("Stage \(context.state.petStage)")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(spacing: 5) {
                        StatusBar(icon: "🍖", value: context.state.hunger,
                                  color: context.state.hunger > 50 ? .green : .orange)
                        StatusBar(icon: "❤️", value: context.state.happiness,
                                  color: context.state.happiness > 50 ? .pink : .orange)
                        StatusBar(icon: "⚡", value: context.state.energy,
                                  color: context.state.energy > 50 ? .yellow : .gray)
                    }
                }
                
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.petName)
                        .font(.system(size: 13, weight: .semibold))
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 12) {
                        // Deep link buttons that trigger app actions
                        Link(destination: URL(string: "unhooked://action/feed")!) {
                            VStack(spacing: 2) {
                                Text("🍎").font(.system(size: 18))
                                Text("Feed").font(.system(size: 9))
                            }
                            .frame(width: 44, height: 38)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        Link(destination: URL(string: "unhooked://action/play")!) {
                            VStack(spacing: 2) {
                                Text("🎾").font(.system(size: 18))
                                Text("Play").font(.system(size: 9))
                            }
                            .frame(width: 44, height: 38)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        Link(destination: URL(string: "unhooked://action/pet")!) {
                            VStack(spacing: 2) {
                                Text("✋").font(.system(size: 18))
                                Text("Pet").font(.system(size: 9))
                            }
                            .frame(width: 44, height: 38)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        Spacer()
                        
                        Link(destination: URL(string: "unhooked://home")!) {
                            HStack(spacing: 3) {
                                Image(systemName: "arrow.up.right.square").font(.system(size: 11))
                                Text("Open").font(.system(size: 10, weight: .medium))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.5))
                            .cornerRadius(6)
                        }
                    }
                }
            } compactLeading: {
                // Pet in compact - positioned to show above island
                ZStack(alignment: .bottom) {
                    // Pet sprite - showing above
                    PixelPetSprite(
                        species: context.state.petSpecies,
                        scale: 3,
                        isEating: context.state.currentAnimation == "eating",
                        isPlaying: false,
                        isPetting: false
                    )
                    .offset(y: -20)
                    
                    // Status dot at bottom
                    StatusDot(status: context.state.statusColor)
                        .offset(y: 4)
                }
                .frame(width: 32, height: 32)
                .clipped()
            } compactTrailing: {
                HStack(spacing: 3) {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(.yellow)
                        .font(.system(size: 11))
                    Text("\(context.state.energyBalance)")
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                }
            } minimal: {
                // Minimal - just show pet peeking
                PixelPetSprite(
                    species: context.state.petSpecies,
                    scale: 2,
                    isEating: false,
                    isPlaying: false,
                    isPetting: false
                )
                .offset(y: -8)
            }
        }
    }
    
    private func lockScreenView(context: ActivityViewContext<PetActivityAttributes>) -> some View {
        HStack(spacing: 14) {
            ZStack {
                PixelPetSprite(
                    species: context.state.petSpecies,
                    scale: 5,
                    isEating: context.state.currentAnimation == "eating",
                    isPlaying: context.state.currentAnimation == "playing",
                    isPetting: context.state.currentAnimation == "petting"
                )
                
                if context.state.currentAnimation == "petting" {
                    Text("❤️").font(.system(size: 16)).offset(x: 28, y: -12)
                }
                if context.state.currentAnimation == "eating" {
                    Text("🍎").font(.system(size: 16)).offset(x: 28, y: 8)
                }
                
                StatusDot(status: context.state.statusColor)
                    .scaleEffect(1.3)
                    .offset(x: 22, y: 18)
            }
            
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(context.state.petName).font(.headline)
                    Text("Stage \(context.state.petStage)")
                        .font(.caption).foregroundStyle(.secondary)
                }
                
                HStack(spacing: 10) {
                    Label("\(context.state.hunger)%", systemImage: "fork.knife")
                    Label("\(context.state.happiness)%", systemImage: "heart.fill")
                }
                .font(.caption2)
            }
            
            Spacer()
            
            VStack {
                Image(systemName: "bolt.fill").foregroundStyle(.yellow)
                Text("\(context.state.energyBalance)")
                    .font(.title3.bold().monospacedDigit())
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}
