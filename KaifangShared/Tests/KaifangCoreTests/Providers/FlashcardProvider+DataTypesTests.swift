//
//  FlashcardProvider+DataTypesTests.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.06.02.
//

import Testing
@testable import KaifangCore
import CoreData

@Suite(.serialized)
struct FlashcardTests {
    // MARK: Setup
    
    private let context: NSManagedObjectContext
    
    init() throws {
        context = try PersistenceController.getTestingContext()
    }
    
    // MARK: Transformation tests
    
    @Test("Marking the flashcard as reviewed returns a new flashcard with updated metadata")
    func markingFlashcardAsReviewedReturnsFlashcardWithUpdatedMetadata() async throws {
        
    }
    
    @Test("Performing a translation transform with a translation provider returns a new flashcard with an updated translation")
    func translationTransformReturnsNewFlashcardWithUpdatedTranslation() async throws {
        
    }
}
