# Widget Files - Setup Required

⚠️ **These widget files are prepared but not yet active.**

## Current Status

These files are currently in the **main app target** but need to be in a **Widget Extension target** to function.

## Files in This Directory

1. **PetWidget.swift** - Home and lock screen widgets
2. **PetLiveActivity.swift** - Dynamic Island Live Activity

## Why Widgets Aren't Working Yet

Widgets must run in a separate process (Widget Extension) from the main app. Until you create the Widget Extension target in Xcode and move these files there, the widgets won't appear in the widget gallery.

## Quick Setup

Follow these steps in Xcode:

### 1. Create Widget Extension
- File → New → Target
- Select "Widget Extension"
- Name: `UnhookedWidgets`

### 2. Move These Files
- Select both `.swift` files in this folder
- In File Inspector → Target Membership
- **Uncheck** `Unhooked` (main app)
- **Check** `UnhookedWidgets` (widget extension)

### 3. Share Required Models
Add to BOTH targets:
- `Models/Pet.swift`
- `Models/Ledger.swift`

### 4. Uncomment @main
In `PetWidget.swift`, find and uncomment:
```swift
// @main  ← Remove the //
struct UnhookedWidgets: WidgetBundle {
    var body: some Widget {
        PetWidget()
    }
}
```

### 5. Configure App Group
- Both targets need the same App Group: `group.com.unhooked.shared`
- Main app: Signing & Capabilities → App Groups
- Widget: Signing & Capabilities → App Groups

## After Setup

Once configured, users can:
- Long press home screen → Add Widget → Unhooked
- Customize lock screen → Add Unhooked widgets
- See Live Activity in Dynamic Island (iPhone 14 Pro+)

## Full Documentation

See `WIDGET_SETUP.md` in the project root for complete instructions.

