//
//  FeedingAnimationView.swift
//  Unhooked
//
//  Feeding animation matching Figma design - 3 variants
//

import SwiftUI

struct FeedingAnimationView: View {
    let foodEmoji: String
    let variant: Int // 0, 1, or 2
    @Binding var isActive: Bool
    
    var body: some View {
        ZStack {
            switch variant {
            case 0:
                fallingFoodAnimation
            case 1:
                burstAnimation
            case 2:
                circlingAnimation
            default:
                EmptyView()
            }
            
            // "YUM! ✨" text
            yumText
        }
        .onAppear {
            // Start the animation progress
            withAnimation(.easeInOut(duration: 2.0)) {
                animationProgress = 1.0
            }
            
            // Auto-dismiss after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                isActive = false
            }
        }
    }
    
    // MARK: - Variant 0: Falling Food
    
    private var fallingFoodAnimation: some View {
        ForEach(0..<5, id: \.self) { index in
            FallingFoodItem(emoji: foodEmoji, index: index)
        }
    }
    
    // MARK: - Variant 1: Burst Effect
    
    private var burstAnimation: some View {
        ZStack {
            // Center food with rotation
            Text(foodEmoji)
                .font(.system(size: 80))
                .shadow(color: .black.opacity(0.3), radius: 0, x: 3, y: 3)
                .scaleEffect(animationProgress * 1.5)
                .rotationEffect(.degrees(animationProgress * 360))
                .opacity(animationProgress < 0.8 ? 1 : 0)
            
            // Pixel sparkle burst
            ForEach(0..<8, id: \.self) { index in
                PixelSparkle(index: index)
            }
        }
    }
    
    // MARK: - Variant 2: Circling Food
    
    private var circlingAnimation: some View {
        ZStack {
            // Circling food items
            ForEach(0..<6, id: \.self) { index in
                CirclingFoodItem(emoji: foodEmoji, index: index)
            }
            
            // Center glow
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.green.opacity(0.6), Color(red: 0.13, green: 0.86, blue: 0.6).opacity(0.6)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 80, height: 80)
                .blur(radius: 40)
                .scaleEffect(animationProgress * 2)
                .opacity(animationProgress < 0.5 ? animationProgress * 1.2 : (1 - animationProgress) * 1.2)
        }
    }
    
    // MARK: - Yum Text
    
    private var yumText: some View {
        Text("YUM! ✨")
            .font(.system(size: 32, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.96, green: 0.4, blue: 0.78), Color(red: 0.75, green: 0.53, blue: 0.95)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(Color.black, lineWidth: 4)
            )
            .shadow(color: .black, radius: 0, x: 4, y: 4)
            .scaleEffect(animationProgress > 0.25 && animationProgress < 0.9 ? 1 + (animationProgress - 0.25) * 0.2 : 0)
            .offset(y: animationProgress > 0.25 ? -60 : 20)
            .opacity(animationProgress > 0.25 && animationProgress < 0.9 ? 1 : 0)
    }
    
    // Animation progress (0 to 1)
    @State private var animationProgress: Double = 0
    
    init(foodEmoji: String, variant: Int, isActive: Binding<Bool>) {
        self.foodEmoji = foodEmoji
        self.variant = variant
        self._isActive = isActive
    }
}

// MARK: - Supporting Views

struct FallingFoodItem: View {
    let emoji: String
    let index: Int
    @State private var progress: Double = 0
    
    var body: some View {
        Text(emoji)
            .font(.system(size: 40))
            .shadow(color: .black.opacity(0.3), radius: 0, x: 2, y: 2)
            .scaleEffect(progress > 0 ? 1 + progress * 0.2 : 0)
            .rotationEffect(.degrees(progress * 360))
            .offset(
                x: CGFloat((index - 2) * 40),
                y: -40 + progress * 280
            )
            .opacity(progress > 0 && progress < 0.9 ? 1 : 0)
            .onAppear {
                withAnimation(.easeIn(duration: 1.5).delay(Double(index) * 0.15)) {
                    progress = 1.0
                }
            }
    }
}

struct PixelSparkle: View {
    let index: Int
    @State private var progress: Double = 0
    
    var body: some View {
        Rectangle()
            .fill(Color.yellow)
            .frame(width: 12, height: 12)
            .overlay(
                Rectangle()
                    .stroke(Color(red: 0.8, green: 0.6, blue: 0), lineWidth: 2)
            )
            .offset(
                x: progress * cos(Double(index) * .pi / 4) * 60,
                y: progress * sin(Double(index) * .pi / 4) * 60
            )
            .opacity(1 - progress)
            .onAppear {
                withAnimation(.linear(duration: 1).delay(0.3)) {
                    progress = 1.0
                }
            }
    }
}

struct CirclingFoodItem: View {
    let emoji: String
    let index: Int
    @State private var progress: Double = 0
    
    var body: some View {
        Text(emoji)
            .font(.system(size: 32))
            .shadow(color: .black.opacity(0.3), radius: 0, x: 2, y: 2)
            .scaleEffect(progress > 0 ? 0.5 + progress * 0.5 : 0)
            .rotationEffect(.degrees(progress * 360))
            .offset(
                x: progress < 1 ? cos(Double(index) * .pi / 3) * 80 * progress : 0,
                y: progress < 1 ? sin(Double(index) * .pi / 3) * 80 * progress : 0
            )
            .opacity(progress > 0 && progress < 0.8 ? 1 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 2).delay(Double(index) * 0.1)) {
                    progress = 1.0
                }
            }
    }
}

#Preview {
    ZStack {
        Color.blue.opacity(0.3)
        FeedingAnimationView(foodEmoji: "🍖", variant: 0, isActive: .constant(true))
    }
}


