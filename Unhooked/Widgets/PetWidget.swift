//
//  PetWidget.swift
//  Unhooked
//
//  Home screen and lock screen widgets
//

import SwiftUI
import WidgetKit

// MARK: - Widget Entry

struct PetWidgetEntry: TimelineEntry {
    let date: Date
    let petData: PetWidgetData?
}

// MARK: - Widget Provider

struct PetWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> PetWidgetEntry {
        PetWidgetEntry(date: Date(), petData: nil)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (PetWidgetEntry) -> Void) {
        let entry = PetWidgetEntry(
            date: Date(),
            petData: loadWidgetData()
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<PetWidgetEntry>) -> Void) {
        let entry = PetWidgetEntry(
            date: Date(),
            petData: loadWidgetData()
        )
        
        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        
        completion(timeline)
    }
    
    private func loadWidgetData() -> PetWidgetData? {
        guard let appGroup = UserDefaults(suiteName: "group.com.kookytrove.unhooked"),
              let data = appGroup.data(forKey: "petWidgetData"),
              let widgetData = try? JSONDecoder().decode(PetWidgetData.self, from: data) else {
            return nil
        }
        return widgetData
    }
}

// MARK: - Widget Pixel Pet (Simplified)

struct WidgetPixelPet: View {
    let stage: Int
    let species: Species
    let healthState: HealthState
    
    var body: some View {
        WidgetPixelGrid(
            pixels: species == .cat ? getCatPixels() : getDogPixels(),
            scale: 4
        )
        .opacity(healthState == .dead ? 0.7 : 1.0)
        .grayscale(healthState == .dead ? 1.0 : 0.0)
    }
    
    private func getCatPixels() -> [[String]] {
        switch stage {
        case 0: // Egg
            return [
                [".", ".", "K", "K", "K", "K", "K", "K", ".", "."],
                [".", "K", "K", "W", "W", "W", "W", "K", "K", "."],
                ["K", "K", "W", "W", "K", "K", "W", "W", "K", "K"],
                ["K", "W", "W", "K", "K", "K", "K", "W", "W", "K"],
                ["K", "W", "K", "K", "K", "K", "K", "K", "W", "K"],
                ["K", "W", "K", "K", "K", "K", "K", "K", "W", "K"],
                ["K", "W", "W", "K", "K", "K", "K", "W", "W", "K"],
                ["K", "K", "W", "W", "W", "W", "W", "W", "K", "K"],
                [".", "K", "K", "W", "W", "W", "W", "K", "K", "."],
                [".", ".", "K", "K", "K", "K", "K", "K", ".", "."]
            ]
        case 1: // Baby
            return [
                ["K", ".", ".", ".", ".", ".", ".", ".", "K", "."],
                ["K", "K", "K", "K", "K", "K", "K", "K", "K", "K"],
                ["K", "K", "G", "K", "K", "K", "G", "K", "K", "K"],
                ["K", "K", "g", "K", "K", "K", "g", "K", "K", "K"],
                [".", "K", "K", "K", "P", "P", "K", "K", "K", "."],
                [".", "K", "W", "W", "W", "W", "W", "W", "K", "."],
                [".", "K", "W", "W", "W", "W", "W", "W", "K", "."],
                [".", ".", "K", "W", "W", "W", "W", "K", ".", "."],
                [".", "K", "W", "K", ".", ".", "K", "W", "K", "."],
                [".", "K", "K", ".", ".", ".", ".", "K", "K", "."]
            ]
        case 2: // Child
            return [
                ["K", ".", ".", ".", ".", ".", ".", ".", ".", "K"],
                ["K", "K", "K", "K", "K", "K", "K", "K", "K", "K"],
                ["K", "K", "G", "K", "K", "K", "K", "G", "K", "K"],
                ["K", "K", "g", "G", "K", "K", "g", "G", "K", "K"],
                [".", "K", "K", "K", "K", "P", "K", "K", "K", "K"],
                [".", "K", "K", "K", "P", "p", "P", "K", "K", "K"],
                [".", "K", "W", "W", "W", "W", "W", "W", "W", "K"],
                [".", ".", "K", "W", "W", "W", "W", "W", "K", "."],
                [".", "K", "W", "K", "W", "K", "W", "K", "W", "K"],
                [".", "K", "K", ".", "K", "K", "K", "K", ".", "K"]
            ]
        case 3: // Teen
            return [
                ["K", ".", ".", ".", ".", ".", ".", ".", ".", "."],
                ["K", "K", "K", "K", "K", "K", "K", "K", "K", "K"],
                ["K", "K", "G", "g", "K", "K", "K", "G", "g", "K"],
                ["K", "K", "G", "G", "K", "K", "K", "G", "G", "K"],
                [".", "K", "K", "K", "K", "P", "P", "K", "K", "K"],
                [".", "K", "W", "W", "W", "P", "P", "W", "W", "W"],
                [".", "K", "W", "W", "W", "W", "W", "W", "W", "W"],
                [".", ".", "K", "W", "W", "W", "W", "W", "W", "K"],
                ["K", "W", "K", "W", "K", "W", "K", "W", "K", "W"],
                ["K", "K", ".", "K", "K", "K", "K", "K", "K", "K"]
            ]
        default: // Adult (stage 4+)
            return [
                [".", ".", ".", "Y", ".", "Y", ".", "Y", ".", "."],
                [".", ".", "Y", "Y", "Y", "Y", "Y", "Y", "Y", "."],
                ["K", ".", ".", "Y", "Y", "Y", "Y", "Y", ".", "."],
                ["K", "K", "K", "K", "K", "K", "K", "K", "K", "K"],
                ["K", "K", "M", "G", "K", "K", "K", "M", "G", "K"],
                ["K", "K", "G", "G", "K", "K", "K", "G", "G", "K"],
                [".", "K", "K", "K", "K", "P", "P", "K", "K", "K"],
                [".", "K", "W", "W", "W", "p", "p", "W", "W", "W"],
                [".", "K", "W", "W", "W", "W", "W", "W", "W", "W"],
                ["K", "W", "K", "W", "K", "W", "K", "W", "K", "W"]
            ]
        }
    }
    
    private func getDogPixels() -> [[String]] {
        switch stage {
        case 0: // Egg
            return [
                [".", ".", "K", "K", "K", "K", "K", "K", ".", "."],
                [".", "K", "C", "C", "E", "E", "C", "C", "K", "."],
                ["K", "C", "C", "E", "O", "E", "C", "C", "C", "K"],
                ["K", "C", "E", "E", "C", "C", "E", "O", "C", "K"],
                ["K", "C", "C", "C", "C", "C", "C", "E", "C", "K"],
                ["K", "C", "O", "C", "C", "C", "C", "C", "C", "K"],
                ["K", "C", "C", "C", "E", "C", "C", "C", "C", "K"],
                ["K", "C", "C", "C", "C", "C", "O", "C", "C", "K"],
                [".", "K", "C", "C", "C", "C", "C", "C", "K", "."],
                [".", ".", "K", "K", "K", "K", "K", "K", ".", "."]
            ]
        case 1: // Baby
            return [
                [".", "E", "E", ".", ".", ".", ".", "E", "E", "."],
                ["E", "E", "O", "E", ".", ".", "E", "O", "E", "E"],
                ["E", "E", "E", "K", "K", "K", "K", "E", "E", "E"],
                [".", "K", "D", "D", "C", "C", "D", "D", "K", "."],
                [".", "K", "D", "C", "C", "C", "C", "D", "K", "."],
                [".", ".", "K", "C", "K", "K", "C", "K", ".", "."],
                [".", ".", "K", "N", "N", "N", "N", "K", ".", "."],
                [".", ".", "K", "C", "C", "C", "C", "K", ".", "."],
                [".", "K", "C", "K", ".", ".", "K", "C", "K", "."],
                [".", "K", "K", ".", ".", ".", ".", "K", "K", "."]
            ]
        case 2: // Child
            return [
                [".", "E", "E", ".", ".", ".", ".", ".", "E", "E"],
                ["E", "E", "O", "E", ".", ".", ".", "E", "O", "E"],
                ["E", "E", "E", "E", "K", "K", "K", "E", "E", "E"],
                [".", "K", "D", "D", "D", "C", "D", "D", "D", "K"],
                [".", "K", "D", "D", "C", "C", "C", "D", "D", "K"],
                [".", ".", "K", "C", "C", "K", "C", "C", "K", "."],
                [".", ".", "K", "N", "N", "N", "N", "N", "K", "."],
                [".", ".", "K", "T", "T", "T", "T", "T", "K", "."],
                [".", "K", "C", "K", "C", "K", "C", "K", "C", "K"],
                [".", "K", "K", ".", "K", "K", "K", "K", ".", "K"]
            ]
        case 3: // Teen
            return [
                [".", "E", "E", "E", ".", ".", ".", ".", ".", "E"],
                ["E", "E", "O", "E", "E", ".", ".", ".", "E", "O"],
                ["E", "E", "E", "E", "E", "K", "K", "K", "E", "E"],
                [".", "K", "D", "D", "D", "D", "C", "D", "D", "D"],
                [".", "K", "D", "D", "C", "C", "C", "C", "D", "D"],
                [".", ".", "K", "C", "C", "C", "K", "C", "C", "K"],
                [".", ".", "K", "C", "N", "N", "N", "N", "C", "K"],
                [".", ".", "K", "T", "T", "T", "T", "T", "T", "K"],
                [".", "K", "C", "C", "C", "C", "C", "C", "C", "C"],
                ["K", "C", "K", "C", "K", "C", "K", "C", "K", "C"]
            ]
        default: // Adult (stage 4+)
            return [
                [".", ".", "Y", ".", "Y", ".", "Y", ".", "Y", "."],
                [".", "Y", "Y", "Y", "Y", "Y", "Y", "Y", "Y", "Y"],
                [".", "E", "E", "Y", "Y", "Y", "Y", "Y", "E", "E"],
                ["E", "E", "O", "E", "E", ".", ".", "E", "O", "E"],
                ["E", "E", "E", "E", "E", "K", "K", "E", "E", "E"],
                [".", "K", "D", "D", "D", "D", "D", "D", "D", "K"],
                [".", "K", "D", "D", "C", "C", "C", "D", "D", "K"],
                [".", ".", "K", "N", "N", "N", "N", "N", "K", "."],
                [".", ".", "K", "T", "T", "T", "T", "T", "K", "."],
                ["K", "C", "K", "C", "K", "C", "K", "C", "K", "C"]
            ]
        }
    }
}

struct WidgetPixelGrid: View {
    let pixels: [[String]]
    let scale: CGFloat
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(pixels.indices, id: \.self) { rowIndex in
                HStack(spacing: 0) {
                    ForEach(pixels[rowIndex].indices, id: \.self) { colIndex in
                        let pixel = pixels[rowIndex][colIndex]
                        Rectangle()
                            .fill(getColor(for: pixel))
                            .frame(width: scale, height: scale)
                    }
                }
            }
        }
    }
    
    private func getColor(for pixel: String) -> Color {
        switch pixel {
        case ".": return .clear
        case "K": return .black
        case "W": return .white
        case "G": return Color(red: 0.56, green: 0.93, blue: 0.56) // Light green
        case "g": return Color(red: 0.13, green: 0.55, blue: 0.13) // Dark green
        case "P": return Color(red: 1.0, green: 0.71, blue: 0.76) // Pink
        case "p": return Color(red: 1.0, green: 0.41, blue: 0.71) // Hot pink
        case "C": return Color(red: 1.0, green: 0.89, blue: 0.77) // Cream
        case "E": return Color(red: 1.0, green: 0.71, blue: 0.85) // Pink ears
        case "O": return Color(red: 1.0, green: 0.65, blue: 0.0) // Orange
        case "D": return Color(red: 0.18, green: 0.31, blue: 0.31) // Dark patches
        case "N": return Color(red: 0.55, green: 0.27, blue: 0.07) // Brown
        case "T": return Color(red: 0.25, green: 0.88, blue: 0.82) // Turquoise
        case "B": return Color(red: 0.55, green: 0.27, blue: 0.07) // Brown
        case "Y": return Color(red: 1.0, green: 0.84, blue: 0.0) // Gold crown
        case "M": return Color(red: 0.60, green: 0.20, blue: 0.80) // Purple mystical
        default: return .red
        }
    }
}

// MARK: - Widget Views

struct PetWidgetSmallView: View {
    let data: PetWidgetData?
    
    var body: some View {
        if let data = data {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: getSkyColors(),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    // Ground
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.2, green: 0.7, blue: 0.3), Color(red: 0.1, green: 0.5, blue: 0.2)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 30)
                }
                
                // Pixel Pet
                VStack {
                    Spacer()
                    
                    WidgetPixelPet(
                        stage: data.petStage,
                        species: data.petSpecies,
                        healthState: data.healthState
                    )
                    .scaleEffect(0.8)
                    .frame(height: 60)
                    .padding(.bottom, 25)
                }
                
                // Stage badge (top)
                VStack {
                    HStack {
                        Spacer()
                        Text("Stage \(data.petStage)")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.9))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.black, lineWidth: 1))
                            .padding(6)
                    }
                    Spacer()
                }
            }
        } else {
            placeholderView
        }
    }
    
    private func getSkyColors() -> [Color] {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 6 && hour < 12 {
            return [Color(red: 0.5, green: 0.8, blue: 1.0), Color(red: 0.9, green: 0.7, blue: 0.4)]
        } else if hour >= 12 && hour < 18 {
            return [Color(red: 0.3, green: 0.6, blue: 1.0), Color(red: 0.6, green: 0.8, blue: 1.0)]
        } else if hour >= 18 && hour < 21 {
            return [Color(red: 0.5, green: 0.3, blue: 0.8), Color(red: 0.9, green: 0.4, blue: 0.6)]
        } else {
            return [Color(red: 0.1, green: 0.0, blue: 0.3), Color(red: 0.3, green: 0.1, blue: 0.5)]
        }
    }
    
    private var placeholderView: some View {
        VStack {
            Image(systemName: "pawprint.fill")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("Open app")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

struct PetWidgetMediumView: View {
    let data: PetWidgetData?
    
    var body: some View {
        if let data = data {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: getSkyColors(),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    // Ground
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.2, green: 0.7, blue: 0.3), Color(red: 0.1, green: 0.5, blue: 0.2)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 40)
                }
                
                HStack(spacing: 12) {
                    // Pet display
                    VStack {
                        Spacer()
                        
                        WidgetPixelPet(
                            stage: data.petStage,
                            species: data.petSpecies,
                            healthState: data.healthState
                        )
                        .scaleEffect(1.2)
                        .frame(height: 80)
                        .padding(.bottom, 35)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Stats
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Stage \(data.petStage)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(0.9))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.black, lineWidth: 1))
                        
                        // Health
                        HStack(spacing: 4) {
                            Image(systemName: healthIcon(data.healthState))
                                .foregroundStyle(healthColor(data.healthState))
                                .frame(width: 16)
                            Text(data.healthState.rawValue.capitalized)
                                .font(.caption2)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(6)
                        
                        // Fullness
                        HStack(spacing: 4) {
                            Text("🍖")
                                .font(.caption2)
                            Text("\(data.fullness)%")
                                .font(.caption)
                                .monospacedDigit()
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(6)
                        
                        // Energy
                        HStack(spacing: 4) {
                            Image(systemName: "bolt.fill")
                                .foregroundStyle(.yellow)
                                .font(.caption2)
                            Text("\(data.energyBalance)")
                                .font(.caption)
                                .monospacedDigit()
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(6)
                    }
                    .padding(.trailing, 8)
                }
                .padding(.horizontal, 8)
            }
        } else {
            placeholderView
        }
    }
    
    private func getSkyColors() -> [Color] {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 6 && hour < 12 {
            return [Color(red: 0.5, green: 0.8, blue: 1.0), Color(red: 0.9, green: 0.7, blue: 0.4)]
        } else if hour >= 12 && hour < 18 {
            return [Color(red: 0.3, green: 0.6, blue: 1.0), Color(red: 0.6, green: 0.8, blue: 1.0)]
        } else if hour >= 18 && hour < 21 {
            return [Color(red: 0.5, green: 0.3, blue: 0.8), Color(red: 0.9, green: 0.4, blue: 0.6)]
        } else {
            return [Color(red: 0.1, green: 0.0, blue: 0.3), Color(red: 0.3, green: 0.1, blue: 0.5)]
        }
    }
    
    private func healthIcon(_ state: HealthState) -> String {
        switch state {
        case .healthy: return "checkmark.circle.fill"
        case .sick: return "thermometer.medium"
        case .dead: return "cloud.fill"
        }
    }
    
    private func healthColor(_ state: HealthState) -> Color {
        switch state {
        case .healthy: return .green
        case .sick: return .orange
        case .dead: return .gray
        }
    }
    
    private var placeholderView: some View {
        HStack {
            Image(systemName: "pawprint.fill")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("Open Unhooked to see your pet")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

struct PetWidgetLargeView: View {
    let data: PetWidgetData?
    
    var body: some View {
        if let data = data {
            VStack(spacing: 12) {
                // Header
                HStack {
                    Text(data.petSpecies.rawValue.capitalized)
                        .font(.headline)
                    Spacer()
                    Text("Stage \(data.petStage)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                // Pet display
                ZStack {
                    Circle()
                        .fill(.gray.opacity(0.1))
                        .frame(height: 100)
                    
                    Text(data.petSpecies == .cat ? "🐱" : "🐶")
                        .font(.system(size: 60))
                        .grayscale(data.healthState == .dead ? 1.0 : 0.0)
                        .opacity(data.healthState == .dead ? 0.5 : 1.0)
                }
                
                // Stats grid
                VStack(spacing: 8) {
                    statRow(
                        icon: "checkmark.circle.fill",
                        label: "Health",
                        value: data.healthState.rawValue.capitalized,
                        color: data.healthState == .healthy ? .green : (data.healthState == .sick ? .orange : .gray)
                    )
                    
                    statRow(
                        icon: "heart.fill",
                        label: "Fullness",
                        value: "\(data.fullness)%",
                        color: .pink
                    )
                    
                    statRow(
                        icon: "face.smiling",
                        label: "Mood",
                        value: "\(data.mood)/10",
                        color: .yellow
                    )
                    
                    Divider()
                    
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "bolt.fill")
                                .foregroundStyle(.yellow)
                            Text("\(data.energyBalance)")
                                .monospacedDigit()
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: "diamond.fill")
                                .foregroundStyle(.cyan)
                            Text("\(data.gemsBalance)")
                                .monospacedDigit()
                        }
                    }
                    .font(.caption)
                }
            }
            .padding()
            .background(Color(.systemBackground))
        } else {
            placeholderView
        }
    }
    
    private func statRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 20)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
    
    private var placeholderView: some View {
        VStack {
            Image(systemName: "pawprint.fill")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("Open Unhooked")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

// MARK: - Widget Configuration

struct PetWidget: Widget {
    let kind: String = "PetWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PetWidgetProvider()) { entry in
            PetWidgetView(entry: entry)
        }
        .configurationDisplayName("My Pet")
        .description("Keep an eye on your virtual friend")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryCircular, .accessoryRectangular])
    }
}

struct PetWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: PetWidgetEntry
    
    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                PetWidgetSmallView(data: entry.petData)
            case .systemMedium:
                PetWidgetMediumView(data: entry.petData)
            case .systemLarge:
                PetWidgetLargeView(data: entry.petData)
            case .accessoryCircular:
                accessoryCircularView
            case .accessoryRectangular:
                accessoryRectangularView
            default:
                PetWidgetSmallView(data: entry.petData)
            }
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
    
    // Lock Screen Circular
    private var accessoryCircularView: some View {
        Group {
            if let data = entry.petData {
                ZStack {
                    Circle()
                        .fill(data.healthState == .healthy ? Color.green : (data.healthState == .sick ? Color.orange : Color.gray))
                        .opacity(0.3)
                    
                    Text(data.petSpecies == .cat ? "🐱" : "🐶")
                        .font(.title3)
                }
            } else {
                Image(systemName: "pawprint.fill")
                    .font(.title3)
            }
        }
    }
    
    // Lock Screen Rectangular
    private var accessoryRectangularView: some View {
        Group {
            if let data = entry.petData {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(data.petSpecies == .cat ? "🐱" : "🐶")
                        Text("Stage \(data.petStage)")
                            .font(.caption2)
                    }
                    
                    HStack(spacing: 8) {
                        HStack(spacing: 2) {
                            Image(systemName: "heart.fill")
                            Text("\(data.fullness)%")
                        }
                        
                        HStack(spacing: 2) {
                            Image(systemName: "bolt.fill")
                            Text("\(data.energyBalance)")
                        }
                    }
                    .font(.caption2)
                }
            } else {
                HStack {
                    Image(systemName: "pawprint.fill")
                    Text("Open app")
                        .font(.caption2)
                }
            }
        }
    }
}

// MARK: - Widget Bundle
// Note: This will have @main when moved to Widget Extension target
// For now, it's commented out to avoid conflict with UnhookedApp @main

@main
struct UnhookedWidgets: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        PetWidget()
        if #available(iOS 16.2, *) {
            PetLiveActivity()
        }
    }
}

#Preview(as: .systemSmall) {
    PetWidget()
} timeline: {
    PetWidgetEntry(date: .now, petData: PetWidgetData(
        petSpecies: .cat,
        petStage: 5,
        healthState: .healthy,
        fullness: 75,
        mood: 8,
        energyBalance: 120,
        gemsBalance: 50,
        isFragile: false,
        lastUpdate: Date()
    ))
}

