//
//  DailyCheckIn.swift
//  Unhooked
//
//  Daily usage tracking component
//

import SwiftUI

struct DailyCheckIn: View {
    @State private var showingSheet = false
    @State private var usageMinutes: String = ""
    @State private var limitMinutes: String = ""
    
    let currentUsage: Int
    let currentLimit: Int
    let onCheckIn: (Int, Int) -> Void
    
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
        Button {
            showingSheet = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.black)
                
                VStack(alignment: .leading, spacing: 4) {
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
                        Text("0/120 min")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(.black)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(RetroColors.yellow)
                    
                    Text("150")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.white)
                .retroBorder(width: 3, cornerRadius: 8)
                
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.black)
                    .padding(8)
                    .background(.white)
                    .retroBorder(width: 3, cornerRadius: 8)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.white)
            .retroBorder(width: 4, cornerRadius: 16)
            .retroShadow(offset: 4)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingSheet) {
            checkInSheet
        }
    }
    
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
}

#Preview {
    VStack(spacing: 20) {
        DailyCheckIn(currentUsage: 0, currentLimit: 0) { _, _ in }
        DailyCheckIn(currentUsage: 60, currentLimit: 120) { _, _ in }
        DailyCheckIn(currentUsage: 90, currentLimit: 120) { _, _ in }
        DailyCheckIn(currentUsage: 150, currentLimit: 120) { _, _ in }
    }
    .padding()
    .background(RetroGradients.background)
}

