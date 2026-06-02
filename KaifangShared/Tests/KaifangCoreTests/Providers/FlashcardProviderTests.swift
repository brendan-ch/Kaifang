//
//  FlashcardProviderTests.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.06.02.
//

import Testing
@testable import KaifangCore
import CoreData

@Suite
struct FlashcardProviderTests {
    // MARK: Setup
    let container: NSPersistentContainer
    let translationRepository: TranslationRepository
    let repository: FlashcardRepository
    let translationProvider: TranslationProvider
    let provider: FlashcardProvider
    
    init() throws {
        container = try PersistenceController.getTestingContainer()
        repository = FlashcardRepository(container: container)
        translationRepository = TranslationRepository(container: container)
        translationProvider = TranslationProvider(
            repository: translationRepository,
            modelProvider: StubModelProvider(
                response: TranslationProvider.Translation(
                    id: UUID(),
                    originalText: "Hello",
                    originalTextLang: Locale.Language(identifier: "en-US"),
                    originalTextContext: nil,
                    translatedText: "您好",
                    translatedTextLang: Locale.Language(identifier: "zh-CN")
                )
            )
        )
        provider = FlashcardProvider(repository: repository)
    }
    
    // MARK: CRUD functionality
    @Test("Creating a flashcard with the creation arguments saves it for later")
    func createFlashcardWithArgsSavesForLater() async throws {
        // try different combinations of args
        // fewer lines of code simply to save a new flashcard
    }
    
    @Test("Deleting a flashcard by ID removes it from storage")
    func deleteFlashcardRemovesFromStorage() async throws {
        
    }
    
    // MARK: Flashcard functionality
    
    @Test("Getting the next flashcard returns the card with the oldest due date")
    func getNextFlashcardReturnsFlashcardWithOldestDueDate() async throws {
        
    }
    
    @Test("Marking a flashcard as reviewed saves it for later")
    func markFlashcardAsReviewedSavesToCoreData() async throws {
        
    }
    
    @Test("Refreshing a translation generates a translation with the provided translation provider")
    func refreshTranslationGeneratesTranslationWithGivenTranslationProvider() async throws {
        // the test is the orchestration of the translation, not the translation part itself
    }
}
