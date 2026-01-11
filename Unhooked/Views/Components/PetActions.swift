//
//  PetActions.swift
//  Unhooked
//
//  Pet interaction buttons (trick, pet, nap) - Expandable circular menu
//

import SwiftUI

struct PetActions: View {
    let healthState: HealthState
    let mood: Int
    let onMoodChange: (Int) -> Void
    let onTriggerAnimation: (PetAnimation, Int?) -> Void
    
    @State private var isExpanded = false
    
    private var canTrick: Bool {
        healthState == .healthy
    }
    
    private var canPet: Bool {
        true // Always available
    }
    
    private var canNap: Bool {
        healthState != .dead
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Expanded action buttons (above)
            if isExpanded {
                VStack(spacing: 8) {
                    // Nap button (top)
                    if canNap {
                        actionButton(
                            icon: "moon.fill",
                            gradient: healthState == .healthy ?
                                [Color(red: 0.4, green: 0.7, blue: 1.0), Color(red: 0.35, green: 0.6, blue: 0.9)] :
                                [Color.gray.opacity(0.7), Color.gray.opacity(0.6)],
                            action: {
                                isExpanded = false
                                onTriggerAnimation(.nap, nil)
                            }
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Pet button (middle)
                    actionButton(
                        icon: "heart.fill",
                        gradient: healthState == .healthy ?
                            [Color(red: 1.0, green: 0.4, blue: 0.8), Color(red: 0.95, green: 0.35, blue: 0.75)] :
                            healthState == .sick ?
                            [Color(red: 0.8, green: 0.5, blue: 1.0), Color(red: 0.7, green: 0.4, blue: 0.9)] :
                            [Color.gray.opacity(0.6), Color.gray.opacity(0.5)],
                        action: {
                            isExpanded = false
                            onTriggerAnimation(.pet, nil)
                            onMoodChange(healthState == .dead ? 0 : 1)
                        }
                    )
                    .transition(.scale.combined(with: .opacity))
                    
                    // Trick button (bottom, just above main button)
                    if canTrick {
                        actionButton(
                            icon: "star.fill",
                            gradient: [Color(red: 1.0, green: 0.7, blue: 0.25), Color(red: 1.0, green: 0.6, blue: 0.0)],
                            action: {
                                isExpanded = false
                                let variant = Int.random(in: 0...4)
                                onTriggerAnimation(.trick, variant)
                                onMoodChange(1)
                            }
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.bottom, 8)
            }
            
            // Main menu button (hand icon)
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            } label: {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 64, height: 64)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.8, green: 0.5, blue: 1.0), Color(red: 0.6, green: 0.3, blue: 0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.black, lineWidth: 3))
                    .shadow(color: .black.opacity(0.3), radius: 0, x: 4, y: 4)
            }
            .buttonStyle(.plain)
            .scaleEffect(isExpanded ? 1.0 : 1.0) // No scale change
            .rotationEffect(isExpanded ? .degrees(20) : .degrees(0))
        }
    }
    
    // MARK: - Action Button
    
    @ViewBuilder
    private func actionButton(icon: String, gradient: [Color], action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    LinearGradient(
                        colors: gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.black, lineWidth: 3))
                .shadow(color: .black.opacity(0.3), radius: 0, x: 3, y: 3)
        }
        .buttonStyle(.plain)
    }
}

enum PetAnimation {
    case idle
    case trick
    case pet
    case nap
    case eating
}

#Preview {
    ZStack {
        Color.blue.opacity(0.3).ignoresSafeArea()
        
        VStack {
            Spacer()
            HStack {
                Spacer()
                PetActions(
                    healthState: .healthy,
                    mood: 5,
                    onMoodChange: { _ in },
                    onTriggerAnimation: { _, _ in }
                )
                .padding(24)
            }
        }
    }
}
