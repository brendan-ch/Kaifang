//
//  FlashcardRepositoryTests.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.06.02.
//

import Testing
@testable import KaifangCore
import CoreData

@Suite(.serialized)
struct FlashcardRepositoryTests {
    // MARK: Setup
    let container: NSPersistentContainer
    let repository: FlashcardRepository
    
    init() throws {
        container = try PersistenceController.getTestingContainer()
        repository = FlashcardRepository(container: container)
    }
    
    // MARK: Listing, filtering and sorting
    
    // MARK: Saving
    
    // MARK: Deleting
    
}
