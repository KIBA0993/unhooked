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
    
    var body: some View {
        HStack(spacing: 12) {
            // Energy
            HStack(spacing: 8) {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(RetroColors.yellow)
                    .font(.system(size: 20, weight: .bold))
                
                Text("\(energy)/150")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(RetroColors.yellow)
            .retroBorder(width: 4, cornerRadius: 16)
            .retroShadow(offset: 4)
            
            // Gems
            HStack(spacing: 8) {
                Image(systemName: "diamond.fill")
                    .foregroundStyle(.black)
                    .font(.system(size: 18, weight: .bold))
                
                Text("Gems")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.black.opacity(0.6))
                
                Text("\(gems)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(RetroColors.pink)
            .retroBorder(width: 4, cornerRadius: 16)
            .retroShadow(offset: 4)
            
            Spacer()
        }
    }
}

#Preview {
    CurrencyDisplay(energy: 150, gems: 50)
        .padding()
        .background(RetroGradients.background)
}

