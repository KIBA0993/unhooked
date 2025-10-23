//
//  CloudSyncService.swift
//  Unhooked
//
//  iCloud sync status monitoring
//

import Foundation
import Combine

@MainActor
class CloudSyncService: ObservableObject {
    @Published var iCloudAvailable: Bool = false
    @Published var syncStatus: SyncStatus = .unknown
    
    private var ubiquityTokenObserver: NSObjectProtocol?
    
    enum SyncStatus {
        case unknown
        case syncing
        case synced
        case notAvailable
        case error(String)
        
        var displayText: String {
            switch self {
            case .unknown:
                return "Checking..."
            case .syncing:
                return "Syncing..."
            case .synced:
                return "Synced"
            case .notAvailable:
                return "Not Available"
            case .error(let message):
                return "Error: \(message)"
            }
        }
        
        var icon: String {
            switch self {
            case .unknown:
                return "questionmark.circle"
            case .syncing:
                return "arrow.triangle.2.circlepath"
            case .synced:
                return "checkmark.icloud"
            case .notAvailable:
                return "xmark.icloud"
            case .error:
                return "exclamationmark.icloud"
            }
        }
    }
    
    init() {
        checkiCloudStatus()
        observeiCloudChanges()
    }
    
    deinit {
        if let observer = ubiquityTokenObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Status Checking
    
    func checkiCloudStatus() {
        // Check if user is signed into iCloud
        if FileManager.default.ubiquityIdentityToken != nil {
            iCloudAvailable = true
            syncStatus = .synced
            print("☁️ iCloud available")
        } else {
            iCloudAvailable = false
            syncStatus = .notAvailable
            print("📱 iCloud not available - user not signed in")
        }
    }
    
    // MARK: - Monitoring
    
    private func observeiCloudChanges() {
        // Observe changes to iCloud availability
        ubiquityTokenObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name.NSUbiquityIdentityDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("🔄 iCloud status changed")
            Task { @MainActor [weak self] in
                self?.checkiCloudStatus()
            }
        }
    }
    
    // MARK: - User Actions
    
    func refreshStatus() {
        syncStatus = .syncing
        
        // Simulate checking sync status
        Task {
            try? await Task.sleep(for: .seconds(1))
            checkiCloudStatus()
        }
    }
    
    var statusMessage: String {
        if iCloudAvailable {
            return "Your pet's progress is automatically synced across all your devices using iCloud."
        } else {
            return "Sign in to iCloud in Settings to sync your progress across devices."
        }
    }
    
    var canSync: Bool {
        return iCloudAvailable
    }
}

