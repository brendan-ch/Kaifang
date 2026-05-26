//
//  TranslationRepository.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.05.25.
//

import CoreData
import Foundation

/// Central class for retrieving and saving translations.
public class TranslationRepository {
    private let container: NSPersistentContainer

    public init(container: NSPersistentContainer) {
        self.container = container
    }

    public func lookup(_ lookup: LookupArguments) async throws -> Translation? {
        let originalText = lookup.originalText
        let originalLangRaw = Self.identifier(for: lookup.originalTextLang)
        let originalTextContext = lookup.originalTextContext
        let translatedLangRaw = Self.identifier(for: lookup.translatedTextLang)

        return try await container.performBackgroundTask { context in
            let request = NSFetchRequest<CDCachedTranslation>(entityName: "CDCachedTranslation")
            request.predicate = Self.matchingPredicate(
                originalText: originalText,
                originalLangRaw: originalLangRaw,
                originalTextContext: originalTextContext,
                translatedLangRaw: translatedLangRaw
            )
            request.fetchLimit = 1
            return try context.fetch(request).first.flatMap(Translation.fromCoreData)
        }
    }

    public func find(id: UUID) async throws -> Translation? {
        try await container.performBackgroundTask { context in
            guard let entity = try Self.fetchEntity(id: id, in: context) else { return nil }
            return try Translation.fromCoreData(entity)
        }
    }

    public func save(_ translation: Translation) async throws -> Translation {
        var updatedDomainTranslation: Translation? = nil
        
        try await container.performBackgroundTask { context in
            let originalLangRaw = Self.identifier(for: translation.originalTextLang)
            let translatedLangRaw = Self.identifier(for: translation.translatedTextLang)

            let dupeRequest = NSFetchRequest<CDCachedTranslation>(entityName: "CDCachedTranslation")
            dupeRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                Self.matchingPredicate(
                    originalText: translation.originalText,
                    originalLangRaw: originalLangRaw,
                    originalTextContext: translation.originalTextContext,
                    translatedLangRaw: translatedLangRaw
                ),
                NSPredicate(format: "id != %@", translation.id as CVarArg),
            ])
            dupeRequest.fetchLimit = 1
            if try context.fetch(dupeRequest).first != nil {
                throw Error.duplicateOriginalTextAndLang(id: translation.id)
            }

            let entity: CDCachedTranslation
            if let existing = try Self.fetchEntity(id: translation.id, in: context) {
                entity = existing
            } else {
                entity = CDCachedTranslation(context: context)
                entity.id = translation.id
            }
            entity.originalText = translation.originalText
            entity.originalTextLangRaw = originalLangRaw
            entity.originalTextContext = translation.originalTextContext
            entity.translatedText = translation.translatedText
            entity.translatedTextLangRaw = translatedLangRaw
            
            updatedDomainTranslation = try Translation.fromCoreData(entity)
            try context.save()
        }
        
        guard let updatedDomainTranslation else {
            throw Error.failedConversionToDomainModel
        }
        
        return updatedDomainTranslation
    }

    public func delete(id: UUID) async throws {
        try await container.performBackgroundTask { context in
            guard let entity = try Self.fetchEntity(id: id, in: context) else {
                throw Error.notFound(id: id)
            }
            context.delete(entity)
            try context.save()
        }
    }

    public func clear() async throws {
        try await container.performBackgroundTask { context in
            let request = NSFetchRequest<CDCachedTranslation>(entityName: "CDCachedTranslation")
            for entity in try context.fetch(request) {
                context.delete(entity)
            }
            try context.save()
        }
    }

    /// Builds a maximal identifier string, inferring any of the three components if necessary.
    private static func identifier(for language: Locale.Language) -> String {
        language.maximalIdentifier
    }

    private static func matchingPredicate(
        originalText: String,
        originalLangRaw: String,
        originalTextContext: String?,
        translatedLangRaw: String
    ) -> NSPredicate {
        let contextPredicate = originalTextContext.map {
            NSPredicate(format: "originalTextContext ==[c] %@", $0)
        } ?? NSPredicate(format: "originalTextContext == nil")

        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "originalText ==[c] %@", originalText),
            NSPredicate(format: "originalTextLangRaw == %@", originalLangRaw),
            NSPredicate(format: "translatedTextLangRaw == %@", translatedLangRaw),
            contextPredicate,
        ])
    }

    private static func fetchEntity(id: UUID, in context: NSManagedObjectContext) throws -> CDCachedTranslation? {
        let request = NSFetchRequest<CDCachedTranslation>(entityName: "CDCachedTranslation")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
}
