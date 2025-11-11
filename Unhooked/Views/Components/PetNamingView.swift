//
//  PetNamingView.swift
//  Unhooked
//
//  Pet naming screen after species selection
//

import SwiftUI

struct PetNamingView: View {
    let species: Species
    let onComplete: (String) -> Void
    
    @State private var petName: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    private let defaultNames = [
        Species.cat: ["Whiskers", "Luna", "Shadow", "Milo", "Oliver"],
        Species.dog: ["Buddy", "Max", "Cooper", "Bailey", "Charlie"]
    ]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.4, green: 0.7, blue: 1.0),
                    Color(red: 0.73, green: 0.33, blue: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Pet preview with pixel art
                VStack(spacing: 16) {
                    PixelPet(
                        stage: 0,
                        mood: .happy,
                        isActive: true,
                        petType: species,
                        healthState: .healthy,
                        currentAnimation: .idle,
                        trickVariant: 0
                    )
                    .scaleEffect(3.0)
                    .frame(height: 180)
                    
                    Text(species == .cat ? "🐱" : "🐶")
                        .font(.system(size: 48))
                }
                
                // Title
                Text("Name Your \(species == .cat ? "Cat" : "Dog")!")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)
                
                // Name input
                VStack(spacing: 16) {
                    TextField("Enter name", text: $petName)
                        .font(.system(size: 20, weight: .semibold))
                        .padding(16)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.black, lineWidth: 3)
                        )
                        .focused($isTextFieldFocused)
                        .multilineTextAlignment(.center)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)
                    
                    // Quick name suggestions
                    Text("Quick picks:")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.8))
                    
                    HStack(spacing: 8) {
                        ForEach(defaultNames[species] ?? [], id: \.self) { name in
                            Button {
                                petName = name
                            } label: {
                                Text(name)
                                    .font(.system(size: 14, weight: .semibold))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.2))
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.white.opacity(0.5), lineWidth: 2)
                                    )
                            }
                        }
                    }
                }
                .padding(.horizontal, 32)
                
                // Continue button
                Button {
                    let finalName = petName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? (species == .cat ? "Cat" : "Dog")
                        : petName.trimmingCharacters(in: .whitespacesAndNewlines)
                    onComplete(finalName)
                } label: {
                    HStack(spacing: 8) {
                        Text("Continue")
                            .font(.system(size: 20, weight: .bold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.63, green: 0.33, blue: 1.0), Color(red: 1.0, green: 0.4, blue: 0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black, lineWidth: 3)
                    )
                    .shadow(color: .black, radius: 0, x: 3, y: 3)
                }
                .padding(.horizontal, 32)
                
                Text(petName.isEmpty ? "Leave blank for default name" : "")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(height: 16)
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            // Auto-focus text field after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
    }
}

#Preview {
    PetNamingView(species: .cat, onComplete: { _ in })
}

