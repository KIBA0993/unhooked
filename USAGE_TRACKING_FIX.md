# Usage Tracking Not Working - Diagnostic & Fix

## Current Issue
The DeviceActivityReport extension is **NOT being triggered**, which means:
- ✅ App Group is accessible
- ✅ Screen Time is authorized
- ✅ App selection exists (1 app)
- ❌ **Extension never runs** (`makeConfiguration()` not called)
- ❌ No usage data saved to App Group

## Root Cause
iOS DeviceActivityReport extensions are **very finicky** and have several requirements that must ALL be met:

### 1. Extension Must Be Properly Built
- The `UnhookedActivityReport` target must be built and installed
- Check: In Xcode, select `UnhookedActivityReport` scheme and build it

### 2. Extension Must Have Correct Entitlements
**Check in Xcode:**
1. Select `UnhookedActivityReport` target
2. Signing & Capabilities tab
3. Must have:
   - ✅ App Groups: `group.com.kookytrove.unhooked`
   - ✅ Family Controls capability

### 3. Extension Must Be in Info.plist
The extension must be declared in the main app's Info.plist under `NSExtension`.

### 4. Real Device vs Simulator
**DeviceActivityReport extensions DO NOT WORK RELIABLY in the simulator!**
- They require actual Screen Time data
- Simulator doesn't track real usage
- **You MUST test on a real iPhone**

## Quick Fix: Test on Real Device

### Step 1: Connect Your iPhone
1. Plug iPhone into your Mac via USB
2. Trust the computer on your iPhone

### Step 2: Select Real Device in Xcode
1. In Xcode, at the top: `UnhookedActivityReport > [Your iPhone Name]`
2. Build and run on your iPhone (not simulator)

### Step 3: Grant Permissions on Real Device
1. Open the app on your iPhone
2. Grant Screen Time permission
3. Select an app to track
4. **Actually use that app for 5+ minutes**
5. Come back to Unhooked
6. Tap "Test Usage Refresh" in debug panel

### Step 4: Check for Usage Data
After using the selected app and refreshing, you should see usage update.

---

## Alternative: Manual Usage Tracking (Fallback)

If DeviceActivityReport continues not to work, we can implement manual usage tracking:

### Option A: DeviceActivityMonitor (Events-based)
- Triggers when app limit is reached
- Less accurate but more reliable
- Works in simulator

### Option B: Manual Check-In
- User manually inputs their usage
- Most reliable (already implemented in your app via Daily Check-In)
- Users can see usage in Settings → Screen Time

---

## Most Likely Solution

**You're testing in the iOS Simulator**, which doesn't support DeviceActivityReport properly.

**ACTION REQUIRED:**
1. **Build and run on a REAL iPhone**
2. **Use the selected app for 5+ minutes**
3. **Open Unhooked and check debug panel**
4. You should then see usage data appear

If you don't have a real device available, let me know and I'll implement the fallback manual tracking system.


