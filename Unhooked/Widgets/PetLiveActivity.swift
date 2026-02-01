//
//  PetLiveActivity.swift
//  Unhooked
//
//  Dynamic Island Live Activity - Pixel Pet Widget
//  Based on PRD: Compact, Minimal, and Expanded states
//

import SwiftUI
import ActivityKit
import WidgetKit

// MARK: - Animated Pixel Pet for Dynamic Island

struct DynamicIslandPet: View {
    let species: String
    let size: CGFloat
    let isAnimated: Bool
    let isSleeping: Bool
    
    @State private var animationFrame: Int = 0
    
    var body: some View {
        ZStack {
            PixelPetSprite(
                species: species,
                frame: animationFrame,
                isSleeping: isSleeping,
                scale: size / 16  // Base size is 16px
            )
        }
        .onAppear {
            if isAnimated {
                startIdleAnimation()
            }
        }
    }
    
    private func startIdleAnimation() {
        // Subtle idle animation every 15 seconds (breathing/blinking)
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                animationFrame = (animationFrame + 1) % 2
            }
        }
    }
}

// MARK: - Pixel Pet Sprite (16x16 for compact, scalable)

struct PixelPetSprite: View {
    let species: String
    let frame: Int
    let isSleeping: Bool
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
            return frame == 0 ? catFrame1() : catFrame2()
        } else {
            return frame == 0 ? dogFrame1() : dogFrame2()
        }
    }
    
    // Cat idle frame 1 (eyes open)
    private func catFrame1() -> [[String]] {
        if isSleeping {
            return [
                [".", "K", ".", ".", ".", ".", ".", ".", "K", "."],
                [".", "K", "K", "K", "K", "K", "K", "K", "K", "."],
                [".", "K", "O", "O", "O", "O", "O", "O", "K", "."],
                [".", "K", "O", "K", "O", "O", "K", "O", "K", "."],  // Closed eyes (-)
                [".", "K", "O", "O", "O", "O", "O", "O", "K", "."],
                [".", "K", "O", "O", "P", "P", "O", "O", "K", "."],
                [".", ".", "K", "K", "K", "K", "K", "K", ".", "."],
                [".", ".", ".", "K", ".", ".", "K", ".", ".", "."],
            ]
        }
        return [
            [".", "K", ".", ".", ".", ".", ".", ".", "K", "."],
            [".", "K", "K", "K", "K", "K", "K", "K", "K", "."],
            [".", "K", "O", "O", "O", "O", "O", "O", "K", "."],
            [".", "K", "O", "G", "O", "O", "G", "O", "K", "."],  // Open eyes
            [".", "K", "O", "g", "O", "O", "g", "O", "K", "."],
            [".", "K", "O", "O", "P", "P", "O", "O", "K", "."],
            [".", ".", "K", "K", "K", "K", "K", "K", ".", "."],
            [".", ".", ".", "K", ".", ".", "K", ".", ".", "."],
        ]
    }
    
    // Cat idle frame 2 (blinking)
    private func catFrame2() -> [[String]] {
        return [
            [".", "K", ".", ".", ".", ".", ".", ".", "K", "."],
            [".", "K", "K", "K", "K", "K", "K", "K", "K", "."],
            [".", "K", "O", "O", "O", "O", "O", "O", "K", "."],
            [".", "K", "O", "K", "O", "O", "K", "O", "K", "."],  // Blinking (closed)
            [".", "K", "O", "O", "O", "O", "O", "O", "K", "."],
            [".", "K", "O", "O", "P", "P", "O", "O", "K", "."],
            [".", ".", "K", "K", "K", "K", "K", "K", ".", "."],
            [".", ".", ".", "K", ".", ".", "K", ".", ".", "."],
        ]
    }
    
    // Dog idle frame 1
    private func dogFrame1() -> [[String]] {
        if isSleeping {
            return [
                ["E", "E", ".", ".", ".", ".", ".", ".", "E", "E"],
                ["E", "B", "E", "K", "K", "K", "K", "E", "B", "E"],
                [".", "K", "C", "C", "C", "C", "C", "C", "K", "."],
                [".", "K", "C", "K", "C", "C", "K", "C", "K", "."],  // Closed eyes
                [".", "K", "C", "C", "C", "C", "C", "C", "K", "."],
                [".", "K", "C", "C", "N", "N", "C", "C", "K", "."],
                [".", ".", "K", "K", "K", "K", "K", "K", ".", "."],
                [".", ".", ".", "K", ".", ".", "K", ".", ".", "."],
            ]
        }
        return [
            ["E", "E", ".", ".", ".", ".", ".", ".", "E", "E"],
            ["E", "B", "E", "K", "K", "K", "K", "E", "B", "E"],
            [".", "K", "C", "C", "C", "C", "C", "C", "K", "."],
            [".", "K", "C", "G", "C", "C", "G", "C", "K", "."],  // Open eyes
            [".", "K", "C", "g", "C", "C", "g", "C", "K", "."],
            [".", "K", "C", "C", "N", "N", "C", "C", "K", "."],
            [".", ".", "K", "K", "K", "K", "K", "K", ".", "."],
            [".", ".", ".", "K", ".", ".", "K", ".", ".", "."],
        ]
    }
    
    // Dog idle frame 2 (blinking)
    private func dogFrame2() -> [[String]] {
        return [
            ["E", "E", ".", ".", ".", ".", ".", ".", "E", "E"],
            ["E", "B", "E", "K", "K", "K", "K", "E", "B", "E"],
            [".", "K", "C", "C", "C", "C", "C", "C", "K", "."],
            [".", "K", "C", "K", "C", "C", "K", "C", "K", "."],  // Blinking
            [".", "K", "C", "C", "C", "C", "C", "C", "K", "."],
            [".", "K", "C", "C", "N", "N", "C", "C", "K", "."],
            [".", ".", "K", "K", "K", "K", "K", "K", ".", "."],
            [".", ".", ".", "K", ".", ".", "K", ".", ".", "."],
        ]
    }
    
    private func getColor(for pixel: String) -> Color {
        switch pixel {
        case ".": return .clear
        case "K": return .black
        case "W": return .white
        case "O": return Color(red: 1.0, green: 0.65, blue: 0.0)  // Orange
        case "G": return Color(red: 0.56, green: 0.93, blue: 0.56) // Light green
        case "g": return Color(red: 0.13, green: 0.55, blue: 0.13) // Dark green
        case "P": return Color(red: 1.0, green: 0.71, blue: 0.76)  // Pink
        case "C": return Color(red: 1.0, green: 0.89, blue: 0.77)  // Cream
        case "E": return Color(red: 0.55, green: 0.27, blue: 0.07) // Brown ears
        case "B": return Color(red: 0.4, green: 0.2, blue: 0.1)    // Dark brown
        case "N": return Color(red: 0.2, green: 0.2, blue: 0.2)    // Dark nose
        default: return .clear
        }
    }
}

// MARK: - Status Indicator Dot

struct StatusDot: View {
    let status: String  // "green", "yellow", "red", "blue"
    
    var body: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 6, height: 6)
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
            )
    }
    
    private var statusColor: Color {
        switch status {
        case "green": return .green
        case "yellow": return .yellow
        case "red": return .red
        case "blue": return .blue
        default: return .green
        }
    }
}

// MARK: - Status Bar for Expanded View

struct StatusBar: View {
    let icon: String
    let label: String
    let value: Int  // 0-100
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Text(icon)
                .font(.system(size: 12))
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.2))
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(value) / 100)
                }
            }
            .frame(height: 8)
            
            Text("\(value)%")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .frame(width: 32, alignment: .trailing)
        }
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let icon: String
    let label: String
    let action: String  // Deep link action
    
    var body: some View {
        Link(destination: URL(string: "unhooked://action/\(action)")!) {
            VStack(spacing: 2) {
                Text(icon)
                    .font(.system(size: 20))
                Text(label)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .frame(width: 50, height: 44)
            .background(Color.white.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

// MARK: - Main Live Activity Widget

@available(iOS 16.2, *)
struct PetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PetActivityAttributes.self) { context in
            // Lock screen/banner UI
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // EXPANDED STATE
                DynamicIslandExpandedRegion(.leading) {
                    expandedLeadingView(context: context)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    expandedTrailingView(context: context)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    expandedBottomView(context: context)
                }
                
                DynamicIslandExpandedRegion(.center) {
                    // Pet name
                    Text(context.state.petName)
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            } compactLeading: {
                // COMPACT STATE - Leading: Pet sprite with status dot
                ZStack(alignment: .bottomTrailing) {
                    DynamicIslandPet(
                        species: context.state.petSpecies,
                        size: 28,
                        isAnimated: true,
                        isSleeping: context.state.isSleeping
                    )
                    
                    StatusDot(status: context.state.statusColor)
                        .offset(x: 2, y: 2)
                }
            } compactTrailing: {
                // COMPACT STATE - Trailing: Energy balance
                HStack(spacing: 2) {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(.yellow)
                        .font(.system(size: 10))
                    Text("\(context.state.energyBalance)")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                }
            } minimal: {
                // MINIMAL STATE - Just pet silhouette
                DynamicIslandPet(
                    species: context.state.petSpecies,
                    size: 20,
                    isAnimated: false,
                    isSleeping: context.state.isSleeping
                )
                .opacity(0.9)
            }
        }
    }
    
    // MARK: - Expanded State Views
    
    private func expandedLeadingView(context: ActivityViewContext<PetActivityAttributes>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            // Larger pet sprite (48x48)
            DynamicIslandPet(
                species: context.state.petSpecies,
                size: 48,
                isAnimated: true,
                isSleeping: context.state.isSleeping
            )
            
            // Pet name and stage
            Text("Stage \(context.state.petStage)")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
    }
    
    private func expandedTrailingView(context: ActivityViewContext<PetActivityAttributes>) -> some View {
        VStack(alignment: .trailing, spacing: 6) {
            // Status bars
            StatusBar(
                icon: "🍖",
                label: "Hunger",
                value: context.state.hunger,
                color: context.state.hunger > 50 ? .green : (context.state.hunger > 20 ? .yellow : .red)
            )
            .frame(width: 100)
            
            StatusBar(
                icon: "❤️",
                label: "Happy",
                value: context.state.happiness,
                color: context.state.happiness > 50 ? .pink : .orange
            )
            .frame(width: 100)
            
            StatusBar(
                icon: "⚡",
                label: "Energy",
                value: context.state.energy,
                color: context.state.energy > 50 ? .yellow : .gray
            )
            .frame(width: 100)
        }
    }
    
    private func expandedBottomView(context: ActivityViewContext<PetActivityAttributes>) -> some View {
        HStack(spacing: 8) {
            // Quick actions
            QuickActionButton(icon: "🍎", label: "Feed", action: "feed")
            QuickActionButton(icon: "🎾", label: "Play", action: "play")
            QuickActionButton(icon: "✋", label: "Pet", action: "pet")
            
            Spacer()
            
            // Open app button
            Link(destination: URL(string: "unhooked://home")!) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 12))
                    Text("Open")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.6))
                .cornerRadius(8)
            }
        }
        .padding(.top, 4)
    }
    
    // MARK: - Lock Screen View
    
    private func lockScreenView(context: ActivityViewContext<PetActivityAttributes>) -> some View {
        HStack(spacing: 16) {
            // Pet
            ZStack(alignment: .bottomTrailing) {
                DynamicIslandPet(
                    species: context.state.petSpecies,
                    size: 48,
                    isAnimated: false,
                    isSleeping: context.state.isSleeping
                )
                
                StatusDot(status: context.state.statusColor)
                    .scaleEffect(1.5)
                    .offset(x: 4, y: 4)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(context.state.petName)
                        .font(.headline)
                    Text("Stage \(context.state.petStage)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Mini status bars
                HStack(spacing: 12) {
                    miniStat(icon: "🍖", value: context.state.hunger)
                    miniStat(icon: "❤️", value: context.state.happiness)
                    miniStat(icon: "⚡", value: context.state.energy)
                }
            }
            
            Spacer()
            
            // Energy balance
            VStack(alignment: .trailing, spacing: 2) {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(.yellow)
                Text("\(context.state.energyBalance)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .monospacedDigit()
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private func miniStat(icon: String, value: Int) -> some View {
        HStack(spacing: 2) {
            Text(icon)
                .font(.system(size: 10))
            Text("\(value)%")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
        }
    }
}
