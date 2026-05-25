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
    func testDueDateIsCorrectlySet() {
        let persistenceController = PersistenceController(inMemory: true)
        let context = persistenceController.container.viewContext
        
        let card = CDFlashcard(context: context)
        #expect(card.dueDate != nil)
        
        let deltaSeconds = abs(card.dueDate!.timeIntervalSinceNow)
        #expect(deltaSeconds < 0.5)
    }
}
