//
//  PetLiveActivity.swift
//  Unhooked
//
//  Dynamic Island - Pet sits ON TOP like Hit'Em
//

import SwiftUI
import ActivityKit
import WidgetKit

// MARK: - Pixel Pet Sprite

struct PixelPetSprite: View {
    let species: String
    let scale: CGFloat
    let mood: String
    
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
                // EXPANDED
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        PixelPetSprite(species: context.state.petSpecies, scale: 4, mood: "happy")
                        VStack(alignment: .leading, spacing: 2) {
                            Text(context.state.petName).font(.caption).fontWeight(.semibold)
                            Text("Stage \(context.state.petStage)").font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
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
                
                DynamicIslandExpandedRegion(.bottom) {
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
                        
                        // Health status
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
                }
            } compactLeading: {
                // HIT'EM STYLE: Pet pops OUT of the island
                // NO clipping - let it overflow!
                PixelPetSprite(species: context.state.petSpecies, scale: 3, mood: "happy")
                    .offset(y: -22)  // Aggressive offset - like Hit'Em's -20
                    .frame(width: 36, height: 36)
                    // NO .clipped() - let it overflow above!
                    
            } compactTrailing: {
                HStack(spacing: 3) {
                    Circle()
                        .fill(context.state.isCritical ? Color.red : (context.state.needsAttention ? Color.orange : Color.green))
                        .frame(width: 6, height: 6)
                    Text("\(context.state.energyBalance)")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                }
            } minimal: {
                // Minimal - pet peeking
                PixelPetSprite(species: context.state.petSpecies, scale: 2.5, mood: "happy")
                    .offset(y: -16)
                    .frame(width: 28, height: 28)
            }
        }
    }
    
    private func lockScreenView(context: ActivityViewContext<PetActivityAttributes>) -> some View {
        HStack(spacing: 12) {
            PixelPetSprite(species: context.state.petSpecies, scale: 5, mood: "happy")
            
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
