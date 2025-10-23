# iCloud Sync Setup Instructions

Your app is now configured for iCloud sync! Follow these steps to complete the setup in Xcode.

## ✅ What's Been Done

- ✅ SwiftData configured to use CloudKit when available
- ✅ Automatic fallback to local-only storage if iCloud unavailable
- ✅ Persistent user ID that syncs across devices
- ✅ Cloud sync status monitoring service
- ✅ Settings UI to show sync status

## 🔧 Xcode Configuration Required

### Step 1: Enable iCloud Capability

1. Open `Unhooked.xcodeproj` in Xcode
2. Select your **Unhooked** target
3. Go to **Signing & Capabilities** tab
4. Click **+ Capability** button
5. Add **iCloud**
6. In the iCloud section, check:
   - ☑️ **CloudKit**
   - ☑️ **Key-value storage** (for syncing user ID)
7. Under "Containers", click the **+** button and add:
   - `iCloud.com.unhooked.app`
   
   *(Note: The container identifier must match what's in `UnhookedApp.swift` line 53)*

### Step 2: Configure App Identifier

If you haven't already:

1. Go to [Apple Developer Portal](https://developer.apple.com)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Select your app identifier
4. Enable **iCloud** capability
5. Configure CloudKit containers

### Step 3: Test iCloud Sync

#### On Simulator:
1. Open **Settings** app on simulator
2. Sign in with an Apple ID (Settings → Sign in to iPhone)
3. Run your app
4. Check Settings → Cloud Sync section
   - Should show "iCloud Sync ✓"

#### On Real Device:
1. Ensure you're signed into iCloud (Settings → [Your Name])
2. Install app on multiple devices with same Apple ID
3. Make changes on one device
4. Wait a few seconds for sync
5. Changes should appear on other device

## 📱 How It Works

### For Users WITH iCloud:
- Data automatically syncs across all devices
- Pet progress, Energy, Gems, purchases all sync
- No additional setup needed from user
- Works seamlessly in background

### For Users WITHOUT iCloud:
- App works perfectly with local storage only
- Settings shows "Sign in to iCloud in Settings to sync..."
- All features work, just no cross-device sync

## 🔍 Verifying Sync

### In Console Logs:
When app launches, look for:
```
☁️ iCloud sync enabled
```
Or if iCloud unavailable:
```
📱 Local storage only (iCloud not available)
```

### In Settings View:
- **iCloud Sync ✓** = Sync enabled and working
- **Not Available** = User not signed into iCloud

## 🎯 User Experience

### First Launch (Device A):
1. User creates pet
2. Pet data saved to local database
3. If iCloud available, data syncs to cloud

### First Launch (Device B):
1. User opens app on second device
2. App detects same userId via iCloud
3. Pet data automatically downloads
4. User sees their existing pet!

### Offline Mode:
- App works perfectly offline
- Changes saved locally
- Sync happens automatically when back online

## 🐛 Troubleshooting

### "Could not create ModelContainer" Error:
- Check that CloudKit capability is properly added
- Verify container identifier matches in both Xcode and code
- Try cleaning build folder (Cmd + Shift + K)

### Sync Not Working:
- Verify user is signed into iCloud
- Check console for "☁️ iCloud sync enabled" message
- Try refresh button in Settings → Cloud Sync

### Testing Without iCloud:
- Sign out of iCloud on simulator
- App should show "Local storage only" in console
- All features should still work

## 📝 Notes

- **Container ID**: `iCloud.com.unhooked.app` (change if needed for your app)
- **User ID**: Stored in UserDefaults, persists across app launches
- **Data Size**: Typical usage ~1MB per user (well within free iCloud tier)
- **Privacy**: Data stays in user's private iCloud, never leaves Apple's servers

## 🚀 Ready to Test!

Once you've completed the Xcode configuration above, you're all set! The app will:
- Automatically detect iCloud availability
- Enable sync if available
- Fall back to local storage if not
- Show appropriate status in Settings

No additional code changes needed!

