//
//  TranslationRepository+DataTypes.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.05.26.
//

import Foundation

public extension TranslationRepository {
    struct Translation: Equatable, Sendable {
        let id: UUID
        let originalText: String
        let originalTextLang: Locale.Language
        let translatedText: String
        let translatedTextLang: Locale.Language
        
        func withUpdatedTranslation(
            _ translatedText: String,
        ) -> Self {
            .init(
                id: id,
                originalText: originalText,
                originalTextLang: originalTextLang,
                translatedText: translatedText,
                translatedTextLang: translatedTextLang
            )
        }
        
        static func fromCoreData(_ entity: CDCachedTranslation) throws -> Self {
            guard let id = entity.id,
                  let originalText = entity.originalText,
                  let originalLangRaw = entity.originalTextLangRaw,
                  let translatedText = entity.translatedText,
                  let translatedLangRaw = entity.translatedTextLangRaw else {
                throw Error.failedConversionToDomainModel
            }
            return Translation(
                id: id,
                originalText: originalText,
                originalTextLang: Locale.Language(identifier: originalLangRaw),
                translatedText: translatedText,
                translatedTextLang: Locale.Language(identifier: translatedLangRaw)
            )

        }
    }
    
    /// Arguments for looking up a translation without an ID.
    struct LookupArguments: Equatable, Sendable {
        let originalText: String
        let originalTextLang: Locale.Language
        let translatedTextLang: Locale.Language
    }
    
    enum Error: LocalizedError, Equatable {
        case notFound(id: UUID)
        case duplicateOriginalTextAndLang(id: UUID)
        case failedConversionToDomainModel
        
        public var errorDescription: String? {
            switch self {
            case .notFound(let id):
                "We couldn't find the translation (ID: \(id))."
            case .duplicateOriginalTextAndLang(let id):
                "A translation already exists for this text and language combination (ID: \(id))."
            case .failedConversionToDomainModel:
                "Unable to convert a Core Data entity to a domain model."
            }
        }
    }
}
