//
//  TranslationRepository+DataTypes.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.05.26.
//

import Foundation

public extension TranslationRepository {
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
