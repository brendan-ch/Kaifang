//
//  TranslationProvider+DataTypes.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.05.28.
//

import CoreData
import Foundation

public extension TranslationProvider {
    struct Translation: Equatable, Sendable {
        let id: UUID
        let originalText: String
        let originalTextLang: Locale.Language
        let originalTextContext: String?
        let translatedText: String
        let translatedTextLang: Locale.Language

        func withUpdatedTranslation(
            _ translatedText: String,
        ) -> Self {
            .init(
                id: id,
                originalText: originalText,
                originalTextLang: originalTextLang,
                originalTextContext: originalTextContext,
                translatedText: translatedText,
                translatedTextLang: translatedTextLang
            )
        }

        static func fromCoreData(_ entity: CDCachedTranslation) throws -> Self {
            let originalTextContext = entity.originalTextContext
            guard let id = entity.id,
                  let originalText = entity.originalText,
                  let originalLangRaw = entity.originalTextLangRaw,
                  let translatedText = entity.translatedText,
                  let translatedLangRaw = entity.translatedTextLangRaw else {
                throw TranslationRepository.Error.failedConversionToDomainModel
            }
            return Translation(
                id: id,
                originalText: originalText,
                originalTextLang: Locale.Language(identifier: originalLangRaw),
                originalTextContext: originalTextContext,
                translatedText: translatedText,
                translatedTextLang: Locale.Language(identifier: translatedLangRaw)
            )
        }
    }

    /// Arguments for looking up a translation without an ID.
    struct LookupArguments: Equatable, Sendable {
        let originalText: String
        let originalTextLang: Locale.Language
        let originalTextContext: String?
        let translatedTextLang: Locale.Language
    }
}
