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
        // Single view - Settings accessed via button in HomeView
        HomeView()
    }
}

#Preview {
    MainTabView()
        .environment(AppViewModel(modelContext: ModelContext(
            try! ModelContainer(for: Pet.self)
        )))
}

