//
//  DebugPanel.swift
//  Unhooked
//
//  Debug panel for testing (only in DEBUG builds)
//

import SwiftUI

#if DEBUG
struct DebugPanel: View {
    @State private var isExpanded = false
    
    let currentGems: Int
    let currentUnfedDays: Int
    let currentGrowthProgress: Int
    let onAddGems: (Int) -> Void
    let onSetUnfedDays: (Int) -> Void
    let onSetGrowthProgress: (Int) -> Void
    let onResetGame: () -> Void
    let onSetTestState: (TestState) -> Void
    
    enum TestState: String, CaseIterable {
        case healthy = "Healthy"
        case sick = "Sick"
        case dead = "Dead"
        case advanced = "Advanced"
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                if isExpanded {
                    expandedPanel
                        .transition(.move(edge: .leading).combined(with: .opacity))
                }
                
                Spacer()
            }
            
            HStack {
                toggleButton
                Spacer()
            }
        }
        .padding()
    }
    
    private var toggleButton: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isExpanded.toggle()
            }
        } label: {
            Image(systemName: isExpanded ? "xmark.circle.fill" : "wrench.and.screwdriver.fill")
                .font(.system(size: 24))
                .foregroundStyle(.white)
                .padding(12)
                .background(.black)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(.white, lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
    
    private var expandedPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: "hammer.fill")
                        .foregroundStyle(.yellow)
                    Text("Debug Panel")
                        .font(.system(size: 14, weight: .bold))
                    Spacer()
                }
                
                Divider()
                
                // Current stats
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Stats")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Gems: \(currentGems)")
                        .font(.caption2)
                        .monospacedDigit()
                    
                    Text("Unfed Days: \(currentUnfedDays)")
                        .font(.caption2)
                        .monospacedDigit()
                    
                    Text("Growth: \(currentGrowthProgress)")
                        .font(.caption2)
                        .monospacedDigit()
                }
                
                Divider()
                
                // Add Gems
                VStack(alignment: .leading, spacing: 6) {
                    Text("Add Gems")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 6) {
                        ForEach([50, 100, 500], id: \.self) { amount in
                            Button {
                                onAddGems(amount)
                            } label: {
                                Text("+\(amount)")
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.cyan.opacity(0.3))
                                    .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                Divider()
                
                // Set Unfed Days
                VStack(alignment: .leading, spacing: 6) {
                    Text("Set Unfed Days")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 6) {
                        ForEach([0, 2, 4], id: \.self) { days in
                            Button {
                                onSetUnfedDays(days)
                            } label: {
                                Text("\(days)")
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.orange.opacity(0.3))
                                    .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                Divider()
                
                // Set Growth Progress
                VStack(alignment: .leading, spacing: 6) {
                    Text("Set Growth")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 6) {
                        ForEach([0, 100, 350], id: \.self) { progress in
                            Button {
                                onSetGrowthProgress(progress)
                            } label: {
                                Text("\(progress)")
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.purple.opacity(0.3))
                                    .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                Divider()
                
                // Test States
                VStack(alignment: .leading, spacing: 6) {
                    Text("Test States")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(TestState.allCases, id: \.self) { state in
                        Button {
                            onSetTestState(state)
                        } label: {
                            Text(state.rawValue)
                                .font(.caption2.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(.green.opacity(0.3))
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Divider()
                
                // Reset
                Button {
                    onResetGame()
                } label: {
                    HStack {
                        Image(systemName: "trash.fill")
                        Text("Reset Game")
                    }
                    .font(.caption.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(.red.opacity(0.3))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
            .padding(12)
        }
        .frame(width: 180, height: 460)
        .background(.black.opacity(0.9))
        .foregroundColor(.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.white.opacity(0.3), lineWidth: 2)
        )
    }
}
#endif

#if DEBUG
#Preview {
    ZStack {
        Color.gray.ignoresSafeArea()
        
        DebugPanel(
            currentGems: 50,
            currentUnfedDays: 1,
            currentGrowthProgress: 75,
            onAddGems: { _ in },
            onSetUnfedDays: { _ in },
            onSetGrowthProgress: { _ in },
            onResetGame: {},
            onSetTestState: { _ in }
        )
    }
}
#endif

