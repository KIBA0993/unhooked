//
//  PixelPet.swift
//  Unhooked
//
//  Animated pet display
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
    
    @State private var bounceOffset: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0
    @State private var showHearts = false
    @State private var showStars = false
    @State private var showZzz = false
    
    private var petEmoji: String {
        switch (petType, healthState) {
        case (.cat, .healthy):
            return mood == .happy ? "😺" : mood == .sad ? "😿" : "😸"
        case (.cat, .sick):
            return "🤒"
        case (.cat, .dead):
            return "👻"
        case (.dog, .healthy):
            return mood == .happy ? "🐶" : mood == .sad ? "😢" : "🐕"
        case (.dog, .sick):
            return "🤒"
        case (.dog, .dead):
            return "👻"
        }
    }
    
    private var petSize: CGFloat {
        let baseSize: CGFloat = 120
        let stageMultiplier = 1.0 + (Double(stage) * 0.15)
        return baseSize * stageMultiplier
    }
    
    var body: some View {
        ZStack {
            // Pet
            Text(petEmoji)
                .font(.system(size: petSize))
                .offset(y: bounceOffset)
                .rotationEffect(.degrees(rotation))
                .scaleEffect(scale)
                .grayscale(healthState == .dead ? 1.0 : 0.0)
                .opacity(healthState == .dead ? 0.5 : 1.0)
            
            // Health indicator overlay
            if healthState == .sick {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "thermometer.medium")
                            .font(.system(size: 24))
                            .foregroundStyle(.orange)
                            .padding(4)
                    }
                }
                .frame(width: petSize, height: petSize)
            }
            
            // Animation overlays
            if showHearts {
                heartsOverlay
            }
            
            if showStars {
                starsOverlay
            }
            
            if showZzz {
                zzzOverlay
            }
        }
        .frame(width: petSize + 40, height: petSize + 40)
        .onChange(of: currentAnimation) { _, newValue in
            playAnimation(newValue)
        }
        .onAppear {
            startIdleAnimation()
        }
    }
    
    // MARK: - Overlays
    
    private var heartsOverlay: some View {
        ForEach(0..<3, id: \.self) { index in
            Text("❤️")
                .font(.system(size: 24))
                .offset(
                    x: CGFloat([-20, 0, 20][index]),
                    y: -petSize / 2 - 20
                )
                .transition(.scale.combined(with: .opacity))
        }
    }
    
    private var starsOverlay: some View {
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
    
    private var zzzOverlay: some View {
        VStack(spacing: -8) {
            ForEach(0..<3, id: \.self) { index in
                Text("Z")
                    .font(.system(size: CGFloat(16 + index * 4)))
                    .foregroundColor(.blue.opacity(0.7))
                    .offset(x: CGFloat(index * 8))
            }
        }
        .offset(x: petSize / 2 + 20, y: -petSize / 2)
        .transition(.opacity)
    }
    
    // MARK: - Animations
    
    private func playAnimation(_ animation: PetAnimation) {
        // Reset previous animations
        showHearts = false
        showStars = false
        showZzz = false
        
        switch animation {
        case .idle:
            startIdleAnimation()
            
        case .trick:
            playTrickAnimation()
            
        case .pet:
            playPetAnimation()
            
        case .nap:
            playNapAnimation()
        }
    }
    
    private func startIdleAnimation() {
        guard currentAnimation == .idle else { return }
        
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            bounceOffset = -8
        }
    }
    
    private func playTrickAnimation() {
        // Different tricks based on variant
        let animations: [() -> Void] = [
            spinTrick,
            jumpTrick,
            shakeTrick,
            bounceTrick,
            waveTrick
        ]
        
        let variant = min(trickVariant, animations.count - 1)
        animations[variant]()
    }
    
    private func spinTrick() {
        bounceOffset = 0
        withAnimation(.easeInOut(duration: 0.8)) {
            rotation = 360
            showStars = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            rotation = 0
            showStars = false
        }
    }
    
    private func jumpTrick() {
        bounceOffset = 0
        withAnimation(.easeOut(duration: 0.4)) {
            bounceOffset = -40
            showStars = true
        }
        
        withAnimation(.easeIn(duration: 0.4).delay(0.4)) {
            bounceOffset = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            showStars = false
        }
    }
    
    private func shakeTrick() {
        bounceOffset = 0
        let shakeAnimation = Animation.easeInOut(duration: 0.1).repeatCount(6, autoreverses: true)
        
        withAnimation(shakeAnimation) {
            rotation = 10
        }
        
        showStars = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            rotation = 0
            showStars = false
        }
    }
    
    private func bounceTrick() {
        bounceOffset = 0
        showStars = true
        
        withAnimation(.easeOut(duration: 0.2)) {
            bounceOffset = -20
            scale = 1.2
        }
        
        withAnimation(.easeIn(duration: 0.2).delay(0.2)) {
            bounceOffset = 0
            scale = 1.0
        }
        
        withAnimation(.easeOut(duration: 0.15).delay(0.4)) {
            bounceOffset = -15
        }
        
        withAnimation(.easeIn(duration: 0.15).delay(0.55)) {
            bounceOffset = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            showStars = false
        }
    }
    
    private func waveTrick() {
        bounceOffset = 0
        showStars = true
        
        withAnimation(.easeInOut(duration: 0.3)) {
            rotation = -20
        }
        
        withAnimation(.easeInOut(duration: 0.3).delay(0.3)) {
            rotation = 20
        }
        
        withAnimation(.easeInOut(duration: 0.3).delay(0.6)) {
            rotation = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            showStars = false
        }
    }
    
    private func playPetAnimation() {
        bounceOffset = 0
        showHearts = true
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            scale = 1.15
        }
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.3)) {
            scale = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            showHearts = false
        }
    }
    
    private func playNapAnimation() {
        bounceOffset = 0
        showZzz = true
        
        withAnimation(.easeInOut(duration: 0.5)) {
            rotation = 90
            scale = 0.8
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            withAnimation(.easeInOut(duration: 0.5)) {
                rotation = 0
                scale = 1.0
                showZzz = false
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
    VStack(spacing: 30) {
        PixelPet(
            stage: 2,
            mood: .happy,
            isActive: true,
            petType: .cat,
            healthState: .healthy,
            currentAnimation: .idle,
            trickVariant: 0
        )
        
        PixelPet(
            stage: 1,
            mood: .sad,
            isActive: true,
            petType: .dog,
            healthState: .sick,
            currentAnimation: .idle,
            trickVariant: 0
        )
    }
    .padding()
    .background(Color.white)
}


