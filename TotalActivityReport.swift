//
//  TotalActivityReport.swift
//  UnhookedDeviceActivity
//
//  Report view that displays total app usage
//  ADD THIS FILE TO THE DeviceActivity EXTENSION TARGET
//

import SwiftUI
import DeviceActivity

struct TotalActivityReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .totalActivity
    let content: (ActivityReport) -> TotalActivityView
    
    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> ActivityReport {
        var totalDuration: TimeInterval = 0
        var appUsages: [String: TimeInterval] = [:]
        
        // Sum up all app usage
        for await activity in data {
            for await application in activity.applications {
                let duration = application.totalActivityDuration
                totalDuration += duration
                
                // Store individual app usage
                if let token = application.token {
                    let tokenString = "\(token)"
                    appUsages[tokenString] = duration
                }
            }
        }
        
        // Convert to minutes
        let totalMinutes = Int(totalDuration / 60)
        
        // Save to shared storage using validated update
        let accepted = ScreenTimeUsageManager.shared.updateUsage(newMinutes: totalMinutes)
        print("📊 DeviceActivityReport: \(totalMinutes) min - \(accepted ? "accepted" : "rejected")")
        
        return ActivityReport(totalMinutes: totalMinutes)
    }
}

// MARK: - Report Data Model

struct ActivityReport {
    let totalMinutes: Int
}

// MARK: - Report View

struct TotalActivityView: View {
    let report: ActivityReport
    
    var body: some View {
        VStack(spacing: 8) {
            Text("\(report.totalMinutes)")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text("minutes today")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

// Note: This file must be added to the DeviceActivity Extension target
// The report will be displayed inline in your app using DeviceActivityReport




//  UnhookedDeviceActivity
//
//  Report view that displays total app usage
//  ADD THIS FILE TO THE DeviceActivity EXTENSION TARGET
//

import SwiftUI
import DeviceActivity

struct TotalActivityReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .totalActivity
    let content: (ActivityReport) -> TotalActivityView
    
    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> ActivityReport {
        var totalDuration: TimeInterval = 0
        var appUsages: [String: TimeInterval] = [:]
        
        // Sum up all app usage
        for await activity in data {
            for await application in activity.applications {
                let duration = application.totalActivityDuration
                totalDuration += duration
                
                // Store individual app usage
                if let token = application.token {
                    let tokenString = "\(token)"
                    appUsages[tokenString] = duration
                }
            }
        }
        
        // Convert to minutes
        let totalMinutes = Int(totalDuration / 60)
        
        // Save to shared storage using validated update
        let accepted = ScreenTimeUsageManager.shared.updateUsage(newMinutes: totalMinutes)
        print("📊 DeviceActivityReport: \(totalMinutes) min - \(accepted ? "accepted" : "rejected")")
        
        return ActivityReport(totalMinutes: totalMinutes)
    }
}

// MARK: - Report Data Model

struct ActivityReport {
    let totalMinutes: Int
}

// MARK: - Report View

struct TotalActivityView: View {
    let report: ActivityReport
    
    var body: some View {
        VStack(spacing: 8) {
            Text("\(report.totalMinutes)")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text("minutes today")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

// Note: This file must be added to the DeviceActivity Extension target
// The report will be displayed inline in your app using DeviceActivityReport




//  UnhookedDeviceActivity
//
//  Report view that displays total app usage
//  ADD THIS FILE TO THE DeviceActivity EXTENSION TARGET
//

import SwiftUI
import DeviceActivity

struct TotalActivityReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .totalActivity
    let content: (ActivityReport) -> TotalActivityView
    
    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> ActivityReport {
        var totalDuration: TimeInterval = 0
        var appUsages: [String: TimeInterval] = [:]
        
        // Sum up all app usage
        for await activity in data {
            for await application in activity.applications {
                let duration = application.totalActivityDuration
                totalDuration += duration
                
                // Store individual app usage
                if let token = application.token {
                    let tokenString = "\(token)"
                    appUsages[tokenString] = duration
                }
            }
        }
        
        // Convert to minutes
        let totalMinutes = Int(totalDuration / 60)
        
        // Save to shared storage using validated update
        let accepted = ScreenTimeUsageManager.shared.updateUsage(newMinutes: totalMinutes)
        print("📊 DeviceActivityReport: \(totalMinutes) min - \(accepted ? "accepted" : "rejected")")
        
        return ActivityReport(totalMinutes: totalMinutes)
    }
}

// MARK: - Report Data Model

struct ActivityReport {
    let totalMinutes: Int
}

// MARK: - Report View

struct TotalActivityView: View {
    let report: ActivityReport
    
    var body: some View {
        VStack(spacing: 8) {
            Text("\(report.totalMinutes)")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text("minutes today")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

// Note: This file must be added to the DeviceActivity Extension target
// The report will be displayed inline in your app using DeviceActivityReport




//  UnhookedDeviceActivity
//
//  Report view that displays total app usage
//  ADD THIS FILE TO THE DeviceActivity EXTENSION TARGET
//

import SwiftUI
import DeviceActivity

struct TotalActivityReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .totalActivity
    let content: (ActivityReport) -> TotalActivityView
    
    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> ActivityReport {
        var totalDuration: TimeInterval = 0
        var appUsages: [String: TimeInterval] = [:]
        
        // Sum up all app usage
        for await activity in data {
            for await application in activity.applications {
                let duration = application.totalActivityDuration
                totalDuration += duration
                
                // Store individual app usage
                if let token = application.token {
                    let tokenString = "\(token)"
                    appUsages[tokenString] = duration
                }
            }
        }
        
        // Convert to minutes
        let totalMinutes = Int(totalDuration / 60)
        
        // Save to shared storage using validated update
        let accepted = ScreenTimeUsageManager.shared.updateUsage(newMinutes: totalMinutes)
        print("📊 DeviceActivityReport: \(totalMinutes) min - \(accepted ? "accepted" : "rejected")")
        
        return ActivityReport(totalMinutes: totalMinutes)
    }
}

// MARK: - Report Data Model

struct ActivityReport {
    let totalMinutes: Int
}

// MARK: - Report View

struct TotalActivityView: View {
    let report: ActivityReport
    
    var body: some View {
        VStack(spacing: 8) {
            Text("\(report.totalMinutes)")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text("minutes today")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

// Note: This file must be added to the DeviceActivity Extension target
// The report will be displayed inline in your app using DeviceActivityReport



