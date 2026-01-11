//
//  TotalActivityReport.swift
//  UnhookedActivityReport
//
//  Created by Simon Chen on 11/11/25.
//

import DeviceActivity
import ExtensionKit
import SwiftUI

extension DeviceActivityReport.Context {
    // If your app initializes a DeviceActivityReport with this context, then the system will use
    // your extension's corresponding DeviceActivityReportScene to render the contents of the
    // report.
    static let totalActivity = Self("Total Activity")
}

@MainActor
struct TotalActivityReport: DeviceActivityReportScene {
    // Define which context your scene will represent.
    let context: DeviceActivityReport.Context = .totalActivity
    
    // Define the custom configuration and the resulting view for this report.
    let content: (String) -> TotalActivityView
    
    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> String {
        print("📊🔥 DeviceActivityReport.makeConfiguration() CALLED!")
        
        // Calculate total activity duration
        var totalActivityDuration: TimeInterval = 0
        var segmentCount = 0
        
        for await segment in data.flatMap({ $0.activitySegments }) {
            totalActivityDuration += segment.totalActivityDuration
            segmentCount += 1
        }
        
        print("   📊 Found \(segmentCount) activity segments")
        print("   📊 Total duration: \(totalActivityDuration) seconds")
        
        // Convert to minutes
        let totalMinutes = Int(totalActivityDuration / 60)
        print("   📊 Total minutes: \(totalMinutes)")
        
        // Save to App Group for main app to read
        let accepted = ScreenTimeUsageManager.shared.updateUsage(newMinutes: totalMinutes)
        print("   \(accepted ? "✅" : "❌") Update \(totalMinutes) minutes: \(accepted ? "accepted" : "rejected")")
        
        // Format for display
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .pad
        
        let formatted = formatter.string(from: totalActivityDuration) ?? "0m"
        print("   📊 Formatted: \(formatted)")
        
        return formatted
    }
}
