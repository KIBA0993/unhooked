//
//  Memorial.swift
//  Unhooked
//
//  Memorial snapshots of deceased pets
//

import Foundation
import SwiftData

@Model
final class Memorial {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var petSpecies: Species
    var petStage: Int
    var petName: String?
    var snapshotImagePath: String?  // Local file path
    var deathDate: Date
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        petSpecies: Species,
        petStage: Int,
        petName: String? = nil,
        snapshotImagePath: String? = nil,
        deathDate: Date
    ) {
        self.id = id
        self.userId = userId
        self.petSpecies = petSpecies
        self.petStage = petStage
        self.petName = petName
        self.snapshotImagePath = snapshotImagePath
        self.deathDate = deathDate
        self.createdAt = Date()
    }
}

@Model
final class MemorialConfig {
    @Attribute(.unique) var id: String = "singleton"
    var enabled: Bool = true
    var maxSnapshotsPerUser: Int = 5
    var updatedAt: Date
    
    init() {
        self.updatedAt = Date()
    }
}


