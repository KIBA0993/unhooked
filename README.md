# Unhooked

A delightful virtual pet companion that helps you build healthier phone usage habits.

## Overview

Unhooked is an iOS app that gamifies mindful phone usage. Stay under your daily screen time limit to earn Energy, then use that Energy to care for your virtual friend. The app features:

- **Virtual Pet System**: Choose between a cat or dog companion that grows as you maintain healthy habits
- **Health State Machine**: Pets transition through Healthy → Sick → Dead states based on care
- **Dual Currency Economy**: Energy (earned daily) and Gems (IAP)
- **Species-Aware Food Shop**: Context-specific items for cats and dogs
- **Recovery System**: Cure, Revive, or Restart with balanced pricing and cooldowns
- **Cosmetics Store**: Expressive customization with dual currency pricing
- **Memorial System**: Remember departed friends
- **Screen Time Integration**: Automatic usage tracking and Energy calculation

## Architecture

### Core Systems

#### 1. Data Models (`/Models`)
- **Pet**: Core pet model with health states, species, growth tracking
- **DailyStats**: Usage tracking and energy award history
- **FoodCatalogItem**: Species-scoped food items with overrides
- **RecoveryConfig**: Server-configurable recovery pricing and limits
- **Ledger**: Immutable transaction log for all currency movements
- **Memorial**: Snapshots of deceased pets
- **CosmeticItem**: Dual-currency cosmetics
- **FeatureFlag**: Runtime feature toggles

#### 2. Services (`/Services`)

**HealthService**
- Manages health state transitions (Healthy/Sick/Dead)
- Performs daily health checks based on feeding
- Natural recovery logic (2 fed days in 3-day window)
- Visual effects based on health state

**EconomyService**
- Daily energy calculation: `E = round(150 × max(0, 1 - r)^γ)`
- Wallet management (Energy & Gems)
- Ledger tracking for all transactions
- Daily reset and growth application

**FoodService**
- Species-aware catalog filtering (cat/dog/both)
- Per-species stat overrides
- Fed-today threshold (100 Energy)
- Buff accumulation with health-state caps

**RecoveryService**
- Cure (Sick→Healthy): 120 Gems, 24h cooldown, 5/30d limit
- Revive (Dead→Healthy+Fragile): 400 Gems, 168h cooldown, 2/90d limit
- Restart (New Pet): 200 Gems, 24h cooldown
- Idempotency support for all actions

**CosmeticsService**
- Dual currency support (Energy and/or Gems)
- Seasonal availability windows
- Ownership tracking

**IAPService**
- StoreKit 2 integration
- Receipt validation
- Refund handling with entitlement rollback
- Transaction observer for automatic updates

**AnalyticsService**
- Event tracking (recovery, food, IAP, health KPIs)
- Batch upload to backend
- Sent/unsent state management

**FeatureFlagService**
- Runtime feature toggles
- Server-driven configuration
- Default flag seeding

**ScreenTimeService**
- FamilyControls integration
- Daily usage monitoring
- Limit configuration

#### 3. Views (`/Views`)

**HomeView**
- Pet visualization with health overlays
- Sick/Dead banners with CTAs
- Stats display (fullness, mood, stage)
- Action buttons (Feed, Cosmetics)

**FoodShopView**
- Species-filtered catalog
- Energy balance display
- Purchase flow with stat preview

**CosmeticsShopView**
- Multi-category browsing
- Dual currency pricing
- Owned item tracking

**MemorialView**
- Grid layout of departed friends
- Snapshot display

**SettingsView**
- Screen Time authorization
- Daily limit picker
- Wallet balances
- Purchase Gems navigation

**MainTabView**
- Home, Memories, Settings tabs

#### 4. ViewModels (`/ViewModels`)

**AppViewModel**
- Central coordinator for all services
- Pet state management
- UI actions (feed, recover, purchase)
- Daily reset orchestration

### Data Flow

```
User Action
    ↓
ViewModel
    ↓
Service Layer
    ↓
SwiftData Models
    ↓
Persistence
```

### Key Algorithms

**Energy Award**
```swift
r = usage_minutes / limit_minutes  // Clamped ≥ 0
r_smooth = moving_average(r, window: 2 days)
E_day = round(150 × max(0, 1 - r_smooth)^γ)  // γ = 1.0
```

**Health Transitions**
- `consecutive_unfed_days` increments at reset if `fed_today == false`
- Sick at 3 consecutive unfed days
- Dead at 7 consecutive unfed days
- Natural recovery: 2 fed days in rolling 3-day window

**Buff System**
```swift
daily_buff_cap = {
    healthy: 0.25 (or 0.15 if fragile)
    sick: 0.10
    dead: 0.0
}

daily_buff = min(cap, sum(food_buff_fracs))
```

## Tech Stack

- **UI**: SwiftUI
- **Data**: SwiftData (local), CoreData-compatible schema
- **IAP**: StoreKit 2
- **Screen Time**: FamilyControls, DeviceActivity
- **Analytics**: Custom event system with backend sync
- **Architecture**: MVVM with Service layer

## PRD Compliance

This implementation follows the **Unhooked PRD v1.8** specifications:

✅ Health state machine with all transitions  
✅ Dual currency economy (Energy/Gems)  
✅ Species-specific food catalog with overrides  
✅ Recovery flows (Cure/Revive/Restart) with cooldowns & limits  
✅ Cosmetics with dual pricing  
✅ Memorial system  
✅ IAP with receipt validation & ledger  
✅ Analytics event tracking  
✅ Feature flags  
✅ Screen Time integration  

### Guardrails Enforced
- Food is Energy-only (no Gems for gameplay advantage)
- Cosmetics are cosmetic-only (no stat bonuses)
- Buff caps by health state (0.25/0.15/0.10/0.0)
- Recovery limits server-enforced
- Idempotent transactions
- Refund entitlement rollback

## Setup

### Requirements
- iOS 17.0+
- Xcode 15+
- Swift 5.9+

### Configuration

1. **App Capabilities**
   - Enable In-App Purchase
   - Add Family Controls capability
   - Add Device Activity capability

2. **StoreKit Configuration**
   - Create products: `gems_100`, `gems_500`, `gems_1200`, `gems_2500`
   - Configure App Store Connect

3. **Entitlements**
   - `com.apple.developer.family-controls`
   - `com.apple.developer.device-activity`

4. **Info.plist**
   - `NSFamilyControlsUsageDescription`: "Unhooked needs access to your screen time data to reward you with Energy for staying under your daily limit."

### Building

```bash
# Clone the repo
cd Unhooked

# Open in Xcode
open Unhooked.xcodeproj

# Select target device/simulator
# Build and run (⌘R)
```

## Testing

Run tests in Xcode Test Navigator (⌘U) or:

```bash
xcodebuild test \
  -project Unhooked.xcodeproj \
  -scheme Unhooked \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Test Coverage

- ✅ Health state transitions
- ✅ Energy calculation formulas
- ✅ Wallet operations (spend/award)
- ✅ Species food filtering
- ✅ Fed-today threshold
- ✅ Buff cap enforcement
- ✅ Ledger immutability

## Development Notes

### Adding New Food Items

```swift
let item = FoodCatalogItem(
    itemId: "unique_id",
    title: "Display Name",
    priceEnergy: 50,
    speciesScope: .cat,  // or .dog or .both
    defaultFullnessDelta: 20,
    defaultMoodDelta: 1,
    defaultBuffFrac: 0.05
)

// Optional: Species overrides
item.speciesOverrides = [
    .cat: FoodOverride(
        fullnessDelta: 25,
        feedAnimationId: "custom_anim"
    )
]
```

### Adding Feature Flags

```swift
try featureFlagService.setFlag(
    key: "feature.new_system",
    enabled: true,
    description: "Enable new feature"
)

// Usage
if featureFlagService.isEnabled("feature.new_system") {
    // Feature code
}
```

### Analytics Events

```swift
analyticsService.track(
    eventName: "custom_event",
    properties: [
        "key1": "value1",
        "key2": "value2"
    ]
)
```

## Admin/CMS Features

The app includes infrastructure for server-driven configuration:

- Recovery pricing/limits via `RecoveryConfig`
- Food catalog via `FoodCatalogItem` management
- Feature flags via `FeatureFlag` updates
- Memorial configuration via `MemorialConfig`

A separate admin web portal would provide:
- Visual config editor with diff preview
- Two-person approval for price changes
- Publishing safety validations
- User support tools (ledger export, memorial access)

## Future Enhancements

- [ ] Backend API integration (currently local-only)
- [ ] Push notifications for daily reset
- [ ] Widget support (Home/Lock screen)
- [ ] Cloud sync for multi-device
- [ ] Social features (friends, not leaderboards)
- [ ] More pet species
- [ ] Quest system
- [ ] Seasonal events
- [ ] AR pet visualization

## License

Copyright © 2025 Unhooked. All rights reserved.

---

**Built with ❤️ to help people use their phones more intentionally.**


