//
//  StageIndicator.swift
//  Unhooked
//
//  Evolution stage indicator with tooltip
//

import SwiftUI

struct StageIndicator: View {
    let currentStage: Int
    let growthProgress: Int
    let species: Species
    
    @State private var showingPopover = false
    
    private var stageInfo: (stage: Int, current: EvolutionStage, next: EvolutionStage?) {
        EvolutionStages.getCurrentStage(progress: growthProgress)
    }
    
    var body: some View {
        Button {
            showingPopover.toggle()
        } label: {
            Image(systemName: "trophy.fill")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.black)
                .frame(width: 48, height: 48)
                .background(RetroColors.pink)
                .retroBorder(width: 4, cornerRadius: 12)
                .retroShadow(offset: 4)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showingPopover) {
            stageInfoView
                .presentationCompactAdaptation(.popover)
        }
    }
    
    private var stageInfoView: some View {
        VStack(spacing: 16) {
            // Header
            VStack(spacing: 4) {
                Text("Evolution Progress")
                    .font(.system(size: 16, weight: .bold))
                
                Text(species == .cat ? "🐱" : "🐶")
                    .font(.system(size: 40))
            }
            .padding(.top, 8)
            
            // Current stage
            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    Text(stageInfo.current.emoji)
                        .font(.system(size: 24))
                    
                    VStack(alignment: .leading) {
                        Text(stageInfo.current.name)
                            .font(.system(size: 18, weight: .bold))
                        Text("Stage \(stageInfo.stage + 1) of \(EvolutionStages.stages.count)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        colors: [Color.purple.opacity(0.3), Color.pink.opacity(0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .retroBorder(width: 2, cornerRadius: 10)
            }
            
            // Stage indicators
            HStack(spacing: 8) {
                ForEach(0..<EvolutionStages.stages.count, id: \.self) { index in
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(index <= stageInfo.stage ? Color.orange : Color.gray.opacity(0.3))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .stroke(.black, lineWidth: 2)
                                )
                            
                            Text("\(index + 1)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(index <= stageInfo.stage ? .white : .gray)
                        }
                        
                        Text(EvolutionStages.stages[index].name)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(index <= stageInfo.stage ? .primary : .secondary)
                    }
                }
            }
            
            // Progress info
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Current Progress:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(growthProgress)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .monospacedDigit()
                }
                
                if let next = stageInfo.next {
                    HStack {
                        Text("Next Stage At:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(next.threshold)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .monospacedDigit()
                    }
                } else {
                    HStack {
                        Spacer()
                        Text("🎉 Max Stage Reached!")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.purple)
                        Spacer()
                    }
                }
            }
            .font(.system(size: 12))
            .padding(12)
            .background(Color.purple.opacity(0.1))
            .retroBorder(width: 2, cornerRadius: 10)
            
            Spacer()
        }
        .padding()
        .frame(width: 320, height: 380)
    }
}

#Preview {
    VStack(spacing: 20) {
        StageIndicator(currentStage: 0, growthProgress: 25, species: .cat)
        StageIndicator(currentStage: 2, growthProgress: 150, species: .dog)
        StageIndicator(currentStage: 4, growthProgress: 400, species: .cat)
    }
    .padding()
    .background(RetroGradients.background)
}

