# Widget & Dynamic Island Setup Guide

This guide explains how to set up Home Screen Widgets, Lock Screen Widgets, and Live Activity (Dynamic Island) for Unhooked.

## Overview

Unhooked now supports three types of pet displays:

1. **Home Screen Widgets** - Small, Medium, and Large sizes
2. **Lock Screen Widgets** - Circular and Rectangular
3. **Live Activity** - Dynamic Island (iPhone 14 Pro and later)

## Important Note

⚠️ **The widget files are currently in the main app target and need to be moved to a Widget Extension target to function.**

The widget code is prepared and ready, but requires these setup steps in Xcode to activate.

## Setup Steps

### 1. Create Widget Extension Target

**In Xcode:**

1. **File → New → Target**
2. Select **Widget Extension**
3. Name it: `UnhookedWidgets`
4. **Include Configuration Intent**: No (uncheck)
5. Click **Activate** when prompted
6. **Delete** the default `UnhookedWidgets.swift` and `UnhookedWidgetsBundle.swift` files that Xcode creates

### 2. Configure App Group

Widgets run in a separate process and need shared data access via App Groups.

**Enable App Groups:**

1. Select **Unhooked** target
2. Go to **Signing & Capabilities**
3. Click **+ Capability**
4. Add **App Groups**
5. Click **+** and create: `group.com.unhooked.shared`

6. Select **UnhookedWidgets** target
7. Repeat steps 2-5 with the same group ID

### 3. Move Widget Files to Widget Target

**In Xcode Project Navigator:**

1. **Move** these files to the Widget Extension target:
   - `Unhooked/Widgets/PetWidget.swift` → Set target to **UnhookedWidgets**
   - `Unhooked/Widgets/PetLiveActivity.swift` → Set target to **UnhookedWidgets**

2. **Add** these model files to BOTH targets (keep in main app AND add to widget):
   - `Unhooked/Models/Pet.swift` - Check **UnhookedWidgets** target membership
   - `Unhooked/Models/Ledger.swift` - Check **UnhookedWidgets** target membership

3. In `PetWidget.swift`, **uncomment** the `@main` attribute:
   ```swift
   @main  // Uncomment this line
   struct UnhookedWidgets: WidgetBundle {
       var body: some Widget {
           PetWidget()
       }
   }
   ```

**Important:** The widget files must be in the Widget Extension target to work. They won't function in the main app target.

### 4. Configure Live Activity (Dynamic Island)

**Add Capabilities:**

1. Select **Unhooked** target
2. **Signing & Capabilities**
3. Add **Push Notifications** capability
4. In **Info.plist**, add:
   ```xml
   <key>NSSupportsLiveActivities</key>
   <true/>
   <key>NSSupportsLiveActivitiesFrequentUpdates</key>
   <true/>
   ```

### 5. Import Required Frameworks

Ensure these imports are in your widget files:

```swift
import WidgetKit
import SwiftUI
import ActivityKit  // For Live Activity
```

### 6. Test Widgets

**Home Screen Widget:**
1. Long press home screen
2. Tap **+** in top corner
3. Search for **Unhooked**
4. Choose size (Small, Medium, Large)
5. Tap **Add Widget**

**Lock Screen Widget:**
1. Long press lock screen
2. Tap **Customize**
3. Choose **Lock Screen**
4. Tap widget area
5. Select **Unhooked**
6. Choose widget style
7. Tap **Done**

**Live Activity / Dynamic Island:**
- Automatically starts when app is active
- Shows pet status in Dynamic Island (iPhone 14 Pro+)
- Enable in **Settings → Widget & Live Activity**

## Widget Features

### Small Widget
- Pet emoji with current species
- Stage number
- Health indicator (if sick/dead)

### Medium Widget
- Pet display with emoji
- Health status
- Fullness percentage
- Energy balance

### Large Widget
- Full pet details
- All stats (health, fullness, mood)
- Energy and Gems balances
- Detailed health status

### Lock Screen Widgets

**Circular:**
- Pet emoji
- Health color indicator (green/orange/gray)

**Rectangular:**
- Pet emoji and stage
- Fullness and Energy stats

### Dynamic Island

**Minimal:**
- Pet emoji only

**Compact:**
- Pet emoji (leading)
- Energy balance (trailing)

**Expanded:**
- Large pet display
- All stats (fullness, energy, health)
- Health status badge
- Stage information

## Update Frequency

- **Widgets**: Refresh every 15 minutes
- **Live Activity**: Updates immediately when app data changes
- **Manual Refresh**: Triggered when feeding pet or making purchases

## Troubleshooting

### Widget Not Updating

1. Check App Group is configured correctly in both targets
2. Ensure `group.com.unhooked.shared` matches exactly
3. Verify widget files have correct target membership
4. Remove and re-add widget to home screen

### Dynamic Island Not Showing

1. Requires iPhone 14 Pro or later
2. Check Live Activities are enabled: **Settings → Unhooked → Live Activities**
3. Ensure capability is added to main app target
4. Restart app

### Data Not Syncing

1. Verify App Group entitlement is active
2. Check provisioning profiles include App Group
3. Clean build folder (**⌘⇧K**) and rebuild

## Privacy & Battery

- Widgets use minimal battery (passive display)
- Live Activities use slightly more power (active updates)
- No location or personal data is displayed
- Only pet stats and game data shown

## Customization

Users can customize widget appearance in **Settings**:

- **Show Detailed Stats**: Toggle extra information
- **Enable Live Activity**: Control Dynamic Island display
- **Widget Refresh Rate**: Adjust update frequency

---

**Note**: Dynamic Island is only available on iPhone 14 Pro, iPhone 14 Pro Max, iPhone 15 Pro, iPhone 15 Pro Max, and later models.

