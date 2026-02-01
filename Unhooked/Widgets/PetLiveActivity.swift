//
//  PetLiveActivity.swift
//  Unhooked
//
//  Dynamic Island Live Activity - Pixel Pet peeking above island
//

import SwiftUI
import ActivityKit
import WidgetKit

// MARK: - Pixel Pet Sprite (Peeking above Dynamic Island)

struct PixelPetSprite: View {
    let species: String
    let frame: Int
    let isSleeping: Bool
    let scale: CGFloat
    let isEating: Bool
    let isPlaying: Bool
    
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
        .rotationEffect(isPlaying ? .degrees(10) : .degrees(0))
        .animation(.easeInOut(duration: 0.3).repeatCount(isPlaying ? 6 : 0), value: isPlaying)
    }
    
    private func getPixels() -> [[String]] {
        if species == "cat" {
            if isEating {
                return catEatingFrame()
            }
            return frame == 0 ? catFrame1() : catFrame2()
        } else {
            if isEating {
                return dogEatingFrame()
            }
            return frame == 0 ? dogFrame1() : dogFrame2()
        }
    }
    
    // Cat normal frame 1
    private func catFrame1() -> [[String]] {
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
    
    // Cat blinking
    private func catFrame2() -> [[String]] {
        return [
            [".", "K", ".", ".", ".", ".", ".", ".", "K", "."],
            [".", "K", "K", "K", "K", "K", "K", "K", "K", "."],
            [".", "K", "O", "O", "O", "O", "O", "O", "K", "."],
            [".", "K", "O", "K", "O", "O", "K", "O", "K", "."],
            [".", "K", "O", "O", "O", "O", "O", "O", "K", "."],
            [".", "K", "O", "O", "P", "P", "O", "O", "K", "."],
            [".", ".", "K", "K", "K", "K", "K", "K", ".", "."],
            [".", ".", ".", "K", ".", ".", "K", ".", ".", "."],
        ]
    }
    
    // Cat eating (mouth open)
    private func catEatingFrame() -> [[String]] {
        return [
            [".", "K", ".", ".", ".", ".", ".", ".", "K", "."],
            [".", "K", "K", "K", "K", "K", "K", "K", "K", "."],
            [".", "K", "O", "O", "O", "O", "O", "O", "K", "."],
            [".", "K", "O", "G", "O", "O", "G", "O", "K", "."],
            [".", "K", "O", "g", "O", "O", "g", "O", "K", "."],
            [".", "K", "O", "K", "P", "P", "K", "O", "K", "."],  // Open mouth
            [".", ".", "K", "K", "R", "R", "K", "K", ".", "."],  // Food
            [".", ".", ".", "K", ".", ".", "K", ".", ".", "."],
        ]
    }
    
    // Dog normal frame 1
    private func dogFrame1() -> [[String]] {
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
    
    // Dog blinking
    private func dogFrame2() -> [[String]] {
        return [
            ["E", "E", ".", ".", ".", ".", ".", ".", "E", "E"],
            ["E", "B", "E", "K", "K", "K", "K", "E", "B", "E"],
            [".", "K", "C", "C", "C", "C", "C", "C", "K", "."],
            [".", "K", "C", "K", "C", "C", "K", "C", "K", "."],
            [".", "K", "C", "C", "C", "C", "C", "C", "K", "."],
            [".", "K", "C", "C", "N", "N", "C", "C", "K", "."],
            [".", ".", "K", "K", "K", "K", "K", "K", ".", "."],
            [".", ".", ".", "K", ".", ".", "K", ".", ".", "."],
        ]
    }
    
    // Dog eating
    private func dogEatingFrame() -> [[String]] {
        return [
            ["E", "E", ".", ".", ".", ".", ".", ".", "E", "E"],
            ["E", "B", "E", "K", "K", "K", "K", "E", "B", "E"],
            [".", "K", "C", "C", "C", "C", "C", "C", "K", "."],
            [".", "K", "C", "G", "C", "C", "G", "C", "K", "."],
            [".", "K", "C", "g", "C", "C", "g", "C", "K", "."],
            [".", "K", "C", "K", "N", "N", "K", "C", "K", "."],
            [".", ".", "K", "K", "R", "R", "K", "K", ".", "."],
            [".", ".", ".", "K", ".", ".", "K", ".", ".", "."],
        ]
    }
    
    private func getColor(for pixel: String) -> Color {
        switch pixel {
        case ".": return .clear
        case "K": return .black
        case "W": return .white
        case "O": return Color(red: 1.0, green: 0.65, blue: 0.0)
        case "G": return Color(red: 0.56, green: 0.93, blue: 0.56)
        case "g": return Color(red: 0.13, green: 0.55, blue: 0.13)
        case "P": return Color(red: 1.0, green: 0.71, blue: 0.76)
        case "C": return Color(red: 1.0, green: 0.89, blue: 0.77)
        case "E": return Color(red: 0.55, green: 0.27, blue: 0.07)
        case "B": return Color(red: 0.4, green: 0.2, blue: 0.1)
        case "N": return Color(red: 0.2, green: 0.2, blue: 0.2)
        case "R": return Color(red: 0.8, green: 0.2, blue: 0.2)  // Food (red)
        default: return .clear
        }
    }
}

// MARK: - Food Emoji for animation
struct FoodEmoji: View {
    let isVisible: Bool
    
    var body: some View {
        Text("🍎")
            .font(.system(size: 16))
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.5)
            .animation(.spring(response: 0.3), value: isVisible)
    }
}

// MARK: - Status Dot
struct StatusDot: View {
    let status: String
    
    var body: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 8, height: 8)
            .overlay(Circle().stroke(Color.black.opacity(0.3), lineWidth: 0.5))
    }
    
    private var statusColor: Color {
        switch status {
        case "green": return .green
        case "yellow": return .yellow
        case "red": return .red
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
            Text(icon)
                .font(.system(size: 10))
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.15))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(value) / 100)
                }
            }
            .frame(height: 6)
            
            Text("\(value)")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .frame(width: 22, alignment: .trailing)
        }
    }
}

// MARK: - Main Live Activity Widget

@available(iOS 16.2, *)
struct PetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PetActivityAttributes.self) { context in
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
                    Text(context.state.petName)
                        .font(.system(size: 13, weight: .semibold))
                }
            } compactLeading: {
                // COMPACT STATE - Pet ABOVE the island + food if eating
                ZStack {
                    // Pet peeking from TOP (negative offset to go above)
                    PixelPetSprite(
                        species: context.state.petSpecies,
                        frame: 0,
                        isSleeping: context.state.isSleeping,
                        scale: 3.5,
                        isEating: context.state.currentAnimation == "eating",
                        isPlaying: context.state.currentAnimation == "playing"
                    )
                    .offset(y: -18)  // Push pet ABOVE the Dynamic Island
                    
                    // Food emoji when eating
                    if context.state.currentAnimation == "eating" {
                        Text("🍎")
                            .font(.system(size: 12))
                            .offset(x: 15, y: -10)
                    }
                    
                    // Status dot at bottom
                    StatusDot(status: context.state.statusColor)
                        .offset(x: 12, y: 8)
                }
                .frame(width: 36, height: 36)
            } compactTrailing: {
                HStack(spacing: 3) {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(.yellow)
                        .font(.system(size: 11))
                    Text("\(context.state.energyBalance)")
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                }
            } minimal: {
                // MINIMAL - Pet peeking above
                PixelPetSprite(
                    species: context.state.petSpecies,
                    frame: 0,
                    isSleeping: context.state.isSleeping,
                    scale: 2.5,
                    isEating: false,
                    isPlaying: false
                )
                .offset(y: -12)
            }
        }
    }
    
    // MARK: - Expanded Views
    
    private func expandedLeadingView(context: ActivityViewContext<PetActivityAttributes>) -> some View {
        VStack(spacing: 4) {
            ZStack {
                PixelPetSprite(
                    species: context.state.petSpecies,
                    frame: 0,
                    isSleeping: context.state.isSleeping,
                    scale: 5,
                    isEating: context.state.currentAnimation == "eating",
                    isPlaying: context.state.currentAnimation == "playing"
                )
                
                // Show hearts when petting
                if context.state.currentAnimation == "petting" {
                    HStack(spacing: 2) {
                        Text("❤️").font(.system(size: 10))
                        Text("❤️").font(.system(size: 8))
                    }
                    .offset(x: 20, y: -15)
                }
                
                // Show stars when playing
                if context.state.currentAnimation == "playing" {
                    Text("⭐").font(.system(size: 12))
                        .offset(x: -15, y: -12)
                }
            }
            
            Text("Stage \(context.state.petStage)")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
    }
    
    private func expandedTrailingView(context: ActivityViewContext<PetActivityAttributes>) -> some View {
        VStack(alignment: .trailing, spacing: 5) {
            StatusBar(
                icon: "🍖",
                value: context.state.hunger,
                color: context.state.hunger > 50 ? .green : (context.state.hunger > 20 ? .yellow : .red)
            )
            .frame(width: 90)
            
            StatusBar(
                icon: "❤️",
                value: context.state.happiness,
                color: context.state.happiness > 50 ? .pink : .orange
            )
            .frame(width: 90)
            
            StatusBar(
                icon: "⚡",
                value: context.state.energy,
                color: context.state.energy > 50 ? .yellow : .gray
            )
            .frame(width: 90)
        }
    }
    
    private func expandedBottomView(context: ActivityViewContext<PetActivityAttributes>) -> some View {
        HStack(spacing: 10) {
            // Feed - triggers eating animation via Intent
            Button(intent: PetActionIntent(action: "feed")) {
                VStack(spacing: 2) {
                    Text("🍎")
                        .font(.system(size: 18))
                    Text("Feed")
                        .font(.system(size: 9, weight: .medium))
                }
                .frame(width: 44, height: 40)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            
            // Play - triggers playing animation via Intent
            Button(intent: PetActionIntent(action: "play")) {
                VStack(spacing: 2) {
                    Text("🎾")
                        .font(.system(size: 18))
                    Text("Play")
                        .font(.system(size: 9, weight: .medium))
                }
                .frame(width: 44, height: 40)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            
            // Pet - triggers petting animation via Intent
            Button(intent: PetActionIntent(action: "pet")) {
                VStack(spacing: 2) {
                    Text("✋")
                        .font(.system(size: 18))
                    Text("Pet")
                        .font(.system(size: 9, weight: .medium))
                }
                .frame(width: 44, height: 40)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Open app
            Link(destination: URL(string: "unhooked://home")!) {
                HStack(spacing: 3) {
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 11))
                    Text("Open")
                        .font(.system(size: 10, weight: .medium))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.5))
                .cornerRadius(6)
            }
        }
    }
    
    // MARK: - Lock Screen View
    
    private func lockScreenView(context: ActivityViewContext<PetActivityAttributes>) -> some View {
        HStack(spacing: 14) {
            ZStack {
                PixelPetSprite(
                    species: context.state.petSpecies,
                    frame: 0,
                    isSleeping: context.state.isSleeping,
                    scale: 5,
                    isEating: context.state.currentAnimation == "eating",
                    isPlaying: context.state.currentAnimation == "playing"
                )
                
                StatusDot(status: context.state.statusColor)
                    .scaleEffect(1.3)
                    .offset(x: 18, y: 15)
            }
            
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(context.state.petName)
                        .font(.headline)
                    Text("• Stage \(context.state.petStage)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                HStack(spacing: 10) {
                    Label("\(context.state.hunger)%", systemImage: "fork.knife")
                    Label("\(context.state.happiness)%", systemImage: "heart.fill")
                    Label("\(context.state.energy)%", systemImage: "bolt.fill")
                }
                .font(.caption2)
            }
            
            Spacer()
            
            VStack {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(.yellow)
                Text("\(context.state.energyBalance)")
                    .font(.title3.bold().monospacedDigit())
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

// MARK: - App Intent for Dynamic Island actions

import AppIntents

@available(iOS 16.0, *)
struct PetActionIntent: AppIntent {
    static var title: LocalizedStringResource = "Pet Action"
    static var description = IntentDescription("Perform an action on your pet")
    
    @Parameter(title: "Action")
    var action: String
    
    init() {
        self.action = "feed"
    }
    
    init(action: String) {
        self.action = action
    }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        // Post notification for main app to handle
        NotificationCenter.default.post(
            name: Notification.Name("PetDynamicIslandAction"),
            object: nil,
            userInfo: ["action": action]
        )
        
        // Update the Live Activity to show animation
        if #available(iOS 16.2, *) {
            for activity in Activity<PetActivityAttributes>.activities {
                // Get current state and add animation
                var newState = activity.content.state
                
                // We need to create a new state with animation
                // The main app will handle clearing the animation after a delay
                await activity.update(
                    ActivityContent(
                        state: PetActivityAttributes.ContentState(
                            petSpecies: newState.petSpecies,
                            petStage: newState.petStage,
                            petName: newState.petName,
                            healthState: newState.healthState,
                            hunger: action == "feed" ? min(100, newState.hunger + 10) : newState.hunger,
                            happiness: action == "play" || action == "pet" ? min(100, newState.happiness + 5) : newState.happiness,
                            energy: newState.energy,
                            energyBalance: newState.energyBalance,
                            isFragile: newState.isFragile,
                            isSleeping: newState.isSleeping,
                            needsAttention: newState.needsAttention,
                            isCritical: newState.isCritical,
                            currentAnimation: action == "feed" ? "eating" : (action == "play" ? "playing" : (action == "pet" ? "petting" : ""))
                        ),
                        staleDate: nil
                    )
                )
                
                // Clear animation after 2 seconds
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                
                await activity.update(
                    ActivityContent(
                        state: PetActivityAttributes.ContentState(
                            petSpecies: newState.petSpecies,
                            petStage: newState.petStage,
                            petName: newState.petName,
                            healthState: newState.healthState,
                            hunger: action == "feed" ? min(100, newState.hunger + 10) : newState.hunger,
                            happiness: action == "play" || action == "pet" ? min(100, newState.happiness + 5) : newState.happiness,
                            energy: newState.energy,
                            energyBalance: newState.energyBalance,
                            isFragile: newState.isFragile,
                            isSleeping: newState.isSleeping,
                            needsAttention: newState.needsAttention,
                            isCritical: newState.isCritical,
                            currentAnimation: ""  // Clear animation
                        ),
                        staleDate: nil
                    )
                )
            }
        }
        
        return .result()
    }
}
