//
//  CurrencyDisplay.swift
//  Unhooked
//
//  Currency display component
//

import SwiftUI

struct CurrencyDisplay: View {
    let energy: Int
    let gems: Int
    let maxEnergy: Int = 150
    
    private var energyPercent: Double {
        Double(energy) / Double(maxEnergy)
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // Energy - with progress bar
            HStack(spacing: 6) {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(Color(red: 0.92, green: 0.7, blue: 0.0))
                    .font(.system(size: 14, weight: .bold))
                
                VStack(alignment: .leading, spacing: 2) {
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(red: 0.95, green: 0.85, blue: 0.6))
                                .frame(height: 4)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 2)
                                        .stroke(.black, lineWidth: 1)
                                )
                            
                            // Fill
                            RoundedRectangle(cornerRadius: 1)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(red: 0.92, green: 0.6, blue: 0.0), Color(red: 1.0, green: 0.7, blue: 0.0)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(2, geometry.size.width * energyPercent - 2))
                                .padding(1)
                                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: energyPercent)
                        }
                    }
                    .frame(height: 4)
                    
                    // Text
                    Text("\(energy)/\(maxEnergy)")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.black.opacity(0.7))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.96, green: 0.8, blue: 0.2), Color(red: 1.0, green: 0.9, blue: 0.25)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .retroBorder(width: 2, cornerRadius: 10)
            .retroShadow(offset: 2)
            
            // Gems
            HStack(spacing: 6) {
                Image(systemName: "diamond.fill")
                    .foregroundStyle(.white)
                    .font(.system(size: 14, weight: .bold))
                
                VStack(alignment: .leading, spacing: 0) {
                    Text("Gems")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer().frame(height: 2)
                }
                
                Text("\(gems)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.63, green: 0.4, blue: 1.0), Color(red: 1.0, green: 0.4, blue: 0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .retroBorder(width: 2, cornerRadius: 10)
            .retroShadow(offset: 2)
            
            Spacer()
        }
    }
}

#Preview {
    CurrencyDisplay(energy: 150, gems: 50)
        .padding()
        .background(RetroGradients.background)
}

