//
//  PetActions.swift
//  Unhooked
//
//  Pet interaction buttons (trick, pet, nap)
//

import SwiftUI

struct PetActions: View {
    let healthState: HealthState
    let mood: Int
    let onMoodChange: (Int) -> Void
    let onTriggerAnimation: (PetAnimation, Int?) -> Void
    
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
        HStack(spacing: 12) {
            // Trick button
            Button {
                if canTrick {
                    let variant = Int.random(in: 0...4)
                    onTriggerAnimation(.trick, variant)
                    onMoodChange(1)
                }
            } label: {
                VStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 28))
                    Text("TRICK")
                        .font(.system(size: 14, weight: .black))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 90)
                .background(canTrick ? RetroColors.orange : Color.gray.opacity(0.5))
                .foregroundColor(.black)
                .retroBorder(width: 4, cornerRadius: 12)
                .retroShadow(offset: 4)
            }
            .disabled(!canTrick)
            .buttonStyle(.plain)
            
            // Pet button
            Button {
                if canPet {
                    onTriggerAnimation(.pet, nil)
                    onMoodChange(healthState == .dead ? 0 : 1)
                }
            } label: {
                VStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 28))
                    Text("PET")
                        .font(.system(size: 14, weight: .black))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 90)
                .background(RetroColors.pink)
                .foregroundColor(.black)
                .retroBorder(width: 4, cornerRadius: 12)
                .retroShadow(offset: 4)
            }
            .buttonStyle(.plain)
            
            // Nap button
            Button {
                if canNap {
                    onTriggerAnimation(.nap, nil)
                }
            } label: {
                VStack(spacing: 6) {
                    Image(systemName: "moon.fill")
                        .font(.system(size: 28))
                    Text("NAP")
                        .font(.system(size: 14, weight: .black))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 90)
                .background(canNap ? RetroColors.blue : Color.gray.opacity(0.5))
                .foregroundColor(.black)
                .retroBorder(width: 4, cornerRadius: 12)
                .retroShadow(offset: 4)
            }
            .disabled(!canNap)
            .buttonStyle(.plain)
        }
    }
}

enum PetAnimation {
    case idle
    case trick
    case pet
    case nap
}

#Preview {
    VStack(spacing: 20) {
        PetActions(
            healthState: .healthy,
            mood: 5,
            onMoodChange: { _ in },
            onTriggerAnimation: { _, _ in }
        )
        
        PetActions(
            healthState: .sick,
            mood: 3,
            onMoodChange: { _ in },
            onTriggerAnimation: { _, _ in }
        )
        
        PetActions(
            healthState: .dead,
            mood: 0,
            onMoodChange: { _ in },
            onTriggerAnimation: { _, _ in }
        )
    }
    .padding()
    .background(Color.white)
}

