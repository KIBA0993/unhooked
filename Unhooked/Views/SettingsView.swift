//
//  SettingsView.swift
//  Unhooked
//
//  Settings modal overlay matching Figma design
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) private var viewModel
    @StateObject private var screenTimeService = ScreenTimeService()
    @StateObject private var cloudSyncService = CloudSyncService()
    
    // Widget preferences
    @AppStorage("widget.enabled") private var widgetEnabled = true
    @AppStorage("widget.showStats") private var showWidgetStats = true
    @AppStorage("dynamicIsland.enabled") private var dynamicIslandEnabled = true
    
    @State private var showingPurchaseGems = false
    @State private var showingTutorial = false
    
    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }
            
            // Settings Card
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Settings")
                        .font(.system(size: 30, weight: .bold))
                    
                    Spacer()
                    
                    Button {
                        dismiss()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color(red: 0.95, green: 0.95, blue: 0.95))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.black)
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .border(width: 0, edges: [.bottom], color: Color.gray.opacity(0.2))
                
                // Content (scrollable)
                ScrollView {
                    VStack(spacing: 0) {
                        // Usage Tracking Section
                        sectionHeader(title: "USAGE TRACKING")
                        
                        VStack(spacing: 0) {
                            SettingsRow(
                                icon: "iphone",
                                iconColor: Color(red: 0.4, green: 0.6, blue: 1.0),
                                title: "Screen Time Access",
                                trailing: {
                                    if screenTimeService.isAuthorized {
                                        HStack(spacing: 4) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                            Text("Active")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.green)
                                        }
                                    } else {
                                        Button("Authorize") {
                                            Task {
                                                await screenTimeService.requestAuthorization()
                                                // After authorization, show app limit setup
                                                if screenTimeService.isAuthorized {
                                                    showingAppLimitSetup = true
                                                }
                                            }
                                        }
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.blue)
                                    }
                                },
                                subtitle: "Grant Screen Time access to track your usage and earn Energy"
                            )
                            
                            // Show app limit configuration if authorized
                            if screenTimeService.isAuthorized {
                                Divider()
                                
                                SettingsRow(
                                    icon: "app.badge",
                                    iconColor: Color.blue,
                                    title: currentAppLimitConfig == nil ? "Setup App Limit" : "Update App Limit",
                                    trailing: {
                                        Button(currentAppLimitConfig == nil ? "Setup" : "Edit") {
                                            showingAppLimitSetup = true
                                        }
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.blue)
                                    },
                                    subtitle: currentAppLimitConfig == nil
                                        ? "Select apps and set your daily limit"
                                        : "Limit: \(formatMinutes(currentAppLimitConfig!.limitMinutes))\(currentAppLimitConfig!.canChangeLimit ? "" : " • Next change in \(currentAppLimitConfig!.daysUntilNextChange)d")"
                                )
                            }
                        }
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                        )
                        .padding(.horizontal)
                        
                        separatorView()
                        
                        // Cloud Sync Section
                        sectionHeader(title: "CLOUD SYNC")
                        
                        VStack(spacing: 0) {
                            SettingsRow(
                                icon: "cloud",
                                iconColor: Color.gray.opacity(0.4),
                                title: "iCloud Sync",
                                trailing: {
                                    Text("Not Available")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray.opacity(0.6))
                                },
                                subtitle: "Sign in to iCloud in Settings to sync your progress across devices"
                            )
                        }
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                        )
                        .padding(.horizontal)
                        
                        separatorView()
                        
                        // Account Section
                        sectionHeader(title: "ACCOUNT")
                        
                        VStack(spacing: 0) {
                            // Energy Balance
                            SettingsRow(
                                icon: "bolt.fill",
                                iconColor: Color(red: 1.0, green: 0.76, blue: 0.0),
                                title: "Energy Balance",
                                trailing: {
                                    HStack(spacing: 4) {
                                        Text("⚡")
                                            .font(.system(size: 18))
                                        Text("\(viewModel.energyBalance)")
                                            .font(.system(size: 18, weight: .bold))
                                    }
                                }
                            )
                            
                            rowDivider()
                            
                            // Gems Balance
                            SettingsRow(
                                icon: "diamond",
                                iconColor: Color(red: 0.4, green: 0.86, blue: 0.86),
                                title: "Gems Balance",
                                trailing: {
                                    HStack(spacing: 4) {
                                        Text("💎")
                                            .font(.system(size: 18))
                                        Text("\(viewModel.gemsBalance)")
                                            .font(.system(size: 18, weight: .bold))
                                    }
                                }
                            )
                            
                            rowDivider()
                            
                            // Buy Gems
                            Button {
                                showingPurchaseGems = true
                            } label: {
                                SettingsRow(
                                    icon: "cart",
                                    iconColor: Color(red: 0.4, green: 0.6, blue: 1.0),
                                    title: "Buy Gems",
                                    trailing: {
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.gray.opacity(0.4))
                                    }
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                        )
                        .padding(.horizontal)
                        
                        separatorView()
                        
                        // Help & Tutorial Section
                        sectionHeader(title: "HELP & TUTORIAL")
                        
                        VStack(spacing: 0) {
                            Button {
                                showingTutorial = true
                            } label: {
                                SettingsRow(
                                    icon: "info.circle",
                                    iconColor: Color(red: 0.4, green: 0.6, blue: 1.0),
                                    title: "Show Tutorial",
                                    trailing: {
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.gray.opacity(0.4))
                                    }
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                        )
                        .padding(.horizontal)
                        
                        separatorView()
                        
                        // Widgets & Live Activity Section
                        sectionHeader(title: "WIDGETS & LIVE ACTIVITY")
                        
                        VStack(spacing: 0) {
                            // Home Screen Widget
                            SettingsRow(
                                icon: "square.grid.2x2",
                                iconColor: Color(red: 0.73, green: 0.53, blue: 1.0),
                                title: "Home Screen Widget",
                                trailing: {
                                    Toggle("", isOn: $widgetEnabled)
                                        .labelsHidden()
                                }
                            )
                            
                            rowDivider()
                            
                            // Dynamic Island Activity
                            SettingsRow(
                                icon: "waveform",
                                iconColor: Color(red: 1.0, green: 0.65, blue: 0.24),
                                title: "Dynamic Island Activity",
                                trailing: {
                                    Toggle("", isOn: $dynamicIslandEnabled)
                                        .labelsHidden()
                                }
                            )
                            
                            rowDivider()
                            
                            // Show Detailed Stats
                            SettingsRow(
                                icon: "chart.bar.fill",
                                iconColor: Color(red: 0.3, green: 0.8, blue: 0.5),
                                title: "Show Detailed Stats",
                                trailing: {
                                    Toggle("", isOn: $showWidgetStats)
                                        .labelsHidden()
                                }
                            )
                        }
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                        )
                        .padding(.horizontal)
                        
                        // App Info
                        VStack(spacing: 4) {
                            Text("Unhooked v2.0")
                                .font(.system(size: 14))
                                .foregroundColor(.gray.opacity(0.6))
                            Text("Build healthier phone habits 🌱")
                                .font(.system(size: 14))
                                .foregroundColor(.gray.opacity(0.6))
                        }
                        .padding(.vertical, 32)
                        .padding(.bottom, 16)
                    }
                }
                .background(Color(red: 0.97, green: 0.97, blue: 0.97))
            }
            .frame(maxWidth: 480)
            .frame(maxHeight: UIScreen.main.bounds.height * 0.9)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        }
        .sheet(isPresented: $showingPurchaseGems) {
            PurchaseGemsView()
                .environment(viewModel)
        }
        .fullScreenCover(isPresented: $showingTutorial) {
            TutorialView()
                .background(Color.clear)
        }
        .sheet(isPresented: $showingAppLimitSetup) {
            AppLimitSetupView(
                isFirstTime: currentAppLimitConfig == nil,
                existingConfig: currentAppLimitConfig
            )
        }
        .onAppear {
            loadAppLimitConfig()
        }
    }
    
    private func sectionHeader(title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.gray.opacity(0.7))
                .tracking(0.5)
            Spacer()
        }
        .padding(.horizontal, 22)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }
    
    private func separatorView() -> some View {
        Rectangle()
            .fill(Color.gray.opacity(0.15))
            .frame(height: 1)
            .padding(.vertical, 8)
    }
    
    private func rowDivider() -> some View {
        Divider()
            .padding(.leading, 62)
    }
    
    private func loadAppLimitConfig() {
        let descriptor = FetchDescriptor<AppLimitConfig>(
            predicate: #Predicate { $0.userId == viewModel.userId }
        )
        if let config = try? viewModel.modelContext.fetch(descriptor).first {
            currentAppLimitConfig = config
        }
    }
    
    private func formatMinutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 && mins > 0 {
            return "\(hours)h \(mins)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(mins)m"
        }
    }
}

// MARK: - Settings Row Component

struct SettingsRow<Trailing: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let trailing: () -> Trailing
    var subtitle: String? = nil
    
    init(
        icon: String,
        iconColor: Color,
        title: String,
        @ViewBuilder trailing: @escaping () -> Trailing,
        subtitle: String? = nil
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.trailing = trailing
        self.subtitle = subtitle
    }
    
    var body: some View {
        HStack(alignment: subtitle != nil ? .top : .center, spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(iconColor)
            }
            
            // Title and Subtitle
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.gray.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            Spacer()
            
            // Trailing content
            trailing()
        }
        .padding()
    }
}

// MARK: - Border Extension

extension View {
    func border(width: CGFloat, edges: [Edge], color: Color) -> some View {
        overlay(
            EdgeBorder(width: width, edges: edges)
                .foregroundColor(color)
        )
    }
}

struct EdgeBorder: Shape {
    var width: CGFloat
    var edges: [Edge]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for edge in edges {
            var x: CGFloat {
                switch edge {
                case .top, .bottom, .leading: return rect.minX
                case .trailing: return rect.maxX - width
                }
            }

            var y: CGFloat {
                switch edge {
                case .top, .leading, .trailing: return rect.minY
                case .bottom: return rect.maxY - width
                }
            }

            var w: CGFloat {
                switch edge {
                case .top, .bottom: return rect.width
                case .leading, .trailing: return width
                }
            }

            var h: CGFloat {
                switch edge {
                case .top, .bottom: return width
                case .leading, .trailing: return rect.height
                }
            }
            path.addRect(CGRect(x: x, y: y, width: w, height: h))
        }
        return path
    }
}

#Preview {
    ZStack {
        Color.purple.opacity(0.3)
            .ignoresSafeArea()
        
        SettingsView()
            .environment(AppViewModel(modelContext: ModelContext(
                try! ModelContainer(for: Pet.self, DailyStats.self, Wallet.self, LedgerEntry.self)
            )))
    }
}
