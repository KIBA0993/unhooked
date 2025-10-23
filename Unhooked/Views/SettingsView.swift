//
//  SettingsView.swift
//  Unhooked
//
//  Settings and daily limit configuration
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(AppViewModel.self) private var viewModel
    @StateObject private var screenTimeService = ScreenTimeService()
    @StateObject private var cloudSyncService = CloudSyncService()
    
    @State private var selectedLimit: Int = 180  // Default 3 hours
    @State private var showingLimitPicker = false
    
    // Widget preferences
    @AppStorage("widget.enabled") private var widgetEnabled = true
    @AppStorage("widget.showStats") private var showWidgetStats = true
    @AppStorage("dynamicIsland.enabled") private var dynamicIslandEnabled = true
    
    let limitOptions = [
        30, 60, 90, 120, 150, 180, 210, 240, 300, 360, 420, 480
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                // Screen Time Section
                Section {
                    HStack {
                        Text("Screen Time Access")
                        Spacer()
                        if screenTimeService.isAuthorized {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else {
                            Button("Authorize") {
                                Task {
                                    await screenTimeService.requestAuthorization()
                                }
                            }
                        }
                    }
                    
                    if screenTimeService.isAuthorized {
                        Button {
                            showingLimitPicker = true
                        } label: {
                            HStack {
                                Text("Daily Limit")
                                Spacer()
                                Text("\(selectedLimit) min")
                                    .foregroundStyle(.secondary)
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                } header: {
                    Text("Usage Tracking")
                } footer: {
                    Text("Grant Screen Time access to track your usage and earn Energy")
                }
                
                // iCloud Sync Section
                Section {
                    HStack {
                        Label {
                            Text("iCloud Sync")
                        } icon: {
                            Image(systemName: cloudSyncService.syncStatus.icon)
                                .foregroundStyle(cloudSyncService.iCloudAvailable ? .blue : .gray)
                        }
                        Spacer()
                        if cloudSyncService.iCloudAvailable {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else {
                            Text("Not Available")
                                .foregroundStyle(.secondary)
                                .font(.footnote)
                        }
                    }
                    
                    if cloudSyncService.iCloudAvailable {
                        Button {
                            cloudSyncService.refreshStatus()
                        } label: {
                            Label("Refresh Status", systemImage: "arrow.clockwise")
                        }
                    }
                } header: {
                    Text("Cloud Sync")
                } footer: {
                    Text(cloudSyncService.statusMessage)
                }
                
                // Account Section
                Section("Account") {
                    HStack {
                        Text("Energy Balance")
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "bolt.fill")
                                .foregroundStyle(.yellow)
                            Text("\(viewModel.energyBalance)")
                                .monospacedDigit()
                        }
                    }
                    
                    HStack {
                        Text("Gems Balance")
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "diamond.fill")
                                .foregroundStyle(.cyan)
                            Text("\(viewModel.gemsBalance)")
                                .monospacedDigit()
                        }
                    }
                    
                    NavigationLink {
                        PurchaseGemsView()
                            .environment(viewModel)
                    } label: {
                        Label("Buy Gems", systemImage: "cart.fill")
                    }
                }
                
                // Widget & Dynamic Island
                Section {
                    Toggle(isOn: $widgetEnabled) {
                        Label("Home Screen Widget", systemImage: "square.grid.2x2")
                    }
                    
                    if widgetEnabled {
                        Toggle(isOn: $showWidgetStats) {
                            Text("Show Detailed Stats")
                        }
                        .padding(.leading)
                    }
                    
                    Toggle(isOn: $dynamicIslandEnabled) {
                        Label("Live Activity (Dynamic Island)", systemImage: "sparkles")
                    }
                    
                    Button {
                        // Open widget gallery
                        if let url = URL(string: "widget://") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("Add to Home Screen", systemImage: "plus.square.on.square")
                    }
                } header: {
                    Text("Widgets & Live Activity")
                } footer: {
                    Text("Display your pet on your home screen, lock screen, or Dynamic Island")
                }
                
                // Memorial Section
                Section {
                    NavigationLink {
                        MemorialView()
                    } label: {
                        Label("Memories", systemImage: "cloud.fill")
                    }
                } header: {
                    Text("Memorial")
                }
                
                // About Section
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingLimitPicker) {
                limitPickerSheet
            }
            .onAppear {
                screenTimeService.checkAuthorizationStatus()
                cloudSyncService.checkiCloudStatus()
            }
        }
    }
    
    private var limitPickerSheet: some View {
        NavigationStack {
            List {
                ForEach(limitOptions, id: \.self) { minutes in
                    Button {
                        selectedLimit = minutes
                        screenTimeService.setDailyLimit(minutes: minutes)
                        showingLimitPicker = false
                    } label: {
                        HStack {
                            Text(formatMinutes(minutes))
                            Spacer()
                            if selectedLimit == minutes {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                }
            }
            .navigationTitle("Daily Limit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showingLimitPicker = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    private func formatMinutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        
        if hours > 0 && mins > 0 {
            return "\(hours)h \(mins)m"
        } else if hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        } else {
            return "\(mins) minutes"
        }
    }
}

#Preview {
    SettingsView()
        .environment(AppViewModel(modelContext: ModelContext(
            try! ModelContainer(for: Pet.self)
        )))
}

