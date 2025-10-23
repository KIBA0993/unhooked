//
//  RetroStyleModifiers.swift
//  Unhooked
//
//  Retro/pixel art styling utilities
//

import SwiftUI

// MARK: - Retro Shadow Modifier

struct RetroShadowModifier: ViewModifier {
    var color: Color = .black
    var offset: CGFloat = 4
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color, radius: 0, x: offset, y: offset)
    }
}

// MARK: - Retro Border Modifier

struct RetroBorderModifier: ViewModifier {
    var borderWidth: CGFloat = 3
    var borderColor: Color = .black
    var cornerRadius: CGFloat = 12
    
    func body(content: Content) -> some View {
        content
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
    }
}

// MARK: - Retro Button Style

struct RetroButtonStyle: ButtonStyle {
    var backgroundColor: Color = .blue
    var pressedScale: CGFloat = 0.95
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(backgroundColor)
            .foregroundColor(.white)
            .font(.system(size: 16, weight: .bold))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.black, lineWidth: 3)
            )
            .shadow(color: .black, radius: 0, x: 4, y: 4)
            .scaleEffect(configuration.isPressed ? pressedScale : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Solid Colors (matching Figma design)

struct RetroColors {
    // Primary colors - vibrant and bold
    static let yellow = Color(red: 1.0, green: 0.8, blue: 0.0)        // Energy
    static let pink = Color(red: 1.0, green: 0.4, blue: 0.8)          // Gems/Pet
    static let orange = Color(red: 1.0, green: 0.6, blue: 0.0)        // Trick
    static let green = Color(red: 0.0, green: 0.9, blue: 0.4)         // Feed
    static let blue = Color(red: 0.4, green: 0.7, blue: 1.0)          // Nap
    static let purple = Color(red: 0.8, green: 0.5, blue: 1.0)        // Stage badge
    
    // Stat backgrounds - pastel
    static let lightBlue = Color(red: 0.85, green: 0.95, blue: 1.0)   // Fullness
    static let lightPink = Color(red: 1.0, green: 0.85, blue: 0.95)   // Mood
    
    // Background
    static let background = Color(red: 0.92, green: 0.85, blue: 1.0)  // Light lavender
    
    // UI elements
    static let border = Color.black
    static let white = Color.white
}

// MARK: - Gradient Backgrounds (for backwards compatibility)

struct RetroGradients {
    static let purple = LinearGradient(
        colors: [RetroColors.purple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let pink = LinearGradient(
        colors: [RetroColors.pink],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let green = LinearGradient(
        colors: [RetroColors.green],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let orange = LinearGradient(
        colors: [RetroColors.orange],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let background = LinearGradient(
        colors: [RetroColors.background],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - View Extensions

extension View {
    func retroShadow(color: Color = .black, offset: CGFloat = 4) -> some View {
        modifier(RetroShadowModifier(color: color, offset: offset))
    }
    
    func retroBorder(width: CGFloat = 3, color: Color = .black, cornerRadius: CGFloat = 12) -> some View {
        modifier(RetroBorderModifier(borderWidth: width, borderColor: color, cornerRadius: cornerRadius))
    }
    
    func retroCard(backgroundColor: Color = .white) -> some View {
        self
            .padding()
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .retroBorder()
            .retroShadow()
    }
}

// MARK: - Evolution Stages

struct EvolutionStage {
    let name: String
    let threshold: Int
    let emoji: String
}

struct EvolutionStages {
    static let stages: [EvolutionStage] = [
        EvolutionStage(name: "Baby", threshold: 0, emoji: "🥚"),
        EvolutionStage(name: "Young", threshold: 50, emoji: "🐣"),
        EvolutionStage(name: "Teen", threshold: 100, emoji: "🐥"),
        EvolutionStage(name: "Adult", threshold: 200, emoji: "🐦"),
        EvolutionStage(name: "Elder", threshold: 350, emoji: "🦅")
    ]
    
    static func getCurrentStage(progress: Int) -> (stage: Int, current: EvolutionStage, next: EvolutionStage?) {
        for (index, stage) in stages.enumerated() {
            if index + 1 < stages.count {
                let nextStage = stages[index + 1]
                if progress >= stage.threshold && progress < nextStage.threshold {
                    return (index, stage, nextStage)
                }
            } else {
                // Max stage
                if progress >= stage.threshold {
                    return (index, stage, nil)
                }
            }
        }
        return (0, stages[0], stages.count > 1 ? stages[1] : nil)
    }
}

