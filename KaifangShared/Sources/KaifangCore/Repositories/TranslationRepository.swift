//
//  TranslationRepository.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.05.25.
//

import CoreData

/// Central class for retrieving and saving translations.
public class TranslationRepository {
    public struct Translation {
        let id: UUID
        let originalText: String
        let originalTextLang: Locale.Language
        let translatedText: String
        let translatedTextLang: Locale.Language
    }
    
    /// Arguments for looking up a translation without an ID.
    public struct TranslationLookupArguments {
        let originalText: String
        let originalTextLang: Locale.Language
        let translatedTextLang: Locale.Language
    }
    
    private let container: NSPersistentContainer
    
    public init(container: NSPersistentContainer) {
        self.container = container
    }
    
    public func lookup(_ lookup: TranslationLookupArguments) async throws -> Translation? {
        return nil
    }
    
    public func find(id: UUID) async throws -> Translation? {
        return nil
    }
    
    public func save(_ translation: Translation) async throws {
        
    }
    
    public func delete(id: UUID) async throws {
        
    }
    
    public func clear() async throws {
        
    }
}
