//
//  PetBackground.swift
//  Unhooked
//
//  Animated background with time-of-day and stage decorations
//

import SwiftUI

enum TimeOfDay {
    case morning, afternoon, evening, night
    
    static var current: TimeOfDay {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12: return .morning
        case 12..<18: return .afternoon
        case 18..<21: return .evening
        default: return .night
        }
    }
}

struct BackgroundColors {
    let sky: [Color]
    let ground: [Color]
    let accent: Color
    
    static func colors(for timeOfDay: TimeOfDay) -> BackgroundColors {
        switch timeOfDay {
        case .morning:
            return BackgroundColors(
                sky: [
                    Color(red: 0.53, green: 0.81, blue: 0.98), // sky-300
                    Color(red: 0.56, green: 0.83, blue: 0.99), // sky-200
                    Color(red: 1.0, green: 0.82, blue: 0.63)   // orange-100
                ],
                ground: [
                    Color(red: 0.25, green: 0.88, blue: 0.33), // green-400
                    Color(red: 0.22, green: 0.8, blue: 0.29)   // green-500
                ],
                accent: Color(red: 1.0, green: 0.84, blue: 0.0) // Gold
            )
        case .afternoon:
            return BackgroundColors(
                sky: [
                    Color(red: 0.38, green: 0.65, blue: 0.91), // blue-400
                    Color(red: 0.53, green: 0.81, blue: 0.98), // sky-300
                    Color(red: 0.67, green: 0.92, blue: 0.99)  // cyan-200
                ],
                ground: [
                    Color(red: 0.22, green: 0.8, blue: 0.29),  // green-500
                    Color(red: 0.16, green: 0.71, blue: 0.23)  // green-600
                ],
                accent: Color(red: 1.0, green: 0.65, blue: 0.0) // Orange
            )
        case .evening:
            return BackgroundColors(
                sky: [
                    Color(red: 0.75, green: 0.53, blue: 0.95), // purple-400
                    Color(red: 0.98, green: 0.69, blue: 0.88), // pink-300
                    Color(red: 1.0, green: 0.82, blue: 0.63)   // orange-200
                ],
                ground: [
                    Color(red: 0.16, green: 0.71, blue: 0.23), // green-600
                    Color(red: 0.13, green: 0.59, blue: 0.2)   // green-700
                ],
                accent: Color(red: 1.0, green: 0.41, blue: 0.71) // Hot pink
            )
        case .night:
            return BackgroundColors(
                sky: [
                    Color(red: 0.18, green: 0.2, blue: 0.45),  // indigo-900
                    Color(red: 0.29, green: 0.18, blue: 0.51), // purple-900
                    Color(red: 0.2, green: 0.22, blue: 0.47)   // indigo-800
                ],
                ground: [
                    Color(red: 0.09, green: 0.47, blue: 0.15), // green-800
                    Color(red: 0.05, green: 0.37, blue: 0.11)  // green-900
                ],
                accent: Color(red: 0.9, green: 0.9, blue: 0.98) // Lavender
            )
        }
    }
}

struct PetBackground: View {
    let stage: Int
    let timeOfDay: TimeOfDay
    
    init(stage: Int, timeOfDay: TimeOfDay = .current) {
        self.stage = stage
        self.timeOfDay = timeOfDay
    }
    
    private var colors: BackgroundColors {
        BackgroundColors.colors(for: timeOfDay)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Sky gradient
                LinearGradient(
                    colors: colors.sky,
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Ground
                VStack {
                    Spacer()
                    
                    LinearGradient(
                        colors: colors.ground,
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: geometry.size.height * 0.25)
                }
                .ignoresSafeArea()
                
                // Decorations based on stage
                decorations(in: geometry)
            }
        }
    }
    
    @ViewBuilder
    private func decorations(in geometry: GeometryProxy) -> some View {
        let width = geometry.size.width
        let height = geometry.size.height
        let groundY = height * 0.75
        
        switch stage {
        case 0: // Egg stage - minimal
            Group {
                // Simple grass tufts
                grassTuft(x: width * 0.1, y: groundY, height: 12)
                grassTuft(x: width * 0.85, y: groundY, height: 12)
            }
            
        case 1: // Baby - small flowers
            Group {
                // Grass tufts
                grassTuft(x: width * 0.08, y: groundY, height: 16)
                grassTuft(x: width * 0.15, y: groundY, height: 12)
                grassTuft(x: width * 0.8, y: groundY, height: 16)
                grassTuft(x: width * 0.9, y: groundY, height: 12)
                
                // Small flowers
                flower(x: width * 0.25, y: groundY - 5, size: 12, color: .pink)
                flower(x: width * 0.72, y: groundY - 5, size: 12, color: .yellow)
            }
            
        case 2: // Teen - more flowers and small tree
            Group {
                // Small tree on left
                tree(x: width * 0.08, y: groundY - 20, treeSize: 32, trunkHeight: 24)
                
                // Multiple flowers
                flower(x: width * 0.2, y: groundY - 5, size: 16, color: .red)
                flower(x: width * 0.35, y: groundY - 8, size: 12, color: .blue)
                flower(x: width * 0.65, y: groundY - 5, size: 16, color: .purple)
                flower(x: width * 0.85, y: groundY - 6, size: 12, color: .pink)
                
                // Grass scattered
                ForEach(0..<6, id: \.self) { i in
                    grassTuft(
                        x: width * (0.15 + Double(i) * 0.12),
                        y: groundY,
                        height: 12
                    )
                }
            }
            
        case 3: // Adult - full garden
            Group {
                // Trees on both sides
                tree(x: width * 0.06, y: groundY - 25, treeSize: 40, trunkHeight: 32)
                tree(x: width * 0.92, y: groundY - 30, treeSize: 48, trunkHeight: 40)
                
                // Bush
                bush(x: width * 0.2, y: groundY - 10)
                
                // Many flowers
                flower(x: width * 0.3, y: groundY - 5, size: 14, color: .red)
                flower(x: width * 0.38, y: groundY - 8, size: 16, color: .yellow)
                flower(x: width * 0.48, y: groundY - 6, size: 12, color: .purple)
                flower(x: width * 0.58, y: groundY - 7, size: 14, color: .pink)
                flower(x: width * 0.68, y: groundY - 5, size: 16, color: .blue)
                flower(x: width * 0.78, y: groundY - 6, size: 12, color: .orange)
                
                // Dense grass
                ForEach(0..<10, id: \.self) { i in
                    grassTuft(
                        x: width * (0.1 + Double(i) * 0.08),
                        y: groundY,
                        height: CGFloat.random(in: 10...16)
                    )
                }
            }
            
        default: // Elder - lush environment
            Group {
                // Large trees
                tree(x: width * 0.05, y: groundY - 35, treeSize: 56, trunkHeight: 48)
                tree(x: width * 0.25, y: groundY - 30, treeSize: 48, trunkHeight: 40)
                tree(x: width * 0.75, y: groundY - 32, treeSize: 52, trunkHeight: 44)
                tree(x: width * 0.94, y: groundY - 38, treeSize: 60, trunkHeight: 52)
                
                // Multiple bushes
                bush(x: width * 0.15, y: groundY - 10)
                bush(x: width * 0.85, y: groundY - 10)
                
                // Flower garden
                ForEach(0..<12, id: \.self) { i in
                    let colors: [Color] = [.red, .yellow, .blue, .purple, .pink, .orange]
                    flower(
                        x: width * (0.35 + Double(i % 4) * 0.08),
                        y: groundY - CGFloat((i / 4) * 8) - 5,
                        size: CGFloat.random(in: 12...18),
                        color: colors[i % colors.count]
                    )
                }
                
                // Very dense grass
                ForEach(0..<15, id: \.self) { i in
                    grassTuft(
                        x: width * (0.05 + Double(i) * 0.06),
                        y: groundY,
                        height: CGFloat.random(in: 12...20)
                    )
                }
            }
        }
    }
    
    // MARK: - Decoration Components
    
    private func grassTuft(x: CGFloat, y: CGFloat, height: CGFloat) -> some View {
        Capsule()
            .fill(Color(red: 0.13, green: 0.59, blue: 0.2))
            .frame(width: 8, height: height)
            .position(x: x, y: y - height / 2)
    }
    
    private func flower(x: CGFloat, y: CGFloat, size: CGFloat, color: Color) -> some View {
        VStack(spacing: 0) {
            Circle()
                .fill(color)
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(color.opacity(0.7), lineWidth: 2)
                )
            
            Rectangle()
                .fill(Color(red: 0.16, green: 0.71, blue: 0.23))
                .frame(width: 2, height: size)
        }
        .position(x: x, y: y)
    }
    
    private func tree(x: CGFloat, y: CGFloat, treeSize: CGFloat, trunkHeight: CGFloat) -> some View {
        VStack(spacing: 0) {
            Circle()
                .fill(Color(red: 0.16, green: 0.71, blue: 0.23))
                .frame(width: treeSize, height: treeSize)
                .overlay(
                    Circle()
                        .stroke(Color(red: 0.09, green: 0.47, blue: 0.15), lineWidth: 2)
                )
            
            Rectangle()
                .fill(Color(red: 0.55, green: 0.35, blue: 0.2))
                .frame(width: treeSize * 0.3, height: trunkHeight)
                .overlay(
                    Rectangle()
                        .stroke(Color(red: 0.4, green: 0.25, blue: 0.1), lineWidth: 2)
                )
        }
        .position(x: x, y: y)
    }
    
    private func bush(x: CGFloat, y: CGFloat) -> some View {
        Capsule()
            .fill(Color(red: 0.22, green: 0.8, blue: 0.29))
            .frame(width: 32, height: 24)
            .overlay(
                Capsule()
                    .stroke(Color(red: 0.13, green: 0.59, blue: 0.2), lineWidth: 2)
            )
            .position(x: x, y: y)
    }
}

#Preview {
    ZStack {
        PetBackground(stage: 3, timeOfDay: .afternoon)
        
        VStack {
            Text("Adult Stage - Afternoon")
                .font(.headline)
                .padding()
                .background(.white.opacity(0.8))
                .cornerRadius(8)
        }
    }
}

