//
//  DailyCheckIn.swift
//  Unhooked
//
//  Daily usage tracking component
//

import SwiftUI

struct DailyCheckIn: View {
    let currentUsage: Int
    let currentLimit: Int
    let energyBalance: Int
    let onCheckIn: (Int, Int) -> Void  // Keeping for compatibility, but not used
    let onRefresh: () -> Void  // New: manual refresh callback
    
    private var usageRatio: Double {
        guard currentLimit > 0 else { return 0 }
        return Double(currentUsage) / Double(currentLimit)
    }
    
    private var statusColor: Color {
        if usageRatio <= 0.5 {
            return .green
        } else if usageRatio < 1.0 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var statusIcon: String {
        if usageRatio <= 0.5 {
            return "checkmark.circle.fill"
        } else if usageRatio < 1.0 {
            return "exclamationmark.triangle.fill"
        } else {
            return "xmark.circle.fill"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Screen Time")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.black.opacity(0.6))
                
                if currentLimit > 0 {
                    HStack(spacing: 6) {
                        Text("\(currentUsage)/\(currentLimit)")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(.black)
                        Text("min")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.black.opacity(0.6))
                    }
                } else {
                    Text("Not set up")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black.opacity(0.6))
                }
            }
            
            Spacer()
            
            // Refresh button with test data option
            if currentLimit > 0 {
                Menu {
                    Button("Refresh Usage") {
                        print("👆 Refresh button tapped")
                        onRefresh()
                    }
                    Button("Test: Add 5 min") {
                        print("👆 Test: Add 5 min button tapped")
                        let manager = ScreenTimeUsageManager.shared
                        let current = manager.getCurrentMinutes()
                        let newTotal = current + 5
                        manager.forceSetUsage(minutes: newTotal)  // Use force for testing
                        print("🧪 Test: Set to \(newTotal) minutes")
                        onRefresh()
                    }
                    Button("Test: Reset to 0") {
                        print("👆 Test: Reset to 0 button tapped")
                        ScreenTimeUsageManager.shared.clearUsageData()
                        print("🧪 Test: Reset to 0")
                        onRefresh()
                    }
                    Button("Test: Set to 30") {
                        print("👆 Test: Set to 30 button tapped")
                        ScreenTimeUsageManager.shared.forceSetUsage(minutes: 30)
                        print("🧪 Test: Set to 30 minutes")
                        onRefresh()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                }
                .padding(8)
                .background(.white)
                .retroBorder(width: 3, cornerRadius: 8)
            }
            
            HStack(spacing: 8) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(RetroColors.yellow)
                
                Text("\(energyBalance)")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.white)
            .retroBorder(width: 3, cornerRadius: 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.white)
        .retroBorder(width: 4, cornerRadius: 16)
        .retroShadow(offset: 4)
    }
    
    /* REMOVED: Manual check-in sheet - now using automatic Screen Time tracking
    
    private var checkInSheet: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Check your Screen Time in Settings and enter today's usage.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Image(systemName: "gearshape.fill")
                            Text("Settings → Screen Time → See All Activity")
                                .font(.caption)
                        }
                        .padding(8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                } header: {
                    Text("How to Check")
                }
                
                Section {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundStyle(.blue)
                        TextField("Usage (minutes)", text: $usageMinutes)
                            .keyboardType(.numberPad)
                    }
                    
                    HStack {
                        Image(systemName: "target")
                            .foregroundStyle(.green)
                        TextField("Daily Limit (minutes)", text: $limitMinutes)
                            .keyboardType(.numberPad)
                    }
                } header: {
                    Text("Today's Screen Time")
                } footer: {
                    Text("Staying under your limit earns more Energy for your pet!")
                }
                
                if currentLimit > 0 {
                    Section {
                        HStack {
                            Text("Current:")
                            Spacer()
                            Text("\(currentUsage) / \(currentLimit) min")
                                .monospacedDigit()
                                .foregroundColor(.secondary)
                        }
                    } header: {
                        Text("Current Values")
                    }
                }
            }
            .navigationTitle("Daily Check-In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingSheet = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveCheckIn()
                    }
                    .disabled(usageMinutes.isEmpty || limitMinutes.isEmpty)
                }
            }
            .onAppear {
                if currentUsage > 0 {
                    usageMinutes = "\(currentUsage)"
                }
                if currentLimit > 0 {
                    limitMinutes = "\(currentLimit)"
                }
            }
        }
    }
    
    private func saveCheckIn() {
        guard let usage = Int(usageMinutes),
              let limit = Int(limitMinutes),
              usage >= 0,
              limit > 0 else {
            return
        }
        
        onCheckIn(usage, limit)
        showingSheet = false
    }
    */
}

#Preview {
    VStack(spacing: 20) {
        DailyCheckIn(currentUsage: 0, currentLimit: 0, energyBalance: 100, onCheckIn: { _, _ in }, onRefresh: {})
        DailyCheckIn(currentUsage: 60, currentLimit: 120, energyBalance: 150, onCheckIn: { _, _ in }, onRefresh: {})
        DailyCheckIn(currentUsage: 90, currentLimit: 120, energyBalance: 80, onCheckIn: { _, _ in }, onRefresh: {})
        DailyCheckIn(currentUsage: 150, currentLimit: 120, energyBalance: 50, onCheckIn: { _, _ in }, onRefresh: {})
    }
    .padding()
    .background(RetroGradients.background)
}

