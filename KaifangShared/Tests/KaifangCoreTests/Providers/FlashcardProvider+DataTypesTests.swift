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
    // MARK: Type aliases
    typealias Flashcard = FlashcardProvider.Flashcard
    typealias ReviewRating = FlashcardProvider.ReviewRating
    
    // MARK: Setup
    
    private let context: NSManagedObjectContext
    
    init() throws {
        context = try PersistenceController.getTestingContext()
    }
    
    // MARK: Transformation tests
    
    @Test(
        "Marking the flashcard as reviewed returns a new flashcard with updated metadata",
        arguments: [ReviewRating.again, .hard, .good, .easy]
    )
    func markingFlashcardAsReviewedReturnsFlashcardWithUpdatedMetadata(
        case: ReviewRating
    ) async throws {
        
    }
}
