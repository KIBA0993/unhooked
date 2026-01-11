//
//  DeviceActivityMonitor.swift
//  UnhookedDeviceActivity
//
//  DeviceActivity Extension for tracking Screen Time usage
//  THIS FILE SHOULD BE ADDED TO THE DEVICEACTIVITY EXTENSION TARGET
//

import Foundation
import DeviceActivity
import FamilyControls

class UnhookedDeviceActivityMonitor: DeviceActivityMonitor {
    let usageManager = ScreenTimeUsageManager.shared
    
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        
        print("📱 DeviceActivity interval started: \(activity)")
        
        // Reset usage for new day
        let newUsage = ScreenTimeUsageData(date: Date(), totalMinutes: 0)
        usageManager.saveUsage(newUsage)
    }
    
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        
        print("📱 DeviceActivity interval ended: \(activity)")
    }
    
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        
        print("📱 DeviceActivity threshold reached: \(event)")
    }
    
    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)
        
        print("⚠️ DeviceActivity warning: \(activity)")
    }
    
    override func intervalWillEndWarning(for activity: DeviceActivityName) {
        super.intervalWillEndWarning(for: activity)
        
        print("⚠️ DeviceActivity ending soon: \(activity)")
    }
    
    // MARK: - App Usage Tracking
    
    /// Update usage statistics
    /// This should be called periodically or when significant app usage occurs
    func updateAppUsage(minutes: Int) {
        var usage = usageManager.loadUsage() ?? ScreenTimeUsageData()
        
        // Update total minutes
        usage.totalMinutes = minutes
        usage.date = Date()
        
        usageManager.saveUsage(usage)
        
        print("📊 Updated app usage: \(minutes) minutes")
    }
}

// Note: For the extension to work properly, you need to:
// 1. Create a DeviceActivity Extension target in Xcode
// 2. Add this file to that target
// 3. Export the monitor class in Info.plist:
//    NSExtension -> NSExtensionPrincipalClass = "$(PRODUCT_MODULE_NAME).UnhookedDeviceActivityMonitor"
// 4. Add the ScreenTimeUsage.swift file to both main app and extension targets
// 5. Enable Family Controls and DeviceActivity capabilities



