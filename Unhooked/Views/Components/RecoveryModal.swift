//
//  RecoveryModal.swift
//  Unhooked
//
//  Recovery action confirmation modal
//

import SwiftUI

struct RecoveryModal: View {
    @Environment(\.dismiss) private var dismiss
    
    let action: RecoveryActionType
    let gems: Int
    let onConfirm: () -> Void
    
    private var actionInfo: (title: String, description: String, cost: Int, icon: String, color: Color) {
        switch action {
        case .cure:
            return (
                "Visit the Vet",
                "Instantly cure your sick friend and restore them to full health. They'll be back to their happy self!",
                120,
                "cross.fill",
                .orange
            )
        case .revive:
            return (
                "Revive Your Friend",
                "Bring your friend back from the beyond. They'll return but will be fragile for a few days. Handle with extra care.",
                400,
                "heart.fill",
                .purple
            )
        case .restart:
            return (
                "Start Fresh",
                "Begin a new journey with a new friend. Your previous friend will be remembered in your Memorial. All cosmetics are kept.",
                200,
                "arrow.clockwise",
                .gray
            )
        }
    }
    
    private var canAfford: Bool {
        gems >= actionInfo.cost
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(actionInfo.color.opacity(0.2))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: actionInfo.icon)
                            .font(.system(size: 50))
                            .foregroundStyle(actionInfo.color)
                    }
                    .padding(.top, 20)
                    
                    // Title & Description
                    VStack(spacing: 12) {
                        Text(actionInfo.title)
                            .font(.system(size: 24, weight: .bold))
                        
                        Text(actionInfo.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Cost
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "diamond.fill")
                                .foregroundStyle(.cyan)
                            Text("\(actionInfo.cost) Gems")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .monospacedDigit()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(actionInfo.color.opacity(0.1))
                        .retroBorder(width: 2, cornerRadius: 16)
                        
                        HStack(spacing: 6) {
                            Text("Your Balance:")
                            Text("\(gems)")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .monospacedDigit()
                            Image(systemName: "diamond.fill")
                                .foregroundStyle(.cyan)
                                .font(.caption)
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                    
                    // Warning if can't afford
                    if !canAfford {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text("Not enough Gems")
                                .font(.subheadline)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.orange.opacity(0.1))
                        .retroBorder(width: 2, color: .orange, cornerRadius: 10)
                    }
                    
                    // Confirm button
                    Button {
                        onConfirm()
                        dismiss()
                    } label: {
                        Text("Confirm")
                            .font(.system(size: 18, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(canAfford ? actionInfo.color : Color.gray)
                            .foregroundColor(.white)
                            .retroBorder(width: 3, cornerRadius: 12)
                            .retroShadow(offset: 3)
                    }
                    .buttonStyle(.plain)
                    .disabled(!canAfford)
                    .padding(.horizontal)
                }
                .padding()
            }
            .background(RetroGradients.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    RecoveryModal(
        action: .revive,
        gems: 450,
        onConfirm: {}
    )
}

