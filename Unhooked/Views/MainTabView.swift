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
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
    }
}

#Preview {
    MainTabView()
        .environment(AppViewModel(modelContext: ModelContext(
            try! ModelContainer(for: Pet.self)
        )))
}

