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
    @State private var showingLiveActivityAlert = false
    @State private var liveActivityMessage = ""
    @State private var liveActivityStatus = ""
    
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
                    .onChange(of: dynamicIslandEnabled) { _, isEnabled in
                        if isEnabled, let pet = viewModel.currentPet {
                            if #available(iOS 16.2, *) {
                                viewModel.widgetService.startLiveActivity(
                                    pet: pet,
                                    energyBalance: viewModel.energyBalance
                                )
                            }
                        } else {
                            if #available(iOS 16.2, *) {
                                viewModel.widgetService.stopLiveActivity()
                            }
                        }
                    }
                    
                    if #available(iOS 16.2, *) {
                        Button {
                            // Start Live Activity with detailed feedback
                            print("👆 User tapped Start Dynamic Island button")
                            liveActivityStatus = "Starting..."
                            
                            if !dynamicIslandEnabled {
                                liveActivityStatus = "❌ Toggle is OFF"
                                liveActivityMessage = "Please enable the 'Live Activity' toggle first"
                                showingLiveActivityAlert = true
                                return
                            }
                            
                            guard let pet = viewModel.currentPet else {
                                liveActivityStatus = "❌ No pet found"
                                liveActivityMessage = "No pet found! Please restart the app."
                                showingLiveActivityAlert = true
                                return
                            }
                            
                            // Check authorization
                            let authInfo = ActivityAuthorizationInfo()
                            if !authInfo.areActivitiesEnabled {
                                liveActivityStatus = "❌ Not authorized"
                                liveActivityMessage = """
                                Live Activities are not enabled!
                                
                                To fix:
                                1. Open iOS Settings app
                                2. Scroll to "Unhooked"
                                3. Turn ON "Live Activities"
                                4. Try again
                                """
                                showingLiveActivityAlert = true
                                return
                            }
                            
                            liveActivityStatus = "✅ Authorized - Starting..."
                            
                            // Start the activity
                            viewModel.widgetService.startLiveActivity(
                                pet: pet,
                                energyBalance: viewModel.energyBalance
                            )
                            
                            // Show result after a moment
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                let activities = Activity<PetActivityAttributes>.activities
                                if activities.isEmpty {
                                    liveActivityStatus = "❌ Failed to create"
                                    liveActivityMessage = """
                                    Failed to start Live Activity!
                                    
                                    Possible issues:
                                    • Not on iPhone 14 Pro or later
                                    • Simulator needs restart
                                    • Check Xcode console for errors (⌘⇧Y)
                                    
                                    Device: \(UIDevice.current.model)
                                    System: iOS \(UIDevice.current.systemVersion)
                                    """
                                } else {
                                    liveActivityStatus = "✅ Active (\(activities.count))"
                                    liveActivityMessage = """
                                    ✅ Live Activity Started!
                                    
                                    Look at the TOP of your screen!
                                    You should see: \(pet.species == .cat ? "🐱" : "🐶")
                                    
                                    Active activities: \(activities.count)
                                    """
                                }
                                showingLiveActivityAlert = true
                            }
                        } label: {
                            Label("Start Dynamic Island", systemImage: "play.fill")
                        }
                        
                        if !liveActivityStatus.isEmpty {
                            Text(liveActivityStatus)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Button {
                            // Stop Live Activity
                            viewModel.widgetService.stopLiveActivity()
                        } label: {
                            Label("Stop Dynamic Island", systemImage: "stop.fill")
                        }
                        .foregroundStyle(.red)
                    }
                    
                    Button {
                        // Force update widgets
                        if let pet = viewModel.currentPet {
                            viewModel.widgetService.updateWidgets(
                                pet: pet,
                                energyBalance: viewModel.energyBalance,
                                gemsBalance: viewModel.gemsBalance
                            )
                        }
                    } label: {
                        Label("Refresh Widget Now", systemImage: "arrow.clockwise")
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
                    if #available(iOS 16.2, *) {
                        Text("Display your pet on your home screen, lock screen, or Dynamic Island. Note: Dynamic Island requires iPhone 14 Pro or later.")
                    } else {
                        Text("Display your pet on your home screen and lock screen.")
                    }
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
            .alert("Dynamic Island", isPresented: $showingLiveActivityAlert) {
                Button("OK") { }
            } message: {
                Text(liveActivityMessage)
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

