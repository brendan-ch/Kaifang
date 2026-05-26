//
//  TranslationRepositoryTests.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.05.25.
//

import CoreData
import Foundation
import Testing
@testable import KaifangCore

@Suite
struct TranslationRepositoryTests {
    // MARK: Setup
    private let container: NSPersistentContainer
    private let repository: TranslationRepository
    
    init() async throws {
        container = PersistenceController.getTestingContainer()
        repository = TranslationRepository(container: container)
    }
    
    // MARK: Data helpers
    private func getSampleLookupArguments() -> TranslationRepository.LookupArguments {
        .init(
            originalText: "Hello",
            originalTextLang: .init(identifier: "en-US"),
            translatedTextLang: .init(identifier: "zh-CN")
        )
    }
    
    private func getSampleTranslation() -> TranslationRepository.Translation {
        .init(
            id: UUID(),
            originalText: "Hello",
            originalTextLang: .init(identifier: "en-US"),
            translatedText: "你好",
            translatedTextLang: .init(identifier: "zh-CN")
        )
    }

    // MARK: Tests
    @Test("Translation save and lookup returns the relevant translation if it exists")
    func translationSaveAndLookupGetsCorrectTranslation() async throws {
        let testTranslation = getSampleTranslation()
        try await repository.save(testTranslation)
        
        let lookupArguments = getSampleLookupArguments()
        let retrievedTranslation = try await repository.lookup(lookupArguments)
        
        #expect(retrievedTranslation == testTranslation)
    }
    
    @Test("Translation lookup returns nil if the translation doesn't exist")
    func translationLookupReturnsNilIfNoTranslation() async throws {
        let lookupArguments = getSampleLookupArguments()
        let retrievedTranslation = try await repository.lookup(lookupArguments)
        
        #expect(retrievedTranslation == nil)
    }
    
    @Test("Translation saving and lookup by original text is case-insensitive")
    func translationSaveAndLookupIsCaseInsensitive() async throws {
        let testTranslation = getSampleTranslation()
        try await repository.save(testTranslation)

        let lookupArguments = TranslationRepository.LookupArguments(
            originalText: "hELlo",
            originalTextLang: .init(identifier: "en-US"),
            translatedTextLang: .init(identifier: "zh-CN")
        )
        
        let retrievedTranslation = try await repository.lookup(lookupArguments)
        #expect(retrievedTranslation == testTranslation)
    }
    
    @Test("Translation saving and finding by ID returns translation if found")
    func translationSaveAndFindByIdReturnsTranslation() async throws {
        let testTranslation = getSampleTranslation()
        try await repository.save(testTranslation)
        
        let retrievedTranslation = try await repository.find(id: testTranslation.id)
        #expect(retrievedTranslation == testTranslation)
    }
    
    @Test("Translation finding by ID returns nil if not found")
    func translationFindByIdReturnsNil() async throws {
        let retrievedTranslation = try await repository.find(id: UUID())
        #expect(retrievedTranslation == nil)
    }
    
    @Test("Saving a translation with an existing ID updates the translation")
    func saveTranslationWithSameIdUpdatesTranslation() async throws {
        let testTranslation = getSampleTranslation()
        try await repository.save(testTranslation)
        
        var updatedTranslation = testTranslation.withUpdatedTranslation("Updated translation")
        try await repository.save(updatedTranslation)
        
        let retrievedTranslation = try await repository.find(id: testTranslation.id)
        #expect(retrievedTranslation == updatedTranslation)
    }
    
    @Test("Saving a translation with the same original text + language throws an error")
    func saveTranslationWithExistingOriginalTextAndLangThrowsError() async throws {
        let testTranslation = getSampleTranslation()
        let secondTestTranslation = getSampleTranslation()
        
        try await repository.save(testTranslation)
        
        await #expect(throws: TranslationRepository.Error.duplicateOriginalTextAndLang(id: secondTestTranslation.id)) {
            try await repository.save(secondTestTranslation)
        }

    }
    
    @Test("Deleting a translation via ID removes it from the context immediately")
    func deleteTranslationDeletesFromContext() async throws {
        let testTranslation = getSampleTranslation()
        try await repository.save(testTranslation)
        
        try await repository.delete(id: testTranslation.id)
        
        let retrievedTranslation = try await repository.find(id: testTranslation.id)
        #expect(retrievedTranslation == nil)
    }
    
    @Test("Deleting a non-existent translation throws an error")
    func deleteTranslationThrowsErrorIfNotFound() async throws {
        let id = UUID()
        await #expect(throws: TranslationRepository.Error.notFound(id: id)) {
            try await repository.delete(id: id)
        }
    }
    
    @Test("Clearing all translations clears the stored translations")
    func clearAllTranslationsClearsStoredTranslationsFromContext() async throws {
        var ids: [UUID] = []
        
        for _ in 0..<3 {
            let testTranslation = getSampleTranslation()
            try await repository.save(testTranslation)
            ids.append(testTranslation.id)
        }
        
        try await repository.clear()
        
        for id in ids {
            let retrievedTranslation = try await repository.find(id: id)
            #expect(retrievedTranslation == nil)
        }
    }
    
    @Test("Clearing all translations does not clear other data types")
    func clearAllTranslationsOnlyClearsTranslations() async throws {
        var id: UUID? = nil
        try await container.performBackgroundTask { context in
            let article = CDBaseArticle(context: context)
            try context.save()
            id = article.id
        }
        
        try await repository.clear()
        
        let context = container.viewContext
        let fetchRequest = NSFetchRequest<CDBaseArticle>(entityName: "CDBaseArticle")
        fetchRequest.predicate = NSPredicate(format: "id == %@", id! as CVarArg)

        let results = try context.fetch(fetchRequest)
        #expect(results.count == 1)
        #expect(results[0].id == id)
    }
}
