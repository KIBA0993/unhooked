//
//  ScreenTimeReportView.swift
//  Unhooked
//
//  Hidden DeviceActivityReport that triggers usage tracking
//

import SwiftUI
import DeviceActivity
import FamilyControls

struct ScreenTimeReportView: View {
    let appSelection: FamilyActivitySelection
    
    // Use today's date as ID to force refresh when day changes
    @State private var refreshID = UUID()
    @State private var lastRefreshDate = Date()
    @State private var refreshTimer: Timer?
    
    var body: some View {
        // Hidden report that triggers the extension
        // The extension queries actual Screen Time data and saves to App Group
        Color.clear
            .frame(width: 1, height: 1)
            .opacity(0)
            .background(
                // This triggers the DeviceActivityReport extension
                Group {
                    if #available(iOS 16.0, *) {
                        reportView
                            .id(refreshID) // Force recreate when ID changes
                    }
                }
            )
            .onAppear {
                checkForDayChange()
                startPeriodicRefresh()
            }
            .onDisappear {
                stopPeriodicRefresh()
            }
            .onChange(of: appSelection) { _, _ in
                // Force refresh when app selection changes
                refreshReport()
            }
    }
    
    @ViewBuilder
    private var reportView: some View {
        if #available(iOS 16.0, *) {
            // Use the context name defined in the extension
            let context = DeviceActivityReport.Context("Total Activity")
            
            // Create filter with today's date range
            let calendar = Calendar.current
            let now = Date()
            let startOfDay = calendar.startOfDay(for: now)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            
            DeviceActivityReport(context, filter: DeviceActivityFilter(
                segment: .daily(during: DateInterval(start: startOfDay, end: endOfDay)),
                users: .all,
                devices: .init([.iPhone, .iPad]),
                applications: appSelection.applicationTokens,  // CRITICAL: Filter by selected apps
                webDomains: appSelection.webDomainTokens
            ))
            .frame(width: 1, height: 1)  // Minimal non-zero size to ensure rendering
            .hidden()  // Hide visually but keep in view hierarchy
            .onAppear {
                print("📊 DeviceActivityReport view appeared")
                print("   Date range: \(startOfDay) to \(endOfDay)")
                print("   Today: \(calendar.component(.day, from: now))")
                print("   Apps in selection: \(appSelection.applicationTokens.count)")
                print("   📱 Filtering for specific apps: \(appSelection.applicationTokens.count)")
            }
        }
    }
    
    private func checkForDayChange() {
        let calendar = Calendar.current
        if !calendar.isDate(lastRefreshDate, inSameDayAs: Date()) {
            print("📅 Day changed - refreshing DeviceActivityReport")
            refreshReport()
        }
    }
    
    private func refreshReport() {
        refreshID = UUID()
        lastRefreshDate = Date()
        print("🔄 DeviceActivityReport refreshed with new ID")
    }
    
    private func startPeriodicRefresh() {
        // Refresh every 2 minutes to capture usage updates
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 120, repeats: true) { _ in
            print("⏰ Periodic refresh triggered")
            checkForDayChange()
            refreshReport()
        }
        print("✅ Started periodic DeviceActivityReport refresh (every 2 min)")
    }
    
    private func stopPeriodicRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        print("🛑 Stopped periodic refresh")
    }
}


