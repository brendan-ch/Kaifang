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
    private func getSampleLookupArguments() -> TranslationProvider.LookupArguments {
        .init(
            originalText: "Hello",
            originalTextLang: .init(identifier: "en-Latn-US"),
            originalTextContext: nil,
            translatedTextLang: .init(identifier: "zh-Hans-CN")
        )
    }
    
    private func getSampleTranslation(id: UUID = UUID(), originalText: String = "Hello") -> TranslationProvider.Translation {
        .init(
            id: id,
            originalText: originalText,
            originalTextLang: .init(identifier: "en-Latn-US"),
            originalTextContext: nil,
            translatedText: "你好",
            translatedTextLang: .init(identifier: "zh-Hans-CN")
        )
    }

    // MARK: Tests
    @Test("Translation save and lookup returns the relevant translation if it exists")
    func translationSaveAndLookupGetsCorrectTranslation() async throws {
        let testTranslation = getSampleTranslation()
        _ = try await repository.save(testTranslation)
        
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
    
    @Test("Translation lookup without full original language code automatically infers the language")
    func translationLookupWithoutFullOriginalLanguageCodeInfers() async throws {
        let testTranslation = getSampleTranslation()
        _ = try await repository.save(testTranslation)
        
        let lookupArguments = TranslationProvider.LookupArguments(
            originalText: "Hello",
            originalTextLang: .init(identifier: "en-US"),
            originalTextContext: nil,
            translatedTextLang: .init(identifier: "zh-Hans-CN"),
        )
        
        let translation = try await repository.lookup(lookupArguments)
        #expect(translation?.originalTextLang == .init(identifier: "en-Latn-US"))
    }
    
    @Test("Translation lookup without full translated language code automatically infers the language")
    func translationLookupWithoutFullTranslatedLanguageCodeInfers() async throws {
        let testTranslation = getSampleTranslation()
        _ = try await repository.save(testTranslation)
        
        let lookupArguments = TranslationProvider.LookupArguments(
            originalText: "Hello",
            originalTextLang: .init(identifier: "en-Latn-US"),
            originalTextContext: nil,
            translatedTextLang: .init(identifier: "zh-CN"),
            // should be "zh-Hans-CN"
        )

        let translation = try await repository.lookup(lookupArguments)
        #expect(translation?.translatedTextLang == .init(identifier: "zh-Hans-CN"))
    }
    
    @Test("Translation saving and lookup by original text is case-insensitive")
    func translationSaveAndLookupIsCaseInsensitive() async throws {
        let testTranslation = getSampleTranslation()
        _ = try await repository.save(testTranslation)

        let lookupArguments = TranslationProvider.LookupArguments(
            originalText: "hELlo",
            originalTextLang: .init(identifier: "en-Latn-US"),
            originalTextContext: nil,
            translatedTextLang: .init(identifier: "zh-Hans-CN")
        )
        
        let retrievedTranslation = try await repository.lookup(lookupArguments)
        #expect(retrievedTranslation == testTranslation)
    }
    
    @Test("Translation saving and finding by ID returns translation if found")
    func translationSaveAndFindByIdReturnsTranslation() async throws {
        let testTranslation = getSampleTranslation()
        _ = try await repository.save(testTranslation)
        
        let retrievedTranslation = try await repository.find(id: testTranslation.id)
        #expect(retrievedTranslation == testTranslation)
    }
    
    @Test("Translation finding by ID returns nil if not found")
    func translationFindByIdReturnsNil() async throws {
        let retrievedTranslation = try await repository.find(id: UUID())
        #expect(retrievedTranslation == nil)
    }
    
    @Test("Saving a translation without full original language code automatically infers it")
    func saveTranslationWithoutFullOriginalLanguageCodeThrowsError() async throws {
        let testTranslation = TranslationProvider.Translation(
            id: UUID(),
            originalText: "Hello",
            originalTextLang: .init(identifier: "en-US"),
            originalTextContext: nil,
            translatedText: "你好",
            translatedTextLang: .init(identifier: "zh-Hans-CN")
        )
        
        let updatedTranslation = try await repository.save(testTranslation)
        #expect(updatedTranslation.originalTextLang == .init(identifier: "en-Latn-US"))
    }
    
    @Test("Saving a translation without full translated language code automatically infers it")
    func saveTranslationWithoutFullTranslatedLanguageCodeThrowsError() async throws {
        let testTranslation = TranslationProvider.Translation(
            id: UUID(),
            originalText: "Hello",
            originalTextLang: .init(identifier: "en-Latn-US"),
            originalTextContext: nil,
            translatedText: "你好",
            translatedTextLang: .init(identifier: "zh-TW")
        )
        
        let updatedTranslation = try await repository.save(testTranslation)
        #expect(updatedTranslation.translatedTextLang == .init(identifier: "zh-Hant-TW"))
    }
    
    @Test("Saving a translation with an existing ID updates the translation")
    func saveTranslationWithSameIdUpdatesTranslation() async throws {
        let testTranslation = try await repository.save(getSampleTranslation())
        
        let updatedTranslation = testTranslation.withUpdatedTranslation("Updated translation")
        _ = try await repository.save(updatedTranslation)
        
        let retrievedTranslation = try await repository.find(id: testTranslation.id)
        #expect(retrievedTranslation == updatedTranslation)
    }
    
    @Test("Saving a translation with the same original text + language throws an error")
    func saveTranslationWithExistingOriginalTextAndLangThrowsError() async throws {
        let testTranslation = getSampleTranslation()
        let secondTestTranslation = getSampleTranslation()
        
        _ = try await repository.save(testTranslation)
        
        await #expect(throws: TranslationRepository.Error.duplicateOriginalTextAndLang(id: secondTestTranslation.id)) {
            try await repository.save(secondTestTranslation)
        }
    }
    
    @Test("Deleting a translation via ID removes it from the context immediately")
    func deleteTranslationDeletesFromContext() async throws {
        let testTranslation = getSampleTranslation()
        _ = try await repository.save(testTranslation)
        
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
        
        for i in 0..<3 {
            let testTranslation = getSampleTranslation(originalText: "Hello \(i)")
            _ = try await repository.save(testTranslation)
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
