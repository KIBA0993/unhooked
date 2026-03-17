//
//  PetLiveActivity.swift
//  Unhooked
//
//  Dynamic Island - Pet ABOVE island using OVERLAY HACK
//

import SwiftUI
import ActivityKit
import WidgetKit

// MARK: - Peeking Pet (sits ABOVE Dynamic Island!)

struct PeekingPet: View {
    let species: String
    let stage: Int
    let scale: CGFloat
    let showZzz: Bool
    
    let offsetY: CGFloat = -8
    let offsetX: CGFloat = 8
    
    init(species: String, stage: Int, scale: CGFloat = 2.0, showZzz: Bool = true) {
        self.species = species
        self.stage = stage
        self.scale = scale
        self.showZzz = showZzz
    }
    
    var body: some View {
        PixelPetSprite(
            species: species,
            stage: stage,
            scale: scale
        )
        .offset(x: offsetX, y: offsetY)
    }
}

// MARK: - Pet Above Island (Working Configuration)

struct CenteredPetAboveIsland: View {
    let species: String
    let stage: Int
    let scale: CGFloat
    
    init(species: String, stage: Int, scale: CGFloat = 2.5) {
        self.species = species
        self.stage = stage
        self.scale = scale
    }
    
    var body: some View {
        // WORKING: scale 2.5, offsetY -8, NO X offset
        PixelPetSprite(
            species: species,
            stage: stage,
            scale: scale
        )
        .offset(y: -8)  // Peek above - THIS WORKED
        // NO X offset - any X offset clips the pet
    }
}

// MARK: - Expanded Walking Pet (walks left ↔ right)

struct ExpandedWalkingPet: View {
    let species: String
    let stage: Int
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 0.15)) { timeline in
            let time = timeline.date.timeIntervalSince1970
            let cycle = 5.0  // 5 seconds per direction
            let period = time.truncatingRemainder(dividingBy: cycle * 2)
            let goingRight = period < cycle
            let progress = goingRight
                ? period / cycle
                : (cycle * 2 - period) / cycle
            
            GeometryReader { geo in
                let petSize: CGFloat = 30
                let x = petSize/2 + (geo.size.width - petSize) * CGFloat(progress)
                
                PixelPetSprite(
                    species: species,
                    stage: stage,
                    scale: 4
                )
                .scaleEffect(x: goingRight ? 1 : -1, y: 1)
                .position(x: x, y: geo.size.height / 2 - 20)  // Above center
            }
            .frame(height: 60)
        }
    }
}

// MARK: - Pixel Pet Sprite (Stage-aware)

struct PixelPetSprite: View {
    let species: String
    let stage: Int
    let scale: CGFloat
    
    init(species: String, scale: CGFloat) {
        self.species = species
        self.stage = 2 // Default to child stage for backwards compatibility
        self.scale = scale
    }
    
    init(species: String, stage: Int, scale: CGFloat) {
        self.species = species
        self.stage = stage
        self.scale = scale
    }
    
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
            return getCatPixels()
        } else {
            return getDogPixels()
        }
    }
    
    private func getCatPixels() -> [[String]] {
        switch stage {
        case 0: // Egg
            return [
                [".", "K", "K", "K", "K", "."],
                ["K", "W", "W", "W", "W", "K"],
                ["K", "W", "K", "K", "W", "K"],
                ["K", "W", "W", "W", "W", "K"],
                [".", "K", "K", "K", "K", "."],
            ]
        case 1: // Baby
            return [
                ["K", ".", ".", ".", ".", "K"],
                ["K", "K", "K", "K", "K", "K"],
                ["K", "G", "K", "K", "G", "K"],
                ["K", "K", "P", "P", "K", "K"],
                [".", "K", "W", "W", "K", "."],
            ]
        default: // Child and above
            return [
                ["K", ".", ".", ".", ".", "K"],
                ["K", "K", "K", "K", "K", "K"],
                ["K", "G", "K", "K", "G", "K"],
                ["K", "K", "P", "P", "K", "K"],
                ["K", "W", "W", "W", "W", "K"],
                ["K", "K", ".", ".", "K", "K"],
            ]
        }
    }
    
    private func getDogPixels() -> [[String]] {
        switch stage {
        case 0: // Egg
            return [
                [".", "K", "K", "K", "K", "."],
                ["K", "C", "E", "E", "C", "K"],
                ["K", "C", "C", "C", "C", "K"],
                ["K", "C", "O", "C", "C", "K"],
                [".", "K", "K", "K", "K", "."],
            ]
        case 1: // Baby
            return [
                ["E", "E", ".", ".", "E", "E"],
                ["E", "K", "K", "K", "K", "E"],
                ["K", "C", "G", "G", "C", "K"],
                ["K", "C", "N", "N", "C", "K"],
                [".", "K", "K", "K", "K", "."],
            ]
        default: // Child and above
            return [
                ["E", "E", ".", ".", "E", "E"],
                ["E", "K", "K", "K", "K", "E"],
                ["K", "C", "G", "G", "C", "K"],
                ["K", "C", "N", "N", "C", "K"],
                ["K", "C", "C", "C", "C", "K"],
                ["K", "K", ".", ".", "K", "K"],
            ]
        }
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
                // EXPANDED VIEW - Pet walks across when user taps island
                DynamicIslandExpandedRegion(.center) {
                    ExpandedWalkingPet(
                        species: context.state.petSpecies,
                        stage: context.state.petStage
                    )
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text(context.state.petName)
                            .font(.caption)
                            .foregroundColor(.white)
                        Spacer()
                        HStack(spacing: 8) {
                            Text("❤️ \(context.state.hunger)%")
                                .font(.caption)
                            Text("⚡ \(context.state.energyBalance)")
                                .font(.caption)
                        }
                        .foregroundColor(.green)
                    }
                    .padding(.horizontal)
                }
                
            } compactLeading: {
                // Pet peeking above on the LEFT side
                // This is the WORKING configuration
                CenteredPetAboveIsland(
                    species: context.state.petSpecies,
                    stage: context.state.petStage,
                    scale: 2.5  // Visible size
                )
                
            } compactTrailing: {
                // Energy on the right
                HStack(spacing: 2) {
                    Text("⚡")
                        .font(.system(size: 10))
                    Text("\(context.state.energyBalance)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                
            } minimal: {
                PeekingPet(
                    species: context.state.petSpecies,
                    stage: context.state.petStage,
                    scale: 1.5,
                    showZzz: false
                )
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
            PixelPetSprite(species: context.state.petSpecies, stage: context.state.petStage, scale: 5)
            
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
