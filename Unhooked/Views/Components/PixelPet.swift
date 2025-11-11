//
//  PixelPet.swift
//  Unhooked
//
//  Pixel art pet display - Retro game style
//

import SwiftUI

struct PixelPet: View {
    let stage: Int
    let mood: PetMood
    let isActive: Bool
    let petType: Species
    let healthState: HealthState
    let currentAnimation: PetAnimation
    let trickVariant: Int
    
    @State private var animationTrigger = UUID()
    @State private var showHearts = false
    @State private var showStars = false
    @State private var showZzz = false
    
    var body: some View {
        ZStack {
            // Pixel art pet
            PixelGrid(
                pixels: petType == .cat ? getCatPixels() : getDogPixels(),
                scale: 6
            )
            .opacity(healthState == .dead ? 0.7 : 1.0)
            .grayscale(healthState == .dead ? 1.0 : 0.0)
            .saturation(healthState == .sick ? 0.7 : 1.0)
            .brightness(healthState == .sick ? -0.05 : 0.0)
            .modifier(AnimationModifier(
                animation: currentAnimation,
                trickVariant: trickVariant,
                trigger: animationTrigger
            ))
            
            // Health indicator
            if healthState == .sick {
                VStack {
                    HStack {
                        Spacer()
                        Text("🤒")
                            .font(.system(size: 20))
                            .padding(4)
                    }
                    Spacer()
                }
                .frame(width: 80, height: 80)
            }
            
            if healthState == .dead {
                VStack {
                    HStack {
                        Spacer()
                        Text("👻")
                            .font(.system(size: 20))
                            .padding(4)
                    }
                    Spacer()
                }
                .frame(width: 80, height: 80)
            }
            
            // Animation effects
            if showHearts {
                ForEach(0..<3, id: \.self) { index in
                    Text("❤️")
                        .font(.system(size: 24))
                        .offset(x: CGFloat([-20, 0, 20][index]), y: -60)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            
            if showStars {
                ForEach(0..<4, id: \.self) { index in
                    Text("✨")
                        .font(.system(size: 20))
                        .offset(
                            x: CGFloat([30, -30, 35, -35][index]),
                            y: CGFloat([-30, -30, 30, 30][index])
                        )
                        .transition(.scale.combined(with: .opacity))
                }
            }
            
            if showZzz {
                VStack(spacing: -8) {
                    ForEach(0..<3, id: \.self) { index in
                        Text("Z")
                            .font(.system(size: CGFloat(16 + index * 4)))
                            .foregroundColor(.blue.opacity(0.7))
                            .offset(x: CGFloat(index * 8))
                    }
                }
                .offset(x: 50, y: -40)
                .transition(.opacity)
            }
        }
        .onChange(of: currentAnimation) { _, _ in
            animationTrigger = UUID()
            handleAnimationEffects()
        }
    }
    
    // MARK: - Animation Effects Handler
    
    private func handleAnimationEffects() {
        showHearts = false
        showStars = false
        showZzz = false
        
        switch currentAnimation {
        case .trick:
            withAnimation {
                showStars = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation {
                    showStars = false
                }
            }
            
        case .pet:
            withAnimation {
                showHearts = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation {
                    showHearts = false
                }
            }
            
        case .nap:
            withAnimation {
                showZzz = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                withAnimation {
                    showZzz = false
                }
            }
            
        case .idle:
            break
        }
    }
    
    // MARK: - Pixel Art Data
    
    private func getCatPixels() -> [[String]] {
        switch stage {
        case 0: // Egg
            return [
                [".", ".", "K", "K", "K", "K", "K", "K", ".", "."],
                [".", "K", "K", "W", "W", "W", "W", "K", "K", "."],
                ["K", "K", "W", "W", "K", "K", "W", "W", "K", "K"],
                ["K", "W", "W", "K", "K", "K", "K", "W", "W", "K"],
                ["K", "W", "K", "K", "K", "K", "K", "K", "W", "K"],
                ["K", "W", "K", "K", "K", "K", "K", "K", "W", "K"],
                ["K", "W", "W", "K", "K", "K", "K", "W", "W", "K"],
                ["K", "K", "W", "W", "W", "W", "W", "W", "K", "K"],
                [".", "K", "K", "W", "W", "W", "W", "K", "K", "."],
                [".", ".", "K", "K", "K", "K", "K", "K", ".", "."]
            ]
            
        case 1: // Baby
            return [
                ["K", ".", ".", ".", ".", ".", ".", ".", "K", "."],
                ["K", "K", "K", "K", "K", "K", "K", "K", "K", "K"],
                ["K", "K", "G", "K", "K", "K", "G", "K", "K", "K"],
                ["K", "K", "g", "K", "K", "K", "g", "K", "K", "K"],
                [".", "K", "K", "K", "P", "P", "K", "K", "K", "."],
                [".", "K", "W", "W", "W", "W", "W", "W", "K", "."],
                [".", "K", "W", "W", "W", "W", "W", "W", "K", "."],
                [".", ".", "K", "W", "W", "W", "W", "K", ".", "."],
                [".", "K", "W", "K", ".", ".", "K", "W", "K", "."],
                [".", "K", "K", ".", ".", ".", ".", "K", "K", "."]
            ]
            
        case 2: // Child
            return [
                ["K", ".", ".", ".", ".", ".", ".", ".", ".", "K"],
                ["K", "K", "K", "K", "K", "K", "K", "K", "K", "K"],
                ["K", "K", "G", "K", "K", "K", "K", "G", "K", "K"],
                ["K", "K", "g", "G", "K", "K", "g", "G", "K", "K"],
                [".", "K", "K", "K", "K", "P", "K", "K", "K", "K"],
                [".", "K", "K", "K", "P", "p", "P", "K", "K", "K"],
                [".", "K", "W", "W", "W", "W", "W", "W", "W", "K"],
                [".", ".", "K", "W", "W", "W", "W", "W", "K", "."],
                [".", ".", "K", "W", "W", "W", "W", "W", "K", "K"],
                [".", ".", "K", "W", "W", "W", "W", "W", "K", "K"],
                [".", "K", "W", "K", "W", "K", "W", "K", "W", "K"],
                [".", "K", "K", ".", "K", "K", "K", "K", ".", "K"]
            ]
            
        case 3: // Teen
            return [
                ["K", ".", ".", ".", ".", ".", ".", ".", ".", "."],
                ["K", "K", "K", "K", "K", "K", "K", "K", "K", "K"],
                ["K", "K", "G", "g", "K", "K", "K", "G", "g", "K"],
                ["K", "K", "G", "G", "K", "K", "K", "G", "G", "K"],
                [".", "K", "K", "K", "K", "P", "P", "K", "K", "K"],
                [".", "K", "W", "W", "W", "P", "P", "W", "W", "W"],
                [".", "K", "W", "W", "W", "W", "W", "W", "W", "W"],
                [".", ".", "K", "W", "W", "W", "W", "W", "W", "K"],
                [".", ".", "K", "W", "W", "W", "W", "W", "W", "W"],
                [".", "K", "W", "W", "W", "W", "W", "W", "W", "W"],
                ["K", "W", "K", "W", "K", "W", "K", "W", "K", "W"],
                ["K", "K", ".", "K", "K", "K", "K", "K", "K", "K"]
            ]
            
        case 4: // Adult
            return [
                [".", ".", ".", "Y", ".", "Y", ".", "Y", ".", "."],
                [".", ".", "Y", "Y", "Y", "Y", "Y", "Y", "Y", "."],
                ["K", ".", ".", "Y", "Y", "Y", "Y", "Y", ".", "."],
                ["K", "K", "K", "K", "K", "K", "K", "K", "K", "K"],
                ["K", "K", "M", "G", "K", "K", "K", "M", "G", "K"],
                ["K", "K", "G", "G", "K", "K", "K", "G", "G", "K"],
                [".", "K", "K", "K", "K", "P", "P", "K", "K", "K"],
                [".", "K", "W", "W", "W", "p", "p", "W", "W", "W"],
                [".", "K", "W", "W", "W", "W", "W", "W", "W", "W"],
                [".", ".", "K", "W", "W", "W", "W", "W", "W", "K"],
                [".", ".", "K", "W", "W", "W", "W", "W", "W", "W"],
                [".", "K", "W", "W", "W", "W", "W", "W", "W", "W"],
                ["K", "W", "K", "W", "K", "W", "K", "W", "K", "W"],
                ["K", "K", ".", "K", "K", "K", "K", "K", "K", "K"]
            ]
            
        default:
            // Fallback to adult stage (stage 4)
            return [
                [".", ".", ".", "Y", ".", "Y", ".", "Y", ".", "."],
                [".", ".", "Y", "Y", "Y", "Y", "Y", "Y", "Y", "."],
                ["K", ".", ".", "Y", "Y", "Y", "Y", "Y", ".", "."],
                ["K", "K", "K", "K", "K", "K", "K", "K", "K", "K"],
                ["K", "K", "M", "G", "K", "K", "K", "M", "G", "K"],
                ["K", "K", "G", "G", "K", "K", "K", "G", "G", "K"],
                [".", "K", "K", "K", "K", "P", "P", "K", "K", "K"],
                [".", "K", "W", "W", "W", "p", "p", "W", "W", "W"],
                [".", "K", "W", "W", "W", "W", "W", "W", "W", "W"],
                [".", ".", "K", "W", "W", "W", "W", "W", "W", "K"],
                [".", ".", "K", "W", "W", "W", "W", "W", "W", "W"],
                [".", "K", "W", "W", "W", "W", "W", "W", "W", "W"],
                ["K", "W", "K", "W", "K", "W", "K", "W", "K", "W"],
                ["K", "K", ".", "K", "K", "K", "K", "K", "K", "K"]
            ]
        }
    }
    
    private func getDogPixels() -> [[String]] {
        switch stage {
        case 0: // Egg
            return [
                [".", ".", "K", "K", "K", "K", "K", "K", ".", "."],
                [".", "K", "C", "C", "E", "E", "C", "C", "K", "."],
                ["K", "C", "C", "E", "O", "E", "C", "C", "C", "K"],
                ["K", "C", "E", "E", "C", "C", "E", "O", "C", "K"],
                ["K", "C", "C", "C", "C", "C", "C", "E", "C", "K"],
                ["K", "C", "O", "C", "C", "C", "C", "C", "C", "K"],
                ["K", "C", "C", "C", "E", "C", "C", "C", "C", "K"],
                ["K", "C", "C", "C", "C", "C", "O", "C", "C", "K"],
                [".", "K", "C", "C", "C", "C", "C", "C", "K", "."],
                [".", ".", "K", "K", "K", "K", "K", "K", ".", "."]
            ]
            
        case 1: // Baby
            return [
                [".", "E", "E", ".", ".", ".", ".", "E", "E", "."],
                ["E", "E", "O", "E", ".", ".", "E", "O", "E", "E"],
                ["E", "E", "E", "K", "K", "K", "K", "E", "E", "E"],
                [".", "K", "D", "D", "C", "C", "D", "D", "K", "."],
                [".", "K", "D", "C", "C", "C", "C", "D", "K", "."],
                [".", ".", "K", "C", "K", "K", "C", "K", ".", "."],
                [".", ".", "K", "N", "N", "N", "N", "K", ".", "."],
                [".", ".", "K", "C", "C", "C", "C", "K", ".", "."],
                [".", "K", "C", "K", ".", ".", "K", "C", "K", "."],
                [".", "K", "K", ".", ".", ".", ".", "K", "K", "."]
            ]
            
        case 2: // Child
            return [
                [".", "E", "E", ".", ".", ".", ".", ".", "E", "E"],
                ["E", "E", "O", "E", ".", ".", ".", "E", "O", "E"],
                ["E", "E", "E", "E", "K", "K", "K", "E", "E", "E"],
                [".", "K", "D", "D", "D", "C", "D", "D", "D", "K"],
                [".", "K", "D", "D", "C", "C", "C", "D", "D", "K"],
                [".", ".", "K", "C", "C", "K", "C", "C", "K", "."],
                [".", ".", "K", "N", "N", "N", "N", "N", "K", "."],
                [".", ".", "K", "T", "T", "T", "T", "T", "K", "."],
                [".", ".", "K", "C", "C", "C", "C", "C", "K", "."],
                [".", ".", "K", "C", "C", "C", "C", "C", "K", "."],
                [".", "K", "C", "K", "C", "K", "C", "K", "C", "K"],
                [".", "K", "K", ".", "K", "K", "K", "K", ".", "K"]
            ]
            
        case 3: // Teen
            return [
                [".", "E", "E", "E", ".", ".", ".", ".", ".", "E"],
                ["E", "E", "O", "E", "E", ".", ".", ".", "E", "O"],
                ["E", "E", "E", "E", "E", "K", "K", "K", "E", "E"],
                [".", "K", "D", "D", "D", "D", "C", "D", "D", "D"],
                [".", "K", "D", "D", "C", "C", "C", "C", "D", "D"],
                [".", ".", "K", "C", "C", "C", "K", "C", "C", "K"],
                [".", ".", "K", "C", "N", "N", "N", "N", "C", "K"],
                [".", ".", "K", "T", "T", "T", "T", "T", "T", "K"],
                [".", ".", "K", "C", "C", "C", "C", "C", "C", "K"],
                [".", "K", "C", "C", "C", "C", "C", "C", "C", "C"],
                [".", "K", "C", "C", "C", "C", "C", "C", "C", "C"],
                ["K", "C", "K", "C", "K", "C", "K", "C", "K", "C"],
                ["K", "B", "K", "K", "K", "B", "K", "K", "K", "B"]
            ]
            
        case 4: // Adult
            return [
                [".", ".", "Y", ".", "Y", ".", "Y", ".", "Y", "."],
                [".", "Y", "Y", "Y", "Y", "Y", "Y", "Y", "Y", "Y"],
                [".", "E", "E", "Y", "Y", "Y", "Y", "Y", "E", "E"],
                ["E", "E", "O", "E", "E", ".", ".", "E", "O", "E"],
                ["E", "E", "E", "E", "E", "K", "K", "E", "E", "E"],
                [".", "K", "D", "D", "D", "D", "D", "D", "D", "K"],
                [".", "K", "D", "D", "C", "C", "C", "D", "D", "K"],
                [".", ".", "K", "C", "C", "C", "K", "C", "K", "."],
                [".", ".", "K", "N", "N", "N", "N", "N", "K", "."],
                [".", ".", "K", "Y", "T", "T", "T", "Y", "K", "."],
                [".", ".", "K", "C", "C", "C", "C", "C", "K", "."],
                [".", "K", "C", "C", "C", "C", "C", "C", "C", "K"],
                ["K", "C", "K", "C", "K", "C", "K", "C", "K", "C"],
                ["K", "B", "K", "K", "K", "B", "K", "K", "K", "B"]
            ]
            
        default:
            // Fallback to adult stage (stage 4)
            return [
                [".", ".", "Y", ".", "Y", ".", "Y", ".", "Y", "."],
                [".", "Y", "Y", "Y", "Y", "Y", "Y", "Y", "Y", "Y"],
                [".", "E", "E", "Y", "Y", "Y", "Y", "Y", "E", "E"],
                ["E", "E", "O", "E", "E", ".", ".", "E", "O", "E"],
                ["E", "E", "E", "E", "E", "K", "K", "E", "E", "E"],
                [".", "K", "D", "D", "D", "D", "D", "D", "D", "K"],
                [".", "K", "D", "D", "C", "C", "C", "D", "D", "K"],
                [".", ".", "K", "C", "C", "C", "K", "C", "K", "."],
                [".", ".", "K", "N", "N", "N", "N", "N", "K", "."],
                [".", ".", "K", "Y", "T", "T", "T", "Y", "K", "."],
                [".", ".", "K", "C", "C", "C", "C", "C", "K", "."],
                [".", "K", "C", "C", "C", "C", "C", "C", "C", "K"],
                ["K", "C", "K", "C", "K", "C", "K", "C", "K", "C"],
                ["K", "B", "K", "K", "K", "B", "K", "K", "K", "B"]
            ]
        }
    }
}

// MARK: - Pixel Grid Renderer

struct PixelGrid: View {
    let pixels: [[String]]
    let scale: CGFloat
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(pixels.indices, id: \.self) { rowIndex in
                HStack(spacing: 0) {
                    ForEach(pixels[rowIndex].indices, id: \.self) { colIndex in
                        let pixel = pixels[rowIndex][colIndex]
                        Rectangle()
                            .fill(getColor(for: pixel))
                            .frame(width: scale, height: scale)
                    }
                }
            }
        }
    }
    
    private func getColor(for pixel: String) -> Color {
        switch pixel {
        case ".": return .clear
        case "K": return .black
        case "W": return .white
        case "G": return Color(red: 0.56, green: 0.93, blue: 0.56) // Light green
        case "g": return Color(red: 0.13, green: 0.55, blue: 0.13) // Dark green
        case "P": return Color(red: 1.0, green: 0.71, blue: 0.76) // Pink
        case "p": return Color(red: 1.0, green: 0.41, blue: 0.71) // Hot pink
        case "C": return Color(red: 1.0, green: 0.89, blue: 0.77) // Cream
        case "c": return Color(red: 0.96, green: 0.87, blue: 0.70) // Wheat
        case "E": return Color(red: 1.0, green: 0.71, blue: 0.85) // Pink ears
        case "e": return Color(red: 1.0, green: 0.60, blue: 0.80) // Light pink
        case "O": return Color(red: 1.0, green: 0.65, blue: 0.0) // Orange
        case "o": return Color(red: 1.0, green: 0.55, blue: 0.0) // Dark orange
        case "D": return Color(red: 0.18, green: 0.31, blue: 0.31) // Dark patches
        case "d": return Color(red: 0.33, green: 0.42, blue: 0.18) // Olive
        case "N": return Color(red: 0.55, green: 0.27, blue: 0.07) // Brown
        case "n": return Color(red: 0.40, green: 0.20, blue: 0.13) // Dark brown
        case "T": return Color(red: 0.25, green: 0.88, blue: 0.82) // Turquoise
        case "t": return Color(red: 0.13, green: 0.70, blue: 0.67) // Light sea green
        case "B": return Color(red: 0.55, green: 0.27, blue: 0.07) // Brown
        case "Y": return Color(red: 1.0, green: 0.84, blue: 0.0) // Gold
        case "y": return Color(red: 1.0, green: 0.65, blue: 0.0) // Gold shading
        case "M": return Color(red: 0.60, green: 0.20, blue: 0.80) // Purple
        case "m": return Color(red: 0.55, green: 0.0, blue: 0.55) // Magenta
        case "S": return Color(red: 0.75, green: 0.75, blue: 0.75) // Silver
        default: return .red // Debug: show red for unknown pixels
        }
    }
}

// MARK: - Animation Modifier

struct AnimationModifier: ViewModifier {
    let animation: PetAnimation
    let trickVariant: Int
    let trigger: UUID
    
    @State private var rotationAngle: Double = 0
    @State private var offsetY: CGFloat = 0
    @State private var offsetX: CGFloat = 0
    @State private var scale: CGFloat = 1.0
    
    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(rotationAngle))
            .offset(x: offsetX, y: offsetY)
            .scaleEffect(scale)
            .onAppear {
                if animation == .idle {
                    startIdleAnimation()
                }
            }
            .onChange(of: trigger) { _, _ in
                performAnimation()
            }
    }
    
    private func startIdleAnimation() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            offsetY = -8
        }
    }
    
    private func performAnimation() {
        // Reset
        rotationAngle = 0
        offsetY = 0
        offsetX = 0
        scale = 1.0
        
        switch animation {
        case .trick:
            performTrickAnimation()
        case .pet:
            performPetAnimation()
        case .nap:
            performNapAnimation()
        case .idle:
            startIdleAnimation()
        }
    }
    
    private func performTrickAnimation() {
        switch trickVariant {
        case 0: // Spin
            withAnimation(.easeInOut(duration: 0.8)) {
                rotationAngle = 360
                scale = 1.2
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                rotationAngle = 0
                scale = 1.0
            }
            
        case 1: // Jump & Flip
            withAnimation(.easeOut(duration: 0.5)) {
                offsetY = -60
                rotationAngle = 180
            }
            withAnimation(.easeIn(duration: 0.5).delay(0.5)) {
                offsetY = 0
                rotationAngle = 360
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                rotationAngle = 0
            }
            
        case 2: // Bounce
            for i in 0..<3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.3) {
                    withAnimation(.easeOut(duration: 0.15)) {
                        offsetY = CGFloat(-20 + i * 5)
                    }
                    withAnimation(.easeIn(duration: 0.15).delay(0.15)) {
                        offsetY = 0
                    }
                }
            }
            
        case 3: // Shake
            for i in 0..<6 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.1) {
                    withAnimation(.linear(duration: 0.1)) {
                        rotationAngle = i % 2 == 0 ? 15 : -15
                        offsetX = i % 2 == 0 ? 5 : -5
                    }
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                rotationAngle = 0
                offsetX = 0
            }
            
        case 4: // Wave/Bow
            withAnimation(.easeInOut(duration: 0.4)) {
                rotationAngle = -20
                offsetY = 5
            }
            withAnimation(.easeInOut(duration: 0.4).delay(0.4)) {
                rotationAngle = -25
                offsetY = 10
            }
            withAnimation(.easeInOut(duration: 0.4).delay(0.8)) {
                rotationAngle = 0
                offsetY = 0
            }
            
        default:
            break
        }
    }
    
    private func performPetAnimation() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            offsetY = -10
            scale = 1.05
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.3)) {
            offsetY = 0
            scale = 1.0
        }
    }
    
    private func performNapAnimation() {
        withAnimation(.easeInOut(duration: 0.5)) {
            rotationAngle = 90
            scale = 0.9
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            withAnimation(.easeInOut(duration: 0.5)) {
                rotationAngle = 0
                scale = 1.0
            }
        }
    }
}

enum PetMood {
    case happy
    case neutral
    case sad
}

#Preview {
    ZStack {
        Color.blue.opacity(0.3).ignoresSafeArea()
        
        VStack(spacing: 30) {
            PixelPet(
                stage: 3,
                mood: .happy,
                isActive: true,
                petType: .cat,
                healthState: .healthy,
                currentAnimation: .idle,
                trickVariant: 0
            )
            
            PixelPet(
                stage: 2,
                mood: .happy,
                isActive: true,
                petType: .dog,
                healthState: .healthy,
                currentAnimation: .idle,
                trickVariant: 0
            )
        }
    }
}
