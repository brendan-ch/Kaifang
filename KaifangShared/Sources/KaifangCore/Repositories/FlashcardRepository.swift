//
//  FlashcardProvider.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.06.02.
//

import CoreData

public class FlashcardRepository {
    // MARK: Type aliases
    public typealias Flashcard = FlashcardProvider.Flashcard
    public typealias FilterArguments = FlashcardProvider.FilterArguments
    public typealias SortCriteria = FlashcardProvider.SortCriteria
    
    // MARK: Setup
    private let container: NSPersistentContainer
    
    init(container: NSPersistentContainer) {
        self.container = container
    }
    
    // MARK: Finding and lookup
    public func find(_ id: UUID) async throws -> Flashcard? {
        return nil
    }
    
    public func list(
        filterBy filterArguments: FilterArguments,
        sortBy sortArguments: SortCriteria
    ) -> [Flashcard] {
        return []
    }
    
    // MARK: Saving
    public func save(_ flashcard: Flashcard) async throws -> Flashcard {
        // TODO: persist to Core Data. Stubbed to echo the input so tests that
        // exercise the surrounding flow don't trap on an unimplemented method.
        return flashcard
    }
    
    // MARK: Deletion
    public func delete(id: UUID) async throws {
        
    }
    
    public func clear() async throws {
        
    }
    
    // MARK: Private helpers
}
