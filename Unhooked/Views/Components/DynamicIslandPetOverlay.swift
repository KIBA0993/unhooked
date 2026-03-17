//
//  DynamicIslandPetOverlay.swift
//  Unhooked
//
//  Animated pet that lives above the Dynamic Island
//  Inspired by: https://github.com/khlebobul/dynamic_island_pet
//

import SwiftUI

struct DynamicIslandPetOverlay: View {
    let species: Species
    let stage: Int
    
    @State private var offsetX: CGFloat = 0
    @State private var isAnimating = false
    @State private var facingRight = true
    
    private let petScale: CGFloat = 1.5
    private let animationDuration: Double = 2.0
    
    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let petWidth: CGFloat = 12 * petScale
            let petHeight: CGFloat = 10 * petScale
            
            // Get Dynamic Island dimensions from DeviceInfo
            let islandWidth = DeviceInfo.dynamicIslandWidth
            
            // Calculate the center position of the Dynamic Island
            let islandCenterX = screenWidth / 2
            let islandStartX = islandCenterX - (islandWidth / 2)
            
            // Pet walks across the top of the Dynamic Island
            let walkableWidth = islandWidth - petWidth - 8
            let startX = islandStartX + 4
            
            // Position pet so its feet touch the top of the Dynamic Island
            let topOfIsland = DeviceInfo.dynamicIslandTopPadding
            let petY = topOfIsland - (petHeight / 2) + 2
            
            MiniPixelPet(species: species, stage: stage, scale: petScale)
                .scaleEffect(x: facingRight ? 1 : -1, y: 1)
                .position(
                    x: startX + (petWidth / 2) + offsetX,
                    y: petY
                )
                .onAppear {
                    startAnimation(walkableWidth: walkableWidth)
                }
        }
        .frame(height: 50)
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
    
    private func startAnimation(walkableWidth: CGFloat) {
        guard !isAnimating else { return }
        isAnimating = true
        
        offsetX = 0
        animateMovement(walkableWidth: walkableWidth, movingRight: true)
    }
    
    private func animateMovement(walkableWidth: CGFloat, movingRight: Bool) {
        facingRight = movingRight
        let targetX = movingRight ? walkableWidth : 0
        
        withAnimation(.easeInOut(duration: animationDuration)) {
            offsetX = targetX
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            animateMovement(walkableWidth: walkableWidth, movingRight: !movingRight)
        }
    }
}

// MARK: - Mini Pixel Pet for Dynamic Island Overlay

struct MiniPixelPet: View {
    let species: Species
    let stage: Int
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
        if species == .cat {
            return getCatPixels()
        } else {
            return getDogPixels()
        }
    }
    
    private func getCatPixels() -> [[String]] {
        switch stage {
        case 0: // Egg - simplified
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
        case "G": return Color(red: 0.56, green: 0.93, blue: 0.56) // Light green eyes
        case "g": return Color(red: 0.13, green: 0.55, blue: 0.13) // Dark green
        case "P": return Color(red: 1.0, green: 0.71, blue: 0.76)  // Pink nose
        case "C": return Color(red: 1.0, green: 0.89, blue: 0.77)  // Cream
        case "E": return Color(red: 0.55, green: 0.27, blue: 0.07) // Brown ears
        case "O": return Color(red: 1.0, green: 0.65, blue: 0.0)   // Orange spot
        case "N": return Color(red: 0.2, green: 0.2, blue: 0.2)    // Dark nose
        default: return .clear
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.blue.opacity(0.3).ignoresSafeArea()
        
        VStack {
            if DeviceInfo.hasDynamicIsland {
                DynamicIslandPetOverlay(species: .cat, stage: 2)
            } else {
                Text("Dynamic Island not available")
                    .padding(.top, 60)
            }
            Spacer()
        }
    }
}
