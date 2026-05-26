//
//  TranslationRepositoryTests.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.05.25.
//

import Testing
@testable import KaifangCore

struct TranslationRepositoryTests {
    @Test("Translation lookup returns the relevant translation by original text, original language and translation language if it exists")
    func translationLookupGetsCorrectTranslation() async throws {
        
    }
    
    @Test("Translation lookup returns nil if the translation doesn't exist")
    func translationLookupReturnsNilIfNoTranslation() async throws {
        
    }
    
    @Test("Translation lookup by original text is case-insensitive")
    func translationLookupIsCaseInsensitive() async throws {
        
    }
    
    @Test("Saving a new translation saves the context")
    func saveTranslationPersistsTranslationInContext() async throws {
        
    }
    
    @Test("Saving a translation with an existing ID updates the translation")
    func saveTranslationWithSameIdUpdatesTranslation() async throws {
        
    }
    
    @Test("Saving a translation with the same original text + language throws an error")
    func saveTranslationWithExistingOriginalTextAndLangThrowsError() async throws {
        
    }
    
    @Test("Deleting a translation via ID removes it from the context immediately")
    func deleteTranslationDeletesFromContext() async throws {
        
    }
    
    @Test("Clearing all translations clears the stored translations")
    func clearAllTranslationsClearsStoredTranslationsFromContext() async throws {
        
    }
    
    @Test("Clearing all translations does not clear other data types")
    func clearAllTranslationsOnlyClearsTranslations() async throws {
        
    }
}
