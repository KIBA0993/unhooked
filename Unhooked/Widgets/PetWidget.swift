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
        guard let appGroup = UserDefaults(suiteName: "group.com.unhooked.shared"),
              let data = appGroup.data(forKey: "petWidgetData"),
              let widgetData = try? JSONDecoder().decode(PetWidgetData.self, from: data) else {
            return nil
        }
        return widgetData
    }
}

// MARK: - Widget Views

struct PetWidgetSmallView: View {
    let data: PetWidgetData?
    
    var body: some View {
        if let data = data {
            VStack(spacing: 8) {
                // Pet emoji
                Text(data.petSpecies == .cat ? "🐱" : "🐶")
                    .font(.system(size: 40))
                    .grayscale(data.healthState == .dead ? 1.0 : 0.0)
                    .opacity(data.healthState == .dead ? 0.5 : 1.0)
                
                // Stage
                Text("Stage \(data.petStage)")
                    .font(.caption2)
                    .fontWeight(.medium)
                
                // Health indicator
                if data.healthState != .healthy {
                    Image(systemName: data.healthState == .sick ? "thermometer.medium" : "cloud.fill")
                        .foregroundStyle(data.healthState == .sick ? .orange : .gray)
                        .font(.caption)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
        } else {
            placeholderView
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
            HStack(spacing: 16) {
                // Pet display
                VStack {
                    Text(data.petSpecies == .cat ? "🐱" : "🐶")
                        .font(.system(size: 50))
                        .grayscale(data.healthState == .dead ? 1.0 : 0.0)
                        .opacity(data.healthState == .dead ? 0.5 : 1.0)
                    
                    Text("Stage \(data.petStage)")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    if data.isFragile {
                        Image(systemName: "bandage.fill")
                            .foregroundStyle(.orange)
                            .font(.caption2)
                    }
                }
                
                Divider()
                
                // Stats
                VStack(alignment: .leading, spacing: 8) {
                    // Health
                    HStack {
                        Image(systemName: healthIcon(data.healthState))
                            .foregroundStyle(healthColor(data.healthState))
                        Text(data.healthState.rawValue.capitalized)
                            .font(.caption)
                    }
                    
                    // Fullness
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.pink)
                        Text("\(data.fullness)%")
                            .font(.caption)
                            .monospacedDigit()
                    }
                    
                    // Energy
                    HStack {
                        Image(systemName: "bolt.fill")
                            .foregroundStyle(.yellow)
                        Text("\(data.energyBalance)")
                            .font(.caption)
                            .monospacedDigit()
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(Color(.systemBackground))
        } else {
            placeholderView
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
    
    // Lock Screen Circular
    private var accessoryCircularView: some View {
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
    
    // Lock Screen Rectangular
    private var accessoryRectangularView: some View {
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

// MARK: - Widget Bundle

@main
struct UnhookedWidgets: WidgetBundle {
    var body: some Widget {
        PetWidget()
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

