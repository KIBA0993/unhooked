//
//  MainTabView.swift
//  Unhooked
//
//  Main tab navigation
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(AppViewModel.self) private var viewModel
    @AppStorage("dynamicIslandPet.enabled") private var dynamicIslandPetEnabled = true
    @Environment(\.scenePhase) private var scenePhase
    
    private var shouldShowDynamicIslandPet: Bool {
        DeviceInfo.hasDynamicIsland && dynamicIslandPetEnabled
    }
    
    var body: some View {
        // Single view - Settings accessed via button in HomeView
        HomeView()
            .onChange(of: scenePhase) { _, newPhase in
                handleScenePhaseChange(newPhase)
            }
            .onAppear {
                // Delay slightly to ensure pet is loaded
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showFloatingPetIfNeeded()
                }
            }
            .onChange(of: viewModel.currentPet?.id) { _, _ in
                // Pet changed (created or loaded)
                showFloatingPetIfNeeded()
            }
            .onChange(of: viewModel.currentPet?.stage) { _, _ in
                // Stage changed
                if let pet = viewModel.currentPet {
                    FloatingPetController.shared.updatePet(species: pet.species, stage: pet.stage)
                }
            }
            .onChange(of: dynamicIslandPetEnabled) { _, enabled in
                if enabled {
                    showFloatingPetIfNeeded()
                } else {
                    FloatingPetController.shared.hide()
                }
            }
    }
    
    private func showFloatingPetIfNeeded() {
        guard shouldShowDynamicIslandPet,
              let pet = viewModel.currentPet,
              scenePhase == .active else {
            return
        }
        FloatingPetController.shared.show(species: pet.species, stage: pet.stage)
    }
    
    private func handleScenePhaseChange(_ newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            // App is in foreground - show floating pet (UIWindow)
            showFloatingPetIfNeeded()
        case .inactive, .background:
            // App minimized - hide floating pet, Live Activity takes over
            FloatingPetController.shared.hide()
        @unknown default:
            break
        }
    }
}

#Preview {
    MainTabView()
        .environment(AppViewModel(modelContext: ModelContext(
            try! ModelContainer(for: Pet.self)
        )))
}

