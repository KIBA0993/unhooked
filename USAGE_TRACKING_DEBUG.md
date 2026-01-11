# Screen Time Usage Tracking - Debug Guide

## Current Status

The DeviceActivityReport extension is built and working, BUT it's not being triggered because **DeviceActivityReport extensions only run when you display a `DeviceActivityReport` view in your app**.

## The Problem

```
Main App → Needs to display DeviceActivityReport view
              ↓
         System triggers extension
              ↓
         Extension queries Screen Time data
              ↓
         Extension saves to App Group
              ↓
         Main app reads from App Group
```

**We're missing the first step!** The main app isn't displaying a DeviceActivityReport view, so the extension never runs.

## Testing the Data Flow

I've added a **test menu** to verify the data storage/loading works:

1. **Long-press the refresh button** (🔄) in the top bar
2. **Select "Test: Add 5 min"** - This manually adds 5 minutes
3. **Watch the console** for these logs:
   ```
   🧪 Test: Added 5 minutes (now 5)
   💾 saveUsage() called with 5 minutes
   ✅ Saved usage data: 5 minutes to key 'screentime.usage.data' in app group
   🔄 updateUsageFromScreenTime() called
   📱 Attempting to load usage data from App Group...
   📖 loadUsage() called
   ✅ Loaded usage data: 5 minutes from [date]
   📊 Updated pet usage: 0 → 5 minutes
   ```

4. **Check the top bar** - It should now show `5/60 min` (or your limit)

If the test works, **the data flow is correct** and we just need to trigger the report extension!

## Solutions

### Option 1: Use DeviceActivityMonitor Only (Current)

The Monitor extension can save usage at:
- Interval start (midnight)
- Interval end (midnight) 
- Event thresholds (when you hit your limit)

**Pros:**
- Already implemented
- No additional views needed

**Cons:**
- Updates only at specific events, not continuously
- Can't get real-time usage

### Option 2: Add DeviceActivityReport View (Recommended for Real-Time)

Add a hidden `DeviceActivityReport` view that triggers the extension to fetch real usage:

```swift
// In HomeView.swift
if let config = appLimitConfig {
    DeviceActivityReport(
        .init("Total Activity"),
        filter: makeFilter(from: config)
    )
    .frame(width: 0, height: 0)
    .opacity(0)
}
```

**Pros:**
- Real-time usage updates
- Accurate Screen Time data

**Cons:**
- More complex
- Report extension must be properly configured

### Option 3: Manual Refresh Only

Keep the current setup but rely on users tapping the refresh button:

**Pros:**
- Simple
- User-controlled

**Cons:**
- Not automatic
- Requires user action

## Recommended Approach

For now, use **Option 3 (Manual Refresh)** with the test menu to verify everything works. Once confirmed:

1. Test with real Screen Time data using the Monitor extension
2. If that's not frequent enough, implement Option 2

## Console Logs to Watch For

### When you tap "Test: Add 5 min":
```
🧪 Test: Added 5 minutes (now 5)
💾 saveUsage() called with 5 minutes
✅ Saved usage data: 5 minutes to key 'screentime.usage.data' in app group 'group.com.kookytrove.unhooked'
🔄 updateUsageFromScreenTime() called
📱 Attempting to load usage data from App Group...
📖 loadUsage() called
✅ Loaded usage data: 5 minutes from [date]
📊 Updated pet usage: 0 → 5 minutes
```

### If you see these errors:
- `❌ Failed to get UserDefaults for app group` - App Group not configured
- `ℹ️ No data found for key` - No data has been saved yet
- `❌ No usage data found in App Group` - Data flow broken

## Next Steps

1. **Test the manual "Add 5 min" button** - Verify data flow works
2. **Use the tracked app** for a few minutes
3. **Wait for midnight** (or hit your limit) - Monitor extension should save data
4. **Check console logs** for DeviceActivityMonitor messages
5. **If no automatic updates**, we'll implement Option 2

---

## Real Screen Time Tracking (When Ready)

The Monitor extension (`DeviceActivityMonitor.swift`) should save usage at:

- **intervalDidEnd** - At midnight
- **eventDidReachThreshold** - When limit is hit

Check for these console logs:
```
🔴 DeviceActivityMonitor: Interval Did End for com.unhooked.limit
📊 DeviceActivityReport: [X] minutes saved to App Group
```

If you don't see these, the monitoring might not be started correctly. Check:
1. Family Controls authorized?
2. startMonitoring() called after setup?
3. DeviceActivity extension installed on device?



