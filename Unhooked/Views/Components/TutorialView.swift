//
//  TutorialView.swift
//  Unhooked
//
//  Multi-step tutorial matching Figma design
//

import SwiftUI

struct TutorialView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStep = 0
    
    private let steps: [TutorialStep] = [
        TutorialStep(
            title: "Welcome to Unhooked! 🎮",
            description: "Build healthier phone habits while caring for your virtual friend",
            icon: "sparkles",
            gradientColors: [Color(red: 0.73, green: 0.33, blue: 1.0), Color(red: 1.0, green: 0.4, blue: 0.8)],
            showPet: false,
            showHealthStates: false
        ),
        TutorialStep(
            title: "Earn Energy ⚡",
            description: "Stay under your daily screen time limit to earn Energy. The less time you spend on your phone, the more Energy you'll collect!",
            icon: "bolt.fill",
            gradientColors: [Color(red: 1.0, green: 0.8, blue: 0.25), Color(red: 1.0, green: 0.6, blue: 0.3)],
            showPet: true,
            showHealthStates: false
        ),
        TutorialStep(
            title: "Feed Your Friend 🍖",
            description: "Spend Energy on food to keep your pet happy and healthy. Different foods have different effects!",
            icon: "heart.fill",
            gradientColors: [Color(red: 0.4, green: 0.9, blue: 0.4), Color(red: 0.13, green: 0.86, blue: 0.6)],
            showPet: true,
            showHealthStates: false
        ),
        TutorialStep(
            title: "Watch Them Grow 📈",
            description: "Feed your pet daily to help them grow through 5 evolution stages. Consistent care leads to growth!",
            icon: "chart.line.uptrend.xyaxis",
            gradientColors: [Color(red: 0.4, green: 0.7, blue: 1.0), Color(red: 0.4, green: 0.86, blue: 0.86)],
            showPet: true,
            showHealthStates: false,
            petStage: 2
        ),
        TutorialStep(
            title: "Keep Them Healthy ❤️",
            description: "Missing meals can make your pet sick. Feed them daily to keep them happy and avoid the recovery cost!",
            icon: "exclamationmark.triangle.fill",
            gradientColors: [Color(red: 0.96, green: 0.4, blue: 0.4), Color(red: 1.0, green: 0.47, blue: 0.5)],
            showPet: false,
            showHealthStates: true
        ),
        TutorialStep(
            title: "Ready to Start! 🎉",
            description: "Your new friend is waiting! Check in daily, earn Energy, and watch them thrive.",
            icon: "sparkles",
            gradientColors: [Color(red: 0.73, green: 0.33, blue: 1.0), Color(red: 1.0, green: 0.4, blue: 0.8)],
            showPet: true,
            showHealthStates: false
        )
    ]
    
    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            // Tutorial Card
            VStack(spacing: 0) {
                // Skip Button
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    .padding()
                }
                
                // Content
                VStack(spacing: 0) {
                    // Visual Area
                    ZStack {
                        LinearGradient(
                            colors: steps[currentStep].gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        
                        if steps[currentStep].showPet {
                            PixelPet(
                                stage: steps[currentStep].petStage,
                                mood: .happy,
                                isActive: true,
                                petType: .cat,
                                healthState: .healthy,
                                currentAnimation: .idle,
                                trickVariant: 0
                            )
                            .scaleEffect(2.0)
                        } else if steps[currentStep].showHealthStates {
                            healthStatesView
                        } else {
                            Image(systemName: steps[currentStep].icon)
                                .font(.system(size: 48, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.black, lineWidth: 3)
                    )
                    .padding(.horizontal, 32)
                    .padding(.bottom, 24)
                    
                    // Title
                    Text(steps[currentStep].title)
                        .font(.system(size: 28, weight: .bold))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.bottom, 12)
                    
                    // Description
                    Text(steps[currentStep].description)
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 24)
                    
                    // Progress Dots
                    HStack(spacing: 8) {
                        ForEach(0..<steps.count, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(index == currentStep ? Color.purple : Color.gray.opacity(0.3))
                                .frame(width: index == currentStep ? 32 : 8, height: 8)
                                .animation(.spring(response: 0.3), value: currentStep)
                        }
                    }
                    .padding(.bottom, 24)
                    
                    // Navigation Buttons
                    HStack(spacing: 12) {
                        if currentStep > 0 {
                            Button {
                                withAnimation {
                                    currentStep -= 1
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Back")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.white)
                                .foregroundColor(.black)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.black, lineWidth: 2)
                                )
                            }
                        }
                        
                        Button {
                            if currentStep < steps.count - 1 {
                                withAnimation {
                                    currentStep += 1
                                }
                            } else {
                                dismiss()
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(currentStep == steps.count - 1 ? "Let's Go!" : "Next")
                                    .font(.system(size: 16, weight: .bold))
                                if currentStep < steps.count - 1 {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 0.63, green: 0.33, blue: 1.0), Color(red: 1.0, green: 0.4, blue: 0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.black, lineWidth: 2)
                            )
                            .shadow(color: .black, radius: 0, x: 2, y: 2)
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
                }
            }
            .frame(maxWidth: 480)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.black, lineWidth: 4)
            )
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 16)
        }
    }
    
    private var healthStatesView: some View {
        HStack(spacing: 16) {
            // Healthy
            VStack(spacing: 8) {
                PixelPet(
                    stage: 0,
                    mood: .happy,
                    isActive: true,
                    petType: .cat,
                    healthState: .healthy,
                    currentAnimation: .idle,
                    trickVariant: 0
                )
                .scaleEffect(1.5)
                
                Text("Healthy")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Image(systemName: "arrow.right")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            // Sick
            VStack(spacing: 8) {
                PixelPet(
                    stage: 0,
                    mood: .sad,
                    isActive: true,
                    petType: .cat,
                    healthState: .sick,
                    currentAnimation: .idle,
                    trickVariant: 0
                )
                .scaleEffect(1.5)
                
                Text("Sick")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.2))
            }
            
            Image(systemName: "arrow.right")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            // Dead
            VStack(spacing: 8) {
                PixelPet(
                    stage: 0,
                    mood: .sad,
                    isActive: false,
                    petType: .cat,
                    healthState: .dead,
                    currentAnimation: .idle,
                    trickVariant: 0
                )
                .scaleEffect(1.5)
                .opacity(0.5)
                
                Text("Dead")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
    }
}

// MARK: - Tutorial Step Model

struct TutorialStep {
    let title: String
    let description: String
    let icon: String
    let gradientColors: [Color]
    let showPet: Bool
    let showHealthStates: Bool
    var petStage: Int = 0
}

#Preview {
    ZStack {
        Color.purple.opacity(0.3)
            .ignoresSafeArea()
        
        TutorialView()
    }
}



