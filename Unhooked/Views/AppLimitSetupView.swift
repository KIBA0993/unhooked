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
    @StateObject private var screenTimeService = ScreenTimeService()
    
    @State private var selection = FamilyActivitySelection()
    @State private var selectedLimit: Int = 180  // Default 3 hours
    @State private var showingError = false
    @State private var errorMessage = ""
    
    let isFirstTime: Bool
    let existingConfig: AppLimitConfig?
    
    let limitOptions = Array(stride(from: 15, through: 180, by: 15))  // 15 to 180 in 15-min increments
    
    var body: some View {
        NavigationStack {
            Form {
                // Show lock info if waiting period is active
                if let config = existingConfig, !config.canChangeLimit {
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundStyle(.orange)
                                Text("Change Locked")
                                    .font(.headline)
                                    .foregroundStyle(.orange)
                            }
                            
                            Text("You can change your limit again in \(config.daysUntilNextChange) day\(config.daysUntilNextChange == 1 ? "" : "s"), or pay to unlock now.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            // Pay to unlock this change
                            Button {
                                purchaseSingleEarlyChange()
                            } label: {
                                HStack {
                                    Image(systemName: "lock.open.fill")
                                    Text("Unlock Now")
                                    Spacer()
                                    Text("\(AppLimitConfig.earlyChangeCost) 💎")
                                        .fontWeight(.bold)
                                }
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // App Selection Section
                Section {
                    FamilyActivityPicker(selection: $selection)
                        .frame(height: 300)
                        .disabled(existingConfig != nil && !existingConfig!.canChangeLimit)
                        .opacity(existingConfig != nil && !existingConfig!.canChangeLimit ? 0.5 : 1.0)
                        .onChange(of: selection) { oldValue, newValue in
                            // Limit to only ONE app
                            if newValue.applicationTokens.count > 1 {
                                // Keep only the most recently selected app
                                let lastToken = Array(newValue.applicationTokens).last!
                                selection.applicationTokens = Set([lastToken])
                                selection.categoryTokens = []
                                selection.webDomainTokens = []
                            }
                            // Don't allow category/domain selection, only specific apps
                            if !newValue.categoryTokens.isEmpty || !newValue.webDomainTokens.isEmpty {
                                selection.categoryTokens = []
                                selection.webDomainTokens = []
                            }
                        }
                } header: {
                    Text("Select ONE App to Track")
                } footer: {
                    if existingConfig != nil && !existingConfig!.canChangeLimit {
                        Text("🔒 Unlock unlimited changes to modify your app selection")
                            .foregroundStyle(.orange)
                    } else {
                        Text("Choose one app that counts toward your daily limit")
                    }
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
                    .disabled(existingConfig != nil && !existingConfig!.canChangeLimit)
                    .opacity(existingConfig != nil && !existingConfig!.canChangeLimit ? 0.5 : 1.0)
                } header: {
                    Text("Daily Time Limit")
                } footer: {
                    if let config = existingConfig, !config.canChangeLimit {
                        Text("🔒 Wait \(config.daysUntilNextChange) day\(config.daysUntilNextChange == 1 ? "" : "s") or pay \(AppLimitConfig.earlyChangeCost) gems to change now")
                            .foregroundStyle(.orange)
                    } else if isFirstTime {
                        Text("First time setup is free. After this, you must wait 7 days or pay gems to change.")
                    } else {
                        Text("After saving, you must wait 7 days to change again (or pay gems).")
                    }
                }
                
                // Save Button
                if existingConfig == nil || existingConfig!.canChangeLimit {
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
                        #if targetEnvironment(simulator)
                        // In simulator, allow testing even without app selection
                        .disabled(false)
                        #else
                        .disabled(selection.applicationTokens.isEmpty && selection.categoryTokens.isEmpty)
                        #endif
                    } footer: {
                        #if targetEnvironment(simulator)
                        Text("⚠️ Simulator Mode: App selection won't work, but you can test the flow.")
                            .foregroundStyle(.orange)
                        #endif
                    }
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
    
    private func purchaseSingleEarlyChange() {
        guard let config = existingConfig else { return }
        
        do {
            let success = try viewModel.economyService.spendGems(
                userId: viewModel.userId,
                amount: AppLimitConfig.earlyChangeCost,
                reason: .adjustment,
                relatedItemId: "early_limit_change",
                idempotencyKey: UUID().uuidString
            )
            
            if success {
                config.earlyChangeUnlocked = true
                try? modelContext.save()
                print("✅ Unlocked single early change")
            } else {
                errorMessage = "Not enough gems. You need \(AppLimitConfig.earlyChangeCost) gems."
                showingError = true
            }
        } catch {
            errorMessage = "Failed to purchase: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func saveConfiguration() {
        // Check if can change (for existing configs)
        if let config = existingConfig, !config.canChangeLimit {
            errorMessage = "You must wait \(config.daysUntilNextChange) more days before changing your limit, or unlock unlimited changes."
            showingError = true
            return
        }
        
        #if targetEnvironment(simulator)
        // In simulator, create mock data since FamilyActivityPicker doesn't work
        print("🔵 Simulator: Saving with mock data")
        let mockData = Data() // Empty data for simulator testing
        
        if let config = existingConfig {
            config.selectedApps = mockData
            config.limitMinutes = selectedLimit
            config.recordChange()  // Records change and consumes early unlock if active
            print("✅ Updated existing config: \(selectedLimit) minutes")
        } else {
            let config = AppLimitConfig(
                userId: viewModel.userId,
                selectedApps: mockData,
                limitMinutes: selectedLimit
            )
            modelContext.insert(config)
            print("✅ Created new config: \(selectedLimit) minutes")
        }
        
        // Update the Pet's currentLimit so the UI bar updates
        if let pet = viewModel.currentPet {
            pet.currentLimit = selectedLimit
            print("✅ Updated pet currentLimit to \(selectedLimit) minutes")
        }
        
        do {
            try modelContext.save()
            print("✅ Saved modelContext successfully")
        } catch {
            print("❌ Failed to save modelContext: \(error)")
        }
        
        // Start monitoring (won't actually work in simulator but sets up the structure)
        screenTimeService.startMonitoring(with: selection)
        
        // Force UI refresh by triggering viewModel update
        Task { @MainActor in
            await viewModel.refreshPet()
        }
        
        dismiss()
        return
        #endif
        
        // Real device: Encode selection
        guard let encoded = try? JSONEncoder().encode(selection) else {
            errorMessage = "Failed to save app selection"
            showingError = true
            return
        }
        
        if let config = existingConfig {
            // Update existing
            config.selectedApps = encoded
            config.limitMinutes = selectedLimit
            config.recordChange()  // Records change and consumes early unlock if active
        } else {
            // Create new
            let config = AppLimitConfig(
                userId: viewModel.userId,
                selectedApps: encoded,
                limitMinutes: selectedLimit
            )
            modelContext.insert(config)
        }
        
        // Update the Pet's currentLimit so the UI bar updates
        if let pet = viewModel.currentPet {
            pet.currentLimit = selectedLimit
            print("✅ Updated pet.currentLimit to \(selectedLimit) minutes")
        }
        
        do {
            try modelContext.save()
            print("✅ Saved modelContext successfully")
        } catch {
            print("❌ Failed to save modelContext: \(error)")
        }
        
        // Start monitoring with the selected app
        screenTimeService.startMonitoring(with: selection)
        
        // Force UI refresh by triggering viewModel update
        Task { @MainActor in
            await viewModel.refreshPet()
        }
        
        dismiss()
    }
}


#Preview {
    let container = try! ModelContainer(for: Pet.self)
    let context = ModelContext(container)
    return AppLimitSetupView(isFirstTime: true, existingConfig: nil)
        .environment(AppViewModel(modelContext: context))
}

