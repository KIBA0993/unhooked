//
//  DebugUsageView.swift
//  Unhooked
//
//  Debug view to diagnose Screen Time tracking issues
//

import SwiftUI
import SwiftData
import FamilyControls
import DeviceActivity

struct DebugUsageView: View {
    @Environment(AppViewModel.self) private var viewModel
    @Environment(\.modelContext) private var modelContext
    @State private var debugInfo: [String] = []
    @State private var appLimitConfig: AppLimitConfig?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Screen Time Debug Info")
                        .font(.headline)
                    
                    ForEach(Array(debugInfo.enumerated()), id: \.offset) { _, info in
                        Text(info)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(info.contains("❌") ? .red : info.contains("✅") ? .green : .primary)
                            .padding(.vertical, 2)
                    }
                    
                    Button("Run Full Diagnostic") {
                        runDiagnostic()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding()
            }
            .navigationTitle("Debug")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            runDiagnostic()
        }
    }
    
    private func runDiagnostic() {
        debugInfo.removeAll()
        debugInfo.append("🔍 Starting diagnostic...")
        debugInfo.append("━━━━━━━━━━━━━━━━━━━━━━")
        
        // 1. Check App Group
        debugInfo.append("\n📦 App Group Check:")
        let appGroupID = "group.com.kookytrove.unhooked"
        if let defaults = UserDefaults(suiteName: appGroupID) {
            debugInfo.append("✅ App Group accessible: \(appGroupID)")
            
            // Check if any data exists
            if let data = defaults.data(forKey: "screentime.usage.data") {
                debugInfo.append("✅ Usage data found in App Group (\(data.count) bytes)")
                
                if let decoded = try? JSONDecoder().decode(ScreenTimeUsageData.self, from: data) {
                    debugInfo.append("✅ Data decoded successfully")
                    debugInfo.append("   Total minutes: \(decoded.totalMinutes)")
                    debugInfo.append("   Date: \(decoded.dateString)")
                    debugInfo.append("   Last Updated: \(decoded.lastUpdated)")
                    debugInfo.append("   Is today: \(decoded.isToday)")
                } else {
                    debugInfo.append("❌ Failed to decode usage data")
                }
            } else {
                debugInfo.append("⚠️ No usage data in App Group yet")
            }
        } else {
            debugInfo.append("❌ Cannot access App Group: \(appGroupID)")
        }
        
        // 2. Check App Limit Config
        debugInfo.append("\n⚙️ App Limit Config:")
        let userId = viewModel.userId
        let descriptor = FetchDescriptor<AppLimitConfig>(
            predicate: #Predicate<AppLimitConfig> { config in
                config.userId == userId
            }
        )
        
        do {
            if let config = try modelContext.fetch(descriptor).first {
                appLimitConfig = config
                debugInfo.append("✅ Config found")
                debugInfo.append("   Limit: \(config.limitMinutes) minutes")
                debugInfo.append("   Last changed: \(config.lastChangedAt)")
                debugInfo.append("   Can change: \(config.canChangeLimit)")
                
                if let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: config.selectedApps) {
                    debugInfo.append("✅ App selection decoded")
                    debugInfo.append("   Apps: \(selection.applicationTokens.count)")
                    debugInfo.append("   Categories: \(selection.categoryTokens.count)")
                } else {
                    debugInfo.append("❌ Failed to decode app selection")
                }
            } else {
                debugInfo.append("❌ No config found for user")
            }
        } catch {
            debugInfo.append("❌ Error fetching config: \(error)")
        }
        
        // 3. Check Pet Usage
        debugInfo.append("\n🐾 Pet Status:")
        if let pet = viewModel.currentPet {
            debugInfo.append("✅ Pet found")
            debugInfo.append("   Current usage: \(pet.currentUsage) minutes")
            debugInfo.append("   Current limit: \(pet.currentLimit) minutes")
        } else {
            debugInfo.append("❌ No pet found")
        }
        
        // 4. Screen Time Authorization
        debugInfo.append("\n🔒 Screen Time Authorization:")
        #if !targetEnvironment(simulator)
        let authCenter = AuthorizationCenter.shared
        let status = authCenter.authorizationStatus
        switch status {
        case .notDetermined:
            debugInfo.append("⚠️ Not determined")
        case .denied:
            debugInfo.append("❌ Denied")
        case .approved:
            debugInfo.append("✅ Approved")
        @unknown default:
            debugInfo.append("❓ Unknown status")
        }
        #else
        debugInfo.append("⚠️ Simulator - cannot check")
        #endif
        
        debugInfo.append("\n━━━━━━━━━━━━━━━━━━━━━━")
        debugInfo.append("Diagnostic complete!")
    }
}

#Preview {
    DebugUsageView()
}


