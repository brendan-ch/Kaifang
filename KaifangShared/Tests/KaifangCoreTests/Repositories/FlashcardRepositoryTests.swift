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
    
    // MARK: Finding and lookup
    @Test("Finding a flashcard returns from storage")
    func findReturnsFromStorage() async throws {
        
    }
    
    @Test("Finding a flashcard returns nil if not found")
    func findReturnsNilIfNotFound() async throws {
        
    }
    
    // MARK: Listing, filtering and sorting
    @Test("Different filtering options return the expected outputs")
    func filterOptionsReturnExpectedOutputs() async throws {
        
    }
    
    @Test("Different sorting options return the expected outputs")
    func sortOptionsReturnExpectedOutputs() async throws {
        
    }
    
    // MARK: Saving
    @Test("Saving an existing flashcard updates it")
    func saveExistingUpdates() async throws {
        
    }
    
    @Test("Saving a new flashcard creates it")
    func saveNewCreates() async throws {
        
    }
    
    // MARK: Deleting
    @Test("Deleting a flashcard removes it from storage")
    func deleteRemovesFromStorage() async throws {
        
    }
    
    @Test("Deleting throws if the flashcard is not found in storage")
    func deleteThrowsIfFlashcardNotFound() async throws {
        
    }
    
    @Test("Clearing does not clear other data types")
    func clearOnlyClearsFlashcards() async throws {
        
    }
}
