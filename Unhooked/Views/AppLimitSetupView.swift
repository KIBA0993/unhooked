//
//  AppLimitSetupView.swift
//  Unhooked
//
//  View for selecting apps and setting time limit
//

import SwiftUI
import FamilyControls
import SwiftData

struct AppLimitSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) private var viewModel
    @Environment(\.modelContext) private var modelContext
    
    @State private var selection = FamilyActivitySelection()
    @State private var selectedLimit: Int = 180  // Default 3 hours
    @State private var showingPaywall = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    let isFirstTime: Bool
    let existingConfig: AppLimitConfig?
    
    let limitOptions = Array(stride(from: 15, through: 180, by: 15))  // 15 to 180 in 15-min increments
    
    var body: some View {
        NavigationStack {
            Form {
                // App Selection Section
                Section {
                    FamilyActivityPicker(selection: $selection)
                        .frame(height: 300)
                } header: {
                    Text("Select Apps to Track")
                } footer: {
                    Text("Choose which apps count toward your daily limit")
                }
                
                // Time Limit Section
                Section {
                    Picker("Daily Limit", selection: $selectedLimit) {
                        ForEach(limitOptions, id: \.self) { minutes in
                            Text(formatMinutes(minutes))
                                .tag(minutes)
                        }
                    }
                    .pickerStyle(.wheel)
                } header: {
                    Text("Daily Time Limit")
                } footer: {
                    if let config = existingConfig, !config.canChangeLimit {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("⏱️ You can change your limit again in \(config.daysUntilNextChange) days")
                                .foregroundStyle(.orange)
                            
                            Button {
                                showingPaywall = true
                            } label: {
                                Label("Unlock Unlimited Changes", systemImage: "lock.open.fill")
                                    .foregroundStyle(.blue)
                            }
                        }
                    } else if isFirstTime {
                        Text("You can change this once immediately. After that, changes require a 7-day wait or premium unlock.")
                    } else {
                        Text("This is your free change! Next change requires 7-day wait or premium unlock.")
                    }
                }
                
                // Save Button
                Section {
                    Button {
                        saveConfiguration()
                    } label: {
                        HStack {
                            Spacer()
                            Text(isFirstTime ? "Start Tracking" : "Update Limit")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(selection.applicationTokens.isEmpty && selection.categoryTokens.isEmpty)
                }
            }
            .navigationTitle(isFirstTime ? "Setup App Limit" : "Update Limit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingPaywall) {
                UnlockUnlimitedChangesView(
                    onPurchase: {
                        if let config = existingConfig {
                            config.hasUnlockedUnlimitedChanges = true
                            try? modelContext.save()
                        }
                        showingPaywall = false
                    }
                )
            }
            .alert("Cannot Update", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                if let config = existingConfig {
                    selectedLimit = config.limitMinutes
                    // Decode existing selection
                    if let decoded = try? JSONDecoder().decode(FamilyActivitySelection.self, from: config.selectedApps) {
                        selection = decoded
                    }
                }
            }
        }
    }
    
    private func formatMinutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 && mins > 0 {
            return "\(hours)h \(mins)m"
        } else if hours > 0 {
            return "\(hours) hour\(hours > 1 ? "s" : "")"
        } else {
            return "\(mins) minutes"
        }
    }
    
    private func saveConfiguration() {
        // Check if can change (for existing configs)
        if let config = existingConfig, !config.canChangeLimit {
            errorMessage = "You must wait \(config.daysUntilNextChange) more days before changing your limit, or unlock unlimited changes."
            showingError = true
            return
        }
        
        // Encode selection
        guard let encoded = try? JSONEncoder().encode(selection) else {
            errorMessage = "Failed to save app selection"
            showingError = true
            return
        }
        
        if let config = existingConfig {
            // Update existing
            config.selectedApps = encoded
            config.limitMinutes = selectedLimit
            config.lastChangedAt = Date()
        } else {
            // Create new
            let config = AppLimitConfig(
                userId: viewModel.userId,
                selectedApps: encoded,
                limitMinutes: selectedLimit
            )
            modelContext.insert(config)
        }
        
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Unlock Paywall View

struct UnlockUnlimitedChangesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) private var viewModel
    
    let onPurchase: () -> Void
    
    // Assuming you have this product in your IAP list
    private let productId = "com.unhooked.unlimited_limit_changes"
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "lock.open.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
                
                Text("Unlock Unlimited Changes")
                    .font(.title.bold())
                
                Text("Change your app limits anytime without waiting 7 days between changes")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 12) {
                    FeatureRow(icon: "clock.arrow.2.circlepath", text: "Change limits anytime")
                    FeatureRow(icon: "slider.horizontal.3", text: "Adjust as your needs change")
                    FeatureRow(icon: "checkmark.seal.fill", text: "One-time purchase")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
                
                Button {
                    purchaseUnlock()
                } label: {
                    Text("Unlock for 99 Gems")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Button("Maybe Later") {
                    dismiss()
                }
                .foregroundStyle(.secondary)
                .padding(.bottom)
            }
            .navigationTitle("Premium Feature")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func purchaseUnlock() {
        // Spend gems to unlock
        do {
            let success = try viewModel.economyService.spendGems(
                userId: viewModel.userId,
                amount: 99,
                reason: .adjustment,
                relatedItemId: "unlimited_limit_changes",
                idempotencyKey: UUID().uuidString
            )
            
            if success {
                onPurchase()
                dismiss()
            }
        } catch {
            print("❌ Failed to spend gems: \(error)")
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 24)
            Text(text)
            Spacer()
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: Pet.self)
    let context = ModelContext(container)
    return AppLimitSetupView(isFirstTime: true, existingConfig: nil)
        .environment(AppViewModel(modelContext: context))
}

