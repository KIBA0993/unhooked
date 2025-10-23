//
//  ProgressBar.swift
//  Unhooked
//
//  Progress bar with retro styling
//

import SwiftUI

struct ProgressBar: View {
    let current: Int
    let max: Int
    let label: String
    let color: Color
    
    private var progress: Double {
        guard max > 0 else { return 0 }
        return min(Double(current) / Double(max), 1.0)
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            HStack {
                Text(label)
                    .font(.system(size: 14, weight: .black))
                    .textCase(.uppercase)
                    .foregroundColor(.black)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.black)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.black, lineWidth: 4)
                        )
                    
                    // Progress fill
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color)
                        .frame(width: Swift.max(0, geometry.size.width * progress - 8))
                        .padding(4)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: progress)
                }
            }
            .frame(height: 32)
            
            Text("\(Double(current) / 10, specifier: "%.1f") / \(max)")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundColor(.black.opacity(0.6))
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ProgressBar(current: 75, max: 200, label: "Growth Progress", color: .purple)
        ProgressBar(current: 150, max: 200, label: "Experience", color: .green)
        ProgressBar(current: 200, max: 200, label: "Complete", color: .orange)
    }
    .padding()
    .background(Color.white)
}

