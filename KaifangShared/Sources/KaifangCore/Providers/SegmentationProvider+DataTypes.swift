//
//  SegmentationProvider+DataTypes.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.05.29.
//

import CoreData
import Foundation

public extension SegmentationProvider {
    enum Error: Swift.Error, LocalizedError {
        case failedConversionToDomainModel

        public var errorDescription: String? {
            switch self {
            case .failedConversionToDomainModel:
                return "Unable to convert a Core Data entity to a domain model."
            }
        }
    }

    /// Maps to ``CDArticleWordToken``.
    struct WordToken: Equatable, Sendable {
        let id: UUID
        let tokenText: String
        let sentenceTextPositionStart: Int32
        let wordIndexInSentence: Int32

        static func fromCoreData(_ coreData: CDArticleWordToken) throws -> Self {
            guard let id = coreData.id,
                  let tokenText = coreData.tokenText else {
                throw Error.failedConversionToDomainModel
            }
            return WordToken(
                id: id,
                tokenText: tokenText,
                sentenceTextPositionStart: coreData.sentenceTextPositionStart,
                wordIndexInSentence: coreData.wordIndexInSentence
            )
        }
    }

    /// Maps to ``CDArticleSentenceToken``.
    struct SentenceToken: Equatable, Sendable {
        let id: UUID
        let articleTextPositionStart: Int32
        let sentenceIndexInArticle: Int32
        let tokenText: String

        let wordTokens: [WordToken]

        static func fromCoreData(_ coreData: CDArticleSentenceToken) throws -> Self {
            guard let id = coreData.id,
                  let tokenText = coreData.tokenText else {
                throw Error.failedConversionToDomainModel
            }

            let wordsRelationship = coreData.words ?? NSSet()
            guard let wordEntities = wordsRelationship as? Set<CDArticleWordToken> else {
                throw Error.failedConversionToDomainModel
            }
            let wordTokens = try wordEntities
                .map(WordToken.fromCoreData)
                .sorted { $0.wordIndexInSentence < $1.wordIndexInSentence }

            return SentenceToken(
                id: id,
                articleTextPositionStart: coreData.articleTextPositionStart,
                sentenceIndexInArticle: coreData.sentenceIndexInArticle,
                tokenText: tokenText,
                wordTokens: wordTokens
            )
        }
    }
}
