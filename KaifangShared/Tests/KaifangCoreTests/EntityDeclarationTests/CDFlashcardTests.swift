//
//  CDFlashcardTests.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.05.25.
//

import Testing
@testable import KaifangCore

struct CDFlashcardTests {
    @Test("Newly created flashcard has correct due date")
    func testDueDateIsCorrectlySet() throws {
        let context = try PersistenceController.getTestingContext()
        
        let card = CDFlashcard(context: context)
        #expect(card.dueDate != nil)
        #expect(card.dueDate!.isCloseToNow())
    }
}
