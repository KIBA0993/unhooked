# DeviceActivity Extension Setup Guide

This guide will help you create and configure the DeviceActivity Extension target needed for automatic Screen Time tracking.

## Why Do We Need This?

The Screen Time API doesn't allow the main app to directly track usage. Instead, we need a separate **DeviceActivity Extension** that runs in the background and reports usage data to the main app via the App Group.

## Step-by-Step Setup

### 1. Create DeviceActivity Extension Target

1. **In Xcode, select File → New → Target**
2. **Choose "Device Activity Monitor Extension"** (under iOS)
   - If you don't see this, search for "Device Activity"
3. **Configure the extension:**
   - Product Name: `UnhookedDeviceActivity`
   - Team: Select your development team
   - Bundle Identifier: `com.kookytrove.unhooked.deviceactivity`
   - Click **Finish**
4. **When prompted "Activate scheme?"** → Click **Activate**

### 2. Configure Extension Target

1. **Select the `UnhookedDeviceActivity` target** in project settings
2. **Go to Signing & Capabilities:**
   - Ensure "Automatically manage signing" is checked
   - Team: Select your team
   - Click **"+ Capability"** and add:
     - **App Groups** → Enable `group.com.kookytrove.unhooked`
     - **Family Controls** → Enable

3. **Set iOS Deployment Target:**
   - General tab → Deployment Info
   - Set to iOS 16.0 or later

### 3. Add Required Files to Extension

The extension needs access to the shared usage data structure.

1. **In Xcode's Project Navigator:**
   - Find `Unhooked/Models/ScreenTimeUsage.swift`
   - Click on the file
   - In the right sidebar (File Inspector), under **Target Membership:**
     - ✅ Check BOTH:
       - `Unhooked` (main app)
       - `UnhookedDeviceActivity` (extension)

2. **Replace the auto-generated monitor file:**
   - Delete the auto-generated `DeviceActivityMonitorExtension.swift`
   - Add the `DeviceActivityMonitor.swift` file I created to the extension target
   - In File Inspector, ensure it's only in `UnhookedDeviceActivity` target

### 4. Configure Extension Info.plist

1. **Open `UnhookedDeviceActivity/Info.plist`**
2. **Find or add** `NSExtension` dictionary:
   ```xml
   <key>NSExtension</key>
   <dict>
       <key>NSExtensionPointIdentifier</key>
       <string>com.apple.deviceactivity.monitor-extension</string>
       <key>NSExtensionPrincipalClass</key>
       <string>$(PRODUCT_MODULE_NAME).UnhookedDeviceActivityMonitor</string>
   </dict>
   ```

### 5. Update Extension Entitlements

1. **Create or edit `UnhookedDeviceActivity.entitlements`:**
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
       <key>com.apple.security.application-groups</key>
       <array>
           <string>group.com.kookytrove.unhooked</string>
       </array>
       <key>com.apple.developer.family-controls</key>
       <true/>
   </dict>
   </plist>
   ```

### 6. Build and Test

1. **Clean Build Folder:** `⌘ + Shift + K`
2. **Build Main App:** Select "Unhooked" scheme and build
3. **Build Extension:** Select "UnhookedDeviceActivity" scheme and build
4. **Run on Device:** Connect your iPhone and run the main Unhooked app

## How It Works

```
User selects app in Settings
         ↓
Main app starts monitoring via ScreenTimeService
         ↓
DeviceActivity Extension runs in background
         ↓
Extension updates usage data in App Group
         ↓
Main app reads usage every 5 minutes
         ↓
Usage displayed in home screen bar
```

## Troubleshooting

### Extension Not Running
- Check that Family Controls is authorized in Settings → Unhooked
- Verify App Group is properly configured in both targets
- Check console logs for DeviceActivity messages

### Usage Not Updating
- Make sure ScreenTimeUsage.swift is in BOTH targets
- Verify App Group ID matches: `group.com.kookytrove.unhooked`
- Check that monitoring started successfully (look for console logs)

### Build Errors
- Ensure iOS deployment target is 16.0+ for extension
- Verify all required capabilities are added
- Clean build folder and rebuild

## What's Already Done

✅ Main app code updated to start monitoring
✅ ScreenTimeUsageManager created for shared data
✅ Periodic usage sync (every 5 minutes)
✅ UI updated to show current usage
✅ App Group configured

## What You Need to Do

1. Create the DeviceActivity Extension target (Steps 1-2 above)
2. Add ScreenTimeUsage.swift to extension target (Step 3)
3. Add DeviceActivityMonitor.swift to extension (Step 3)
4. Configure Info.plist and entitlements (Steps 4-5)
5. Build and test!

Once the extension is created and running, your app will automatically track usage of the selected app in real-time!



