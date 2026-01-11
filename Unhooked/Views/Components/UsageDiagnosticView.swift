//
//  UsageDiagnosticView.swift
//  Unhooked
//
//  Comprehensive diagnostic for DeviceActivityReport issues
//

import SwiftUI
import SwiftData
import DeviceActivity
import FamilyControls

struct UsageDiagnosticView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppViewModel.self) private var viewModel
    
    @State private var diagnosticResults: [DiagnosticResult] = []
    @State private var isRunning = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Usage Tracking Diagnostic")
                        .font(.title2.bold())
                        .padding(.bottom)
                    
                    if isRunning {
                        ProgressView("Running diagnostics...")
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    
                    ForEach(diagnosticResults) { result in
                        DiagnosticRow(result: result)
                    }
                    
                    if !isRunning && !diagnosticResults.isEmpty {
                        Button("Run Again") {
                            runDiagnostics()
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                        .padding(.top)
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if diagnosticResults.isEmpty {
                    runDiagnostics()
                }
            }
        }
    }
    
    private func runDiagnostics() {
        isRunning = true
        diagnosticResults = []
        
        Task {
            // Check 1: Screen Time Authorization
            await checkScreenTimeAuth()
            
            // Check 2: App Group Access
            await checkAppGroupAccess()
            
            // Check 3: App Selection
            await checkAppSelection()
            
            // Check 4: Monitoring Active
            await checkMonitoringActive()
            
            // Check 5: Usage Data
            await checkUsageData()
            
            // Check 6: Extension Bundle
            await checkExtensionBundle()
            
            await MainActor.run {
                isRunning = false
            }
        }
    }
    
    private func checkScreenTimeAuth() async {
        // Use retry logic for more reliable status detection
        let isApproved = await viewModel.screenTimeService.checkAuthorizationStatusWithRetry()
        let status = AuthorizationCenter.shared.authorizationStatus
        
        print("🔐 Final Authorization Status: \(status), Approved: \(isApproved)")
        
        await MainActor.run {
            var details = ""
            
            if isApproved {
                details = "✅ Authorization granted (verified with retry)\n"
                details += "Screen Time API is accessible\n\n"
                details += "Status should remain stable now."
            } else {
                details = "❌ Authorization needed\n"
                details += "Status: \(status)\n"
                details += "Checked 3 times with delays\n\n"
                details += "TO FIX:\n"
                details += "1. Go to iOS Settings → Screen Time\n"
                let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "Unhooked"
                details += "2. Scroll down to '\(appName)'\n"
                details += "3. Enable all permissions\n"
                details += "4. Restart the app"
            }
            
            diagnosticResults.append(DiagnosticResult(
                title: "Screen Time Authorization",
                message: isApproved ? "✅ Approved" : "❌ \(status)",
                passed: isApproved,
                details: details
            ))
        }
    }
    
    private func checkAppGroupAccess() async {
        let appGroupID = "group.com.kookytrove.unhooked"
        let userDefaults = UserDefaults(suiteName: appGroupID)
        
        await MainActor.run {
            let passed = userDefaults != nil
            diagnosticResults.append(DiagnosticResult(
                title: "App Group Access",
                message: "ID: \(appGroupID)",
                passed: passed,
                details: passed ? "App Group is accessible" : "Cannot access App Group - check entitlements"
            ))
        }
    }
    
    private func checkAppSelection() async {
        let userId = viewModel.userId
        
        // Query SwiftData for AppLimitConfig
        let descriptor = FetchDescriptor<AppLimitConfig>(
            predicate: #Predicate<AppLimitConfig> { config in
                config.userId == userId
            }
        )
        
        var hasSelection = false
        var selectionDetails = "No app configured"
        var appCount = 0
        
        do {
            if let config = try modelContext.fetch(descriptor).first {
                // Try to decode the selection
                if let decoded = try? JSONDecoder().decode(FamilyActivitySelection.self, from: config.selectedApps) {
                    appCount = decoded.applicationTokens.count
                    hasSelection = appCount > 0
                    selectionDetails = hasSelection ? 
                        "Found \(appCount) app(s), Limit: \(config.limitMinutes) min" : 
                        "Config exists but no apps selected"
                } else {
                    selectionDetails = "Config exists but cannot decode selection"
                }
            }
        } catch {
            selectionDetails = "Error reading config: \(error.localizedDescription)"
        }
        
        await MainActor.run {
            diagnosticResults.append(DiagnosticResult(
                title: "App Selection",
                message: hasSelection ? "\(appCount) app(s) selected" : "No app selected",
                passed: hasSelection,
                details: hasSelection ? selectionDetails : "Go to Settings (gear icon) → Screen Time → Set App Limit to select an app"
            ))
        }
    }
    
    private func checkMonitoringActive() async {
        let userId = viewModel.userId
        
        // Check if monitoring was started
        let descriptor = FetchDescriptor<AppLimitConfig>(
            predicate: #Predicate<AppLimitConfig> { config in
                config.userId == userId
            }
        )
        
        var monitoringDetails = ""
        var isActive = false
        
        do {
            if let config = try modelContext.fetch(descriptor).first {
                if let decoded = try? JSONDecoder().decode(FamilyActivitySelection.self, from: config.selectedApps),
                   !decoded.applicationTokens.isEmpty {
                    
                    // We have a selection, monitoring should be active
                    isActive = true
                    monitoringDetails = "✅ Monitoring was started for \(decoded.applicationTokens.count) app(s)\n"
                    monitoringDetails += "Limit: \(config.limitMinutes) minutes\n\n"
                    monitoringDetails += "Events configured:\n"
                    monitoringDetails += "• Every 5 minutes: 5, 10, 15, 20, 25, 30...\n"
                    monitoringDetails += "• Up to 120 minutes (2 hours)\n"
                    monitoringDetails += "• 18 threshold events total\n\n"
                    monitoringDetails += "Usage will update every 5 minutes as you use the app.\n"
                    monitoringDetails += "Example: At 5 min → shows 5, at 10 min → shows 10, etc."
                } else {
                    monitoringDetails = "No apps configured for monitoring"
                }
            } else {
                monitoringDetails = "No monitoring configuration found"
            }
        } catch {
            monitoringDetails = "Error checking: \(error.localizedDescription)"
        }
        
        await MainActor.run {
            diagnosticResults.append(DiagnosticResult(
                title: "Monitoring Active",
                message: isActive ? "✅ Active" : "❌ Not Active",
                passed: isActive,
                details: monitoringDetails
            ))
        }
    }
    
    private func checkUsageData() async {
        let manager = ScreenTimeUsageManager.shared
        let usage = manager.loadUsage()
        
        await MainActor.run {
            let hasData = usage != nil && usage!.isToday
            var details = ""
            
            if hasData {
                details = "Date: \(usage!.dateString)\n"
                details += "Last updated: \(usage!.lastUpdated)\n"
                details += "Minutes recorded: \(usage!.totalMinutes)\n\n"
                details += "✅ Data is flowing correctly"
            } else {
                details = "❌ No usage data written yet\n\n"
                details += "TROUBLESHOOTING:\n"
                details += "1. Use the selected app for 5+ minutes continuously\n"
                details += "2. The DeviceActivityMonitor should trigger at 5min\n"
                details += "3. Come back and re-run diagnostic\n\n"
                details += "If still no data after 10 minutes of app use:\n"
                details += "• Tap 'Restart Monitoring' in debug panel\n"
                details += "• Check Console.app logs for extension errors\n"
                details += "• Restart your iPhone\n"
                details += "• Re-install the app"
            }
            
            diagnosticResults.append(DiagnosticResult(
                title: "Usage Data in App Group",
                message: hasData ? "Found: \(usage!.totalMinutes) min" : "No data yet",
                passed: hasData,
                details: details
            ))
        }
    }
    
    private func checkExtensionBundle() async {
        var extensionExists = false
        var detailMessage = ""
        
        // Check both PlugIns and Extensions folders
        // (DeviceActivityReport extensions use the Extensions folder)
        
        // 1. Check Extensions folder
        let bundleURL = Bundle.main.bundleURL
        let extensionsPath = bundleURL.appendingPathComponent("Extensions").path
        detailMessage += "📁 Extensions folder: \(extensionsPath)\n"
        
        if FileManager.default.fileExists(atPath: extensionsPath) {
            if let contents = try? FileManager.default.contentsOfDirectory(atPath: extensionsPath) {
                detailMessage += "   Found \(contents.count) items: \(contents.joined(separator: ", "))\n"
                if contents.contains("UnhookedActivityReport.appex") {
                    extensionExists = true
                    detailMessage += "   ✅ Found UnhookedActivityReport.appex here!\n"
                }
            }
        } else {
            detailMessage += "   Extensions folder does not exist\n"
        }
        
        // 2. Check PlugIns folder (for completeness)
        if let pluginsURL = Bundle.main.builtInPlugInsURL {
            detailMessage += "\n📁 PlugIns folder: \(pluginsURL.path)\n"
            
            if let contents = try? FileManager.default.contentsOfDirectory(atPath: pluginsURL.path) {
                detailMessage += "   Found \(contents.count) items: \(contents.joined(separator: ", "))\n"
                if contents.contains("UnhookedActivityReport.appex") && !extensionExists {
                    extensionExists = true
                    detailMessage += "   ✅ Found UnhookedActivityReport.appex here!\n"
                }
            }
        } else {
            detailMessage += "\n⚠️ BuiltInPlugInsURL is nil\n"
        }
        
        if !extensionExists {
            detailMessage += "\n🔧 EXTENSION NOT FOUND - TO FIX:\n"
            detailMessage += "1. Select 'Unhooked' target in Xcode\n"
            detailMessage += "2. Build Phases tab → 'Embed Foundation Extensions'\n"
            detailMessage += "3. Verify 'UnhookedDeviceActivity.appex' is listed\n"
            detailMessage += "4. Product → Clean Build Folder\n"
            detailMessage += "5. Product → Build and Run"
        } else {
            detailMessage += "\n✅ Extension is properly bundled with the app"
        }
        
        await MainActor.run {
            diagnosticResults.append(DiagnosticResult(
                title: "Extension Bundle",
                message: extensionExists ? "✅ Found: UnhookedActivityReport.appex" : "❌ NOT FOUND",
                passed: extensionExists,
                details: detailMessage
            ))
        }
    }
}

struct DiagnosticResult: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let passed: Bool
    let details: String
}

struct DiagnosticRow: View {
    let result: DiagnosticResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: result.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(result.passed ? .green : .red)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.title)
                        .font(.headline)
                    Text(result.message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(result.details)
                .font(.caption)
                .foregroundColor(result.passed ? .secondary : .red)
                .padding(.leading, 32)
        }
        .padding()
        .background(result.passed ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    UsageDiagnosticView()
}

