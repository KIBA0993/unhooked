//
//  PetBackground.swift
//  Unhooked
//
//  Pixel art background matching Figma design exactly
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
    let skyGradient: [Color]
    let groundGradient: [Color]
    let accent: Color
    
    static func colors(for timeOfDay: TimeOfDay) -> BackgroundColors {
        switch timeOfDay {
        case .morning:
            return BackgroundColors(
                skyGradient: [
                    Color(red: 0.53, green: 0.81, blue: 0.98),
                    Color(red: 0.56, green: 0.83, blue: 0.99),
                    Color(red: 1.0, green: 0.82, blue: 0.63)
                ],
                groundGradient: [
                    Color(red: 0.25, green: 0.88, blue: 0.33),
                    Color(red: 0.22, green: 0.8, blue: 0.29)
                ],
                accent: Color(red: 1.0, green: 0.84, blue: 0.0)
            )
        case .afternoon:
            return BackgroundColors(
                skyGradient: [
                    Color(red: 0.38, green: 0.65, blue: 0.91),
                    Color(red: 0.53, green: 0.81, blue: 0.98),
                    Color(red: 0.67, green: 0.92, blue: 0.99)
                ],
                groundGradient: [
                    Color(red: 0.22, green: 0.8, blue: 0.29),
                    Color(red: 0.16, green: 0.71, blue: 0.23)
                ],
                accent: Color(red: 1.0, green: 0.65, blue: 0.0)
            )
        case .evening:
            return BackgroundColors(
                skyGradient: [
                    Color(red: 0.75, green: 0.53, blue: 0.95),
                    Color(red: 0.98, green: 0.69, blue: 0.88),
                    Color(red: 1.0, green: 0.82, blue: 0.63)
                ],
                groundGradient: [
                    Color(red: 0.16, green: 0.71, blue: 0.23),
                    Color(red: 0.13, green: 0.59, blue: 0.2)
                ],
                accent: Color(red: 1.0, green: 0.41, blue: 0.71)
            )
        case .night:
            return BackgroundColors(
                skyGradient: [
                    Color(red: 0.18, green: 0.2, blue: 0.45),
                    Color(red: 0.29, green: 0.18, blue: 0.51),
                    Color(red: 0.2, green: 0.22, blue: 0.47)
                ],
                groundGradient: [
                    Color(red: 0.09, green: 0.47, blue: 0.15),
                    Color(red: 0.05, green: 0.37, blue: 0.11)
                ],
                accent: Color(red: 0.9, green: 0.9, blue: 0.98)
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
                    colors: colors.skyGradient,
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Time-specific elements (sun, moon, stars)
                timeElements(in: geometry)
                
                // Pixel clouds (not at night)
                if timeOfDay != .night {
                    pixelClouds(in: geometry)
                }
                
                // Ground
                VStack {
                    Spacer()
                    LinearGradient(
                        colors: colors.groundGradient,
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 128)
                    .overlay(
                        Rectangle()
                            .fill(Color(red: 0.09, green: 0.47, blue: 0.15))
                            .frame(height: 3),
                        alignment: .top
                    )
                }
                .ignoresSafeArea()
                
                // Stage decorations
                stageDecorations(in: geometry)
            }
        }
    }
    
    // MARK: - Time Elements
    
    @ViewBuilder
    private func timeElements(in geometry: GeometryProxy) -> some View {
        if timeOfDay == .night {
            nightElements(in: geometry)
        } else if timeOfDay == .morning || timeOfDay == .afternoon {
            pixelSun(in: geometry)
        } else if timeOfDay == .evening {
            eveningSun(in: geometry)
            earlyStars(in: geometry)
        }
    }
    
    // MARK: - Night Elements
    
    private func nightElements(in geometry: GeometryProxy) -> some View {
        ZStack {
            // Stars
            ForEach(0..<15, id: \.self) { index in
                PixelStar(index: index, geometry: geometry)
            }
            
            // Pixel moon
            PixelMoon()
                .position(
                    x: geometry.size.width * 0.75,
                    y: geometry.size.height * 0.15
                )
        }
    }
    
    // MARK: - Pixel Sun
    
    private func pixelSun(in geometry: GeometryProxy) -> some View {
        PixelSun(colors: colors)
            .position(
                x: geometry.size.width * 0.75,
                y: geometry.size.height * 0.15
            )
    }
    
    // MARK: - Evening Sun
    
    private func eveningSun(in geometry: GeometryProxy) -> some View {
        EveningSun()
            .position(
                x: geometry.size.width * 0.75,
                y: geometry.size.height * 0.15
            )
    }
    
    // MARK: - Early Stars
    
    private func earlyStars(in geometry: GeometryProxy) -> some View {
        ForEach(0..<6, id: \.self) { index in
            FadingPixelStar(index: index, geometry: geometry)
        }
    }
    
    // MARK: - Pixel Clouds
    
    private func pixelClouds(in geometry: GeometryProxy) -> some View {
        Group {
            // Left cloud
            FloatingPixelCloud(geometry: geometry, position: .left)
                .position(x: geometry.size.width * 0.15, y: geometry.size.height * 0.2)
            
            // Right cloud
            FloatingPixelCloud(geometry: geometry, position: .right)
                .position(x: geometry.size.width * 0.85, y: geometry.size.height * 0.1)
            
            // Center cloud
            FloatingPixelCloud(geometry: geometry, position: .center)
                .position(x: geometry.size.width * 0.5, y: geometry.size.height * 0.35)
        }
    }
    
    // MARK: - Stage Decorations
    
    @ViewBuilder
    private func stageDecorations(in geometry: GeometryProxy) -> some View {
        let groundY = geometry.size.height * 0.75
        
        switch stage {
        case 0:
            stage0Decorations(groundY: groundY, width: geometry.size.width)
        case 1:
            stage1Decorations(groundY: groundY, width: geometry.size.width)
        case 2:
            stage2Decorations(groundY: groundY, width: geometry.size.width)
        case 3:
            stage3Decorations(groundY: groundY, width: geometry.size.width)
        default:
            stage4Decorations(groundY: groundY, width: geometry.size.width)
        }
    }
    
    // MARK: - Stage 0: Egg - Minimal
    
    private func stage0Decorations(groundY: CGFloat, width: CGFloat) -> some View {
        Group {
            GrassTuft(height: 12)
                .position(x: width * 0.1, y: groundY)
            GrassTuft(height: 12)
                .position(x: width * 0.85, y: groundY)
        }
    }
    
    // MARK: - Stage 1: Baby - Small Flowers
    
    private func stage1Decorations(groundY: CGFloat, width: CGFloat) -> some View {
        Group {
            // Grass
            GrassTuft(height: 16).position(x: width * 0.08, y: groundY)
            GrassTuft(height: 12).position(x: width * 0.15, y: groundY)
            GrassTuft(height: 16).position(x: width * 0.8, y: groundY)
            GrassTuft(height: 12).position(x: width * 0.9, y: groundY)
            
            // Flowers
            PixelFlower(size: 12, color: .pink)
                .position(x: width * 0.25, y: groundY - 5)
            PixelFlower(size: 12, color: .yellow)
                .position(x: width * 0.72, y: groundY - 5)
        }
    }
    
    // MARK: - Stage 2: Teen - More Flowers and Small Tree
    
    private func stage2Decorations(groundY: CGFloat, width: CGFloat) -> some View {
        Group {
            // Small tree
            PixelTree(treeSize: 32, trunkHeight: 24)
                .position(x: width * 0.08, y: groundY - 20)
            
            // Flowers
            PixelFlower(size: 16, color: .red).position(x: width * 0.2, y: groundY - 5)
            PixelFlower(size: 12, color: .blue).position(x: width * 0.35, y: groundY - 8)
            PixelFlower(size: 16, color: .purple).position(x: width * 0.65, y: groundY - 5)
            PixelFlower(size: 12, color: .pink).position(x: width * 0.85, y: groundY - 6)
            
            // Grass
            ForEach(0..<6, id: \.self) { i in
                GrassTuft(height: 12)
                    .position(x: width * (0.15 + Double(i) * 0.12), y: groundY)
            }
        }
    }
    
    // MARK: - Stage 3: Adult - Full Garden
    
    private func stage3Decorations(groundY: CGFloat, width: CGFloat) -> some View {
        Group {
            // Trees
            PixelTree(treeSize: 40, trunkHeight: 32).position(x: width * 0.06, y: groundY - 25)
            PixelTree(treeSize: 48, trunkHeight: 40).position(x: width * 0.92, y: groundY - 30)
            
            // Bush
            PixelBush().position(x: width * 0.2, y: groundY - 10)
            
            // Many flowers
            PixelFlower(size: 14, color: .red).position(x: width * 0.3, y: groundY - 5)
            PixelFlower(size: 16, color: .yellow).position(x: width * 0.38, y: groundY - 8)
            PixelFlower(size: 12, color: .purple).position(x: width * 0.48, y: groundY - 6)
            PixelFlower(size: 14, color: .pink).position(x: width * 0.58, y: groundY - 7)
            PixelFlower(size: 16, color: .blue).position(x: width * 0.68, y: groundY - 5)
            PixelFlower(size: 12, color: .orange).position(x: width * 0.78, y: groundY - 6)
            
            // Dense grass
            ForEach(0..<10, id: \.self) { i in
                GrassTuft(height: CGFloat.random(in: 10...16))
                    .position(x: width * (0.1 + Double(i) * 0.08), y: groundY)
            }
        }
    }
    
    // MARK: - Stage 4: Master - Magical Garden
    
    private func stage4Decorations(groundY: CGFloat, width: CGFloat) -> some View {
        Group {
            // Magical glowing trees
            MagicalTree(treeSize: 48, trunkHeight: 40, glowColor: .purple)
                .position(x: width * 0.05, y: groundY - 35)
            MagicalTree(treeSize: 56, trunkHeight: 48, glowColor: .pink)
                .position(x: width * 0.94, y: groundY - 38)
            
            // Golden bushes
            GoldenBush(size: 40).position(x: width * 0.2, y: groundY - 10)
            GoldenBush(size: 32).position(x: width * 0.85, y: groundY - 10)
            
            // Magical flowers
            MagicalFlower(size: 20, color: .red, delay: 0).position(x: width * 0.28, y: groundY - 5)
            MagicalFlower(size: 20, color: .yellow, delay: 0.3).position(x: width * 0.38, y: groundY - 8)
            MagicalFlower(size: 20, color: .purple, delay: 0.6).position(x: width * 0.48, y: groundY - 6)
            MagicalFlower(size: 20, color: .cyan, delay: 0.9).position(x: width * 0.58, y: groundY - 7)
            MagicalFlower(size: 20, color: .pink, delay: 1.2).position(x: width * 0.72, y: groundY - 5)
            
            // Floating sparkles
            ForEach(0..<6, id: \.self) { i in
                FloatingSparkle(index: i, width: width)
            }
            
            // Magical grass with gradient
            ForEach(0..<10, id: \.self) { i in
                MagicalGrass(height: CGFloat.random(in: 12...16))
                    .position(x: width * (0.08 + Double(i) * 0.08), y: groundY)
            }
        }
    }
}

// MARK: - Component Views

struct GrassTuft: View {
    let height: CGFloat
    
    var body: some View {
        Capsule()
            .fill(Color(red: 0.13, green: 0.59, blue: 0.2))
            .frame(width: 8, height: height)
    }
}

struct PixelFlower: View {
    let size: CGFloat
    let color: Color
    
    var body: some View {
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
    }
}

struct PixelTree: View {
    let treeSize: CGFloat
    let trunkHeight: CGFloat
    
    var body: some View {
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
    }
}

struct PixelBush: View {
    var body: some View {
        Capsule()
            .fill(Color(red: 0.22, green: 0.8, blue: 0.29))
            .frame(width: 32, height: 24)
            .overlay(
                Capsule()
                    .stroke(Color(red: 0.13, green: 0.59, blue: 0.2), lineWidth: 2)
            )
    }
}

struct MagicalTree: View {
    let treeSize: CGFloat
    let trunkHeight: CGFloat
    let glowColor: Color
    @State private var glowIntensity: Double = 0.5
    
    var body: some View {
        VStack(spacing: 0) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: glowColor == .purple ?
                            [Color(red: 0.58, green: 0.2, blue: 0.92), Color(red: 0.46, green: 0.16, blue: 0.74)] :
                            [Color(red: 0.93, green: 0.28, blue: 0.6), Color(red: 0.93, green: 0.28, blue: 0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: treeSize, height: treeSize)
                .overlay(
                    Circle()
                        .stroke(glowColor == .purple ? Color(red: 0.3, green: 0.1, blue: 0.58) : Color(red: 0.64, green: 0.16, blue: 0.38), lineWidth: 2)
                )
                .shadow(color: (glowColor == .purple ? Color.purple : Color.pink).opacity(glowIntensity), radius: glowIntensity * 12)
            
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.55, green: 0.35, blue: 0.2), Color(red: 0.4, green: 0.25, blue: 0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: treeSize * 0.25, height: trunkHeight)
                .overlay(
                    Rectangle()
                        .stroke(Color.black, lineWidth: 2)
                )
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                glowIntensity = 0.8
            }
        }
    }
}

struct GoldenBush: View {
    let size: CGFloat
    
    var body: some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [Color(red: 1.0, green: 0.84, blue: 0.0), Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size * 0.6)
            .overlay(
                Capsule()
                    .stroke(Color(red: 0.8, green: 0.6, blue: 0), lineWidth: 2)
            )
    }
}

struct MagicalFlower: View {
    let size: CGFloat
    let color: Color
    let delay: Double
    @State private var scale: CGFloat = 1.0
    
    var gradientColors: [Color] {
        switch color {
        case .red: return [Color(red: 0.96, green: 0.4, blue: 0.4), Color(red: 0.75, green: 0.24, blue: 0.24)]
        case .yellow: return [Color(red: 1.0, green: 0.84, blue: 0.0), Color(red: 0.96, green: 0.64, blue: 0)]
        case .purple: return [Color(red: 0.75, green: 0.53, blue: 0.95), Color(red: 0.58, green: 0.4, blue: 0.76)]
        case .cyan: return [Color(red: 0.13, green: 0.86, blue: 0.86), Color(red: 0.05, green: 0.73, blue: 0.83)]
        case .pink: return [Color(red: 0.96, green: 0.4, blue: 0.78), Color(red: 0.92, green: 0.28, blue: 0.6)]
        default: return [color, color]
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(Color(red: 1.0, green: 0.84, blue: 0.0), lineWidth: 2)
                )
                .shadow(color: color.opacity(0.5), radius: 4)
                .scaleEffect(scale)
            
            Rectangle()
                .fill(Color(red: 0.16, green: 0.71, blue: 0.23))
                .frame(width: 4, height: size)
                .overlay(
                    Rectangle()
                        .stroke(Color(red: 0.09, green: 0.47, blue: 0.15), lineWidth: 1)
                )
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true).delay(delay)) {
                scale = 1.1
            }
        }
    }
}

struct FloatingSparkle: View {
    let index: Int
    let width: CGFloat
    @State private var offset: CGFloat = -5
    @State private var opacity: Double = 0.4
    @State private var scale: CGFloat = 0.8
    
    var body: some View {
        Text("✨")
            .font(.system(size: 20))
            .foregroundColor(Color.yellow)
            .offset(y: offset)
            .opacity(opacity)
            .scaleEffect(scale)
            .position(
                x: width * (0.2 + CGFloat(index) * 0.12),
                y: CGFloat(60 + (index % 3) * 60)
            )
            .onAppear {
                let duration = 2.0 + Double(index) * 0.3
                let delay = Double(index) * 0.4
                
                withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true).delay(delay)) {
                    offset = 5
                    opacity = 1.0
                    scale = 1.2
                }
            }
    }
}

struct MagicalGrass: View {
    let height: CGFloat
    
    var body: some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [Color(red: 0.13, green: 0.59, blue: 0.2), Color(red: 0.16, green: 0.8, blue: 0.31)],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .frame(width: 8, height: height)
            .overlay(
                Capsule()
                    .stroke(Color(red: 0.09, green: 0.47, blue: 0.15), lineWidth: 1)
            )
    }
}

// MARK: - Pixel Sun

struct PixelSun: View {
    let colors: BackgroundColors
    @State private var yOffset: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var shimmerOpacity: [Double] = [0, 0, 0, 0]
    
    var body: some View {
        ZStack {
            // Glow
            Circle()
                .fill(Color.yellow.opacity(0.3))
                .frame(width: 120, height: 120)
                .blur(radius: 40)
            
            // Sun body
            ZStack {
                // Outer
                Rectangle()
                    .fill(Color(red: 1.0, green: 0.84, blue: 0.0))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Rectangle()
                            .stroke(Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.8), lineWidth: 3)
                    )
                
                // Inner core
                Rectangle()
                    .fill(Color(red: 1.0, green: 0.93, blue: 0.51))
                    .frame(width: 40, height: 40)
                
                // Rays - 8 directions
                sunRays
                
                // Shimmer
                ForEach(0..<4, id: \.self) { i in
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 4, height: 4)
                        .offset(x: CGFloat(12 + i * 4), y: CGFloat(12 + i * 4))
                        .opacity(shimmerOpacity[i])
                }
            }
            .offset(y: yOffset)
            .rotationEffect(.degrees(rotation))
        }
        .frame(width: 80, height: 80)
        .onAppear {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                yOffset = -6
            }
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: true)) {
                rotation = 5
            }
            for i in 0..<4 {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(Double(i) * 0.3)) {
                    shimmerOpacity[i] = 1.0
                }
            }
        }
    }
    
    private var sunRays: some View {
        Group {
            // North
            Rectangle().fill(Color(red: 1.0, green: 0.84, blue: 0.0)).frame(width: 8, height: 12)
                .overlay(Rectangle().stroke(Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.8), lineWidth: 1))
                .offset(y: -38)
            // South
            Rectangle().fill(Color(red: 1.0, green: 0.84, blue: 0.0)).frame(width: 8, height: 12)
                .overlay(Rectangle().stroke(Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.8), lineWidth: 1))
                .offset(y: 38)
            // East
            Rectangle().fill(Color(red: 1.0, green: 0.84, blue: 0.0)).frame(width: 12, height: 8)
                .overlay(Rectangle().stroke(Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.8), lineWidth: 1))
                .offset(x: 38)
            // West
            Rectangle().fill(Color(red: 1.0, green: 0.84, blue: 0.0)).frame(width: 12, height: 8)
                .overlay(Rectangle().stroke(Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.8), lineWidth: 1))
                .offset(x: -38)
            // NE
            Rectangle().fill(Color(red: 1.0, green: 0.84, blue: 0.0)).frame(width: 8, height: 8)
                .overlay(Rectangle().stroke(Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.8), lineWidth: 1))
                .offset(x: 28, y: -28)
            // NW
            Rectangle().fill(Color(red: 1.0, green: 0.84, blue: 0.0)).frame(width: 8, height: 8)
                .overlay(Rectangle().stroke(Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.8), lineWidth: 1))
                .offset(x: -28, y: -28)
            // SE
            Rectangle().fill(Color(red: 1.0, green: 0.84, blue: 0.0)).frame(width: 8, height: 8)
                .overlay(Rectangle().stroke(Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.8), lineWidth: 1))
                .offset(x: 28, y: 28)
            // SW
            Rectangle().fill(Color(red: 1.0, green: 0.84, blue: 0.0)).frame(width: 8, height: 8)
                .overlay(Rectangle().stroke(Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.8), lineWidth: 1))
                .offset(x: -28, y: 28)
        }
    }
}

// MARK: - Evening Sun

struct EveningSun: View {
    @State private var yOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.orange.opacity(0.3))
                .frame(width: 100, height: 100)
                .blur(radius: 40)
            
            ZStack {
                Rectangle()
                    .fill(Color(red: 1.0, green: 0.49, blue: 0.0))
                    .frame(width: 52, height: 52)
                    .overlay(
                        Rectangle()
                            .stroke(Color(red: 0.8, green: 0.13, blue: 0.13), lineWidth: 3)
                    )
                
                Rectangle()
                    .fill(Color(red: 1.0, green: 0.65, blue: 0.0))
                    .frame(width: 40, height: 40)
                
                // Short rays
                Rectangle().fill(Color(red: 1.0, green: 0.65, blue: 0.0)).frame(width: 8, height: 8)
                    .overlay(Rectangle().stroke(Color(red: 1.0, green: 0.49, blue: 0.0), lineWidth: 1))
                    .offset(y: -34)
                Rectangle().fill(Color(red: 1.0, green: 0.65, blue: 0.0)).frame(width: 8, height: 8)
                    .overlay(Rectangle().stroke(Color(red: 1.0, green: 0.49, blue: 0.0), lineWidth: 1))
                    .offset(x: 28, y: -24)
                Rectangle().fill(Color(red: 1.0, green: 0.65, blue: 0.0)).frame(width: 8, height: 8)
                    .overlay(Rectangle().stroke(Color(red: 1.0, green: 0.49, blue: 0.0), lineWidth: 1))
                    .offset(x: -28, y: -24)
            }
            .offset(y: yOffset)
        }
        .frame(width: 80, height: 80)
        .opacity(0.9)
        .onAppear {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                yOffset = -6
            }
        }
    }
}

// MARK: - Pixel Moon

struct PixelMoon: View {
    @State private var yOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(red: 1.0, green: 1.0, blue: 0.88).opacity(0.2))
                .frame(width: 100, height: 100)
                .blur(radius: 40)
            
            ZStack {
                Rectangle()
                    .fill(Color(red: 1.0, green: 1.0, blue: 0.88))
                    .frame(width: 64, height: 64)
                    .overlay(
                        Rectangle()
                            .stroke(Color(red: 1.0, green: 1.0, blue: 0.93), lineWidth: 3)
                    )
                
                // Crescent shadow
                Circle()
                    .fill(Color(red: 1.0, green: 1.0, blue: 0.93).opacity(0.6))
                    .frame(width: 40, height: 64)
                    .offset(x: 16)
                
                // Craters
                Rectangle().fill(Color.gray.opacity(0.4)).frame(width: 12, height: 12)
                    .overlay(Rectangle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
                    .offset(x: -8, y: -12)
                Rectangle().fill(Color.gray.opacity(0.4)).frame(width: 16, height: 16)
                    .overlay(Rectangle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
                    .offset(x: -4, y: 4)
                Rectangle().fill(Color.gray.opacity(0.4)).frame(width: 8, height: 8)
                    .overlay(Rectangle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
                    .offset(x: -12, y: 16)
                Rectangle().fill(Color(red: 1.0, green: 1.0, blue: 0.98)).frame(width: 8, height: 8)
                    .offset(x: 8, y: -4)
            }
            .offset(y: yOffset)
        }
        .frame(width: 80, height: 80)
        .onAppear {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                yOffset = -6
            }
        }
    }
}

// MARK: - Pixel Star

struct PixelStar: View {
    let index: Int
    let geometry: GeometryProxy
    @State private var opacity: Double = 0.3
    
    var body: some View {
        ZStack {
            Rectangle().fill(Color.white).frame(width: 4, height: 4)
                .offset(y: -4)
            Rectangle().fill(Color.white).frame(width: 12, height: 4)
            Rectangle().fill(Color.white).frame(width: 4, height: 4)
                .offset(y: 4)
        }
        .opacity(opacity)
        .position(
            x: geometry.size.width * (0.15 + CGFloat((index * 6) % 70) / 100),
            y: geometry.size.height * (0.08 + CGFloat((index * 4) % 40) / 100)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 2 + Double(index) * 0.2).repeatForever(autoreverses: true).delay(Double(index) * 0.3)) {
                opacity = 1.0
            }
        }
    }
}

struct FadingPixelStar: View {
    let index: Int
    let geometry: GeometryProxy
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            Rectangle().fill(Color.white).frame(width: 4, height: 4).offset(y: -4)
            Rectangle().fill(Color.white).frame(width: 12, height: 4)
            Rectangle().fill(Color.white).frame(width: 4, height: 4).offset(y: 4)
        }
        .opacity(opacity)
        .position(
            x: geometry.size.width * (0.2 + CGFloat(index) * 0.12),
            y: geometry.size.height * (0.1 + CGFloat(index % 3) * 0.08)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true).delay(Double(index) * 0.4)) {
                opacity = 0.6
            }
        }
    }
}

// MARK: - Floating Pixel Cloud

enum CloudPosition {
    case left, right, center
}

struct FloatingPixelCloud: View {
    let geometry: GeometryProxy
    let position: CloudPosition
    @State private var xOffset: CGFloat = 0
    
    var body: some View {
        pixelCloud
            .offset(x: xOffset)
            .onAppear {
                let duration: Double
                let distance: CGFloat
                let delay: Double
                
                switch position {
                case .left:
                    duration = 10
                    distance = -8
                    delay = 0
                case .right:
                    duration = 8
                    distance = 10
                    delay = 2
                case .center:
                    duration = 12
                    distance = 6
                    delay = 4
                }
                
                withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true).delay(delay)) {
                    xOffset = distance
                }
            }
    }
    
    private var pixelCloud: some View {
        ZStack {
            // Cloud size varies by position
            Rectangle().fill(Color.white.opacity(0.9)).frame(width: 12, height: 12)
                .overlay(Rectangle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
                .offset(x: 8, y: 8)
            Rectangle().fill(Color.white.opacity(0.9)).frame(width: 16, height: 16)
                .overlay(Rectangle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
                .offset(x: 16, y: 4)
            Rectangle().fill(Color.white.opacity(0.9)).frame(width: 12, height: 20)
                .overlay(Rectangle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
                .offset(x: 28, y: 0)
            Rectangle().fill(Color.white.opacity(0.9)).frame(width: 12, height: 12)
                .overlay(Rectangle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
                .offset(x: 40, y: 8)
            Rectangle().fill(Color.white.opacity(0.9)).frame(width: 48, height: 12)
                .overlay(Rectangle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
                .offset(x: 20, y: 12)
        }
    }
}

#Preview {
    ZStack {
        PetBackground(stage: 4, timeOfDay: .afternoon)
    }
}
