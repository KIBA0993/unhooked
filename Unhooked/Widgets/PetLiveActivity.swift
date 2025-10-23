//
//  PetLiveActivity.swift
//  Unhooked
//
//  Dynamic Island Live Activity
//

import SwiftUI
import ActivityKit
import WidgetKit

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
                    petView(context: context, size: 50)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    statsView(context: context)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    fullStatsView(context: context)
                }
            } compactLeading: {
                petEmoji(context: context)
            } compactTrailing: {
                HStack(spacing: 2) {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(.yellow)
                    Text("\(context.state.energyBalance)")
                        .font(.caption2)
                        .monospacedDigit()
                }
            } minimal: {
                petEmoji(context: context)
            }
        }
    }
    
    // MARK: - Lock Screen View
    
    private func liveActivityView(context: ActivityViewContext<PetActivityAttributes>) -> some View {
        HStack(spacing: 12) {
            petView(context: context, size: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(speciesName(context.state.petSpecies)) • Stage \(context.state.petStage)")
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
    
    // MARK: - Pet Display
    
    private func petView(context: ActivityViewContext<PetActivityAttributes>, size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(petColor(context.state.petSpecies).opacity(0.2))
                .frame(width: size, height: size)
            
            Text(petEmoji(context.state.petSpecies))
                .font(.system(size: size * 0.6))
                .grayscale(context.state.healthState == "dead" ? 1.0 : 0.0)
                .opacity(context.state.healthState == "dead" ? 0.5 : 1.0)
            
            if context.state.isFragile {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "bandage.fill")
                            .font(.system(size: size * 0.2))
                            .foregroundStyle(.orange)
                    }
                }
                .frame(width: size, height: size)
            }
        }
    }
    
    private func petEmoji(context: ActivityViewContext<PetActivityAttributes>) -> some View {
        Text(petEmoji(context.state.petSpecies))
            .font(.caption2)
    }
    
    private func petEmoji(_ species: String) -> String {
        species == "cat" ? "🐱" : "🐶"
    }
    
    private func speciesName(_ species: String) -> String {
        species.capitalized
    }
    
    private func petColor(_ species: String) -> Color {
        species == "cat" ? .orange : .brown
    }
    
    // MARK: - Stats Views
    
    private func statsView(context: ActivityViewContext<PetActivityAttributes>) -> some View {
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
    
    private func fullStatsView(context: ActivityViewContext<PetActivityAttributes>) -> some View {
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

