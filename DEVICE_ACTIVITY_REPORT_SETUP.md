# DeviceActivityReport Extension Setup Guide

This guide shows you how to add the **DeviceActivityReport** extension for automatic, real-time Screen Time usage tracking.

## Why DeviceActivityReport?

Unlike the Monitor extension which only triggers at specific events, the **Report extension** can query actual usage data in real-time and display it in your app.

## Prerequisites

✅ You should have already created the `UnhookedDeviceActivity` (Monitor) extension
✅ Main app has Family Controls capability
✅ App Group `group.com.kookytrove.unhooked` is configured

## Step-by-Step Setup

### 1. Create DeviceActivityReport Extension Target

**Important:** This is a DIFFERENT extension from the Monitor extension!

1. **In Xcode: File → New → Target**
2. **Search for and select: "DeviceActivity Report Extension"**
   - NOT "Monitor" - we need the **Report** extension
3. **Configure:**
   - Product Name: `UnhookedActivityReport`
   - Team: Your team
   - Bundle ID: `com.kookytrove.unhooked.activityreport`
4. **Click Finish**
5. **Click Activate** when prompted

### 2. Configure Report Extension Target

1. **Select `UnhookedActivityReport` target** in project settings
2. **Signing & Capabilities:**
   - ✅ Automatically manage signing
   - Add **App Groups**: `group.com.kookytrove.unhooked`
   - Add **Family Controls**
3. **General tab:**
   - iOS Deployment Target: 16.0+

### 3. Add Required Files to Report Extension

The report extension needs access to shared files:

#### Add These Files to BOTH Main App AND Report Extension:

1. **`ScreenTimeUsage.swift`:**
   - Click on file
   - File Inspector (right sidebar)
   - Target Membership:
     - ✅ Unhooked
     - ✅ UnhookedActivityReport

2. **`ActivityReportContext.swift`:**
   - Same process - add to BOTH targets:
     - ✅ Unhooked
     - ✅ UnhookedActivityReport

#### Add This File to Report Extension ONLY:

3. **`TotalActivityReport.swift`:**
   - Click on file
   - File Inspector
   - Target Membership:
     - ⬜ Unhooked (unchecked)
     - ✅ UnhookedActivityReport (checked)

### 4. Update Extension's Main File

1. **Find the auto-generated file:** `TotalActivityReportExtension.swift` (or similar)
2. **Replace its contents with:**

```swift
import DeviceActivity
import SwiftUI

@main
struct UnhookedActivityReportExtension: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        TotalActivityReport { report in
            TotalActivityView(report: report)
        }
    }
}
```

### 5. Add DeviceActivityReport to Main App

Now we need to display the report in the main app.

**Create a new SwiftUI view:** `UsageReportView.swift` in main app:

```swift
import SwiftUI
import DeviceActivity

struct UsageReportView: View {
    let selectedApps: FamilyActivitySelection
    
    var body: some View {
        DeviceActivityReport(
            .totalActivity,
            filter: selectedApps
        )
        .frame(height: 80)
    }
}
```

### 6. Update HomeView to Show Report

In your `HomeView.swift`, replace the static usage display with the live report (if you have the app selection data).

### 7. Build and Test

1. **Build Report Extension:**
   - Select `UnhookedActivityReport` scheme
   - Press ⌘ + B

2. **Build Main App:**
   - Select `Unhooked` scheme
   - Press ⌘ + Shift + K (clean)
   - Press ⌘ + R (run)

3. **Test on Device:**
   - Use the tracked app for a few minutes
   - The usage should automatically update in your app
   - Check console for "📊 DeviceActivityReport" logs

## How It Works

```
User opens Unhooked app
         ↓
App displays DeviceActivityReport view
         ↓
System renders report extension
         ↓
Report queries real Screen Time data
         ↓
Report saves to App Group
         ↓
Main app reads updated usage
         ↓
UI shows current usage automatically
```

## Troubleshooting

### Report Not Updating

- Verify both extensions are installed (Monitor + Report)
- Check App Group ID matches in all targets
- Ensure ScreenTimeUsage.swift is in all targets
- Look for console logs starting with "📊"

### Build Errors

- Make sure ActivityReportContext.swift is in correct targets
- Verify TotalActivityReport.swift is ONLY in report extension
- Check iOS deployment target is 16.0+

### No Usage Data

- Use the tracked app for at least 1 minute
- DeviceActivity may have a delay (up to 5 minutes)
- Check iOS Settings → Screen Time is enabled
- Verify Family Controls is authorized

## What's Different from Monitor Extension?

| Monitor Extension | Report Extension |
|-------------------|------------------|
| Triggers at events | Queries data on-demand |
| Background only | Renders in your UI |
| Event-based | Real-time data |
| One per app | Can have multiple |

## Summary

You should now have:
- ✅ UnhookedDeviceActivity (Monitor) - triggers events
- ✅ UnhookedActivityReport (Report) - provides usage data
- ✅ Both share data via App Group
- ✅ Main app displays live usage

This is the proper Apple-recommended way to get Screen Time data! 🎉



