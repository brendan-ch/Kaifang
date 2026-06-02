//
//  FlashcardProvider+DataTypes.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.06.02.
//

import Foundation

public extension FlashcardProvider {
    /// Maps to ``CDFlashcard``.
    struct Flashcard {
        let id: UUID
        
        let dueDate: Date
        let easeFactor: Double
        let interval: Int32
        let lastReviewedAt: Date?
        let repetitions: Int32
        
        /// The sentence token from which the flashcard was saved.
        /// If the information exists, it can be used to link back to that token.
        let sentenceToken: SegmentationProvider.SentenceToken?
        
        let originalWord: String
        let originalContext: String?
        let wordTranslation: String?
        let contextTranslation: String?
        
        let dateCreated: Date
        let dateModified: Date
        
        static func fromCoreData(_ coreData: CDFlashcard) throws -> Self {
            guard let id = coreData.id,
                  let dueDate = coreData.dueDate,
                  let originalWord = coreData.originalWord,
                  let dateCreated = coreData.dateCreated,
                  let dateModified = coreData.dateModified else {
                throw Error.failedConversionToDomainModel
            }
            
            let sentenceToken: SegmentationProvider.SentenceToken?
            if let storedSentenceToken = coreData.sentenceToken {
                sentenceToken = try SegmentationProvider.SentenceToken.fromCoreData(storedSentenceToken)
            } else {
                sentenceToken = nil
            }
            
            return Flashcard(
                id: id,
                dueDate: dueDate,
                easeFactor: coreData.easeFactor,
                interval: coreData.interval,
                lastReviewedAt: coreData.lastReviewedAt,
                repetitions: coreData.repetitions,
                sentenceToken: sentenceToken,
                originalWord: originalWord,
                originalContext: coreData.originalContext,
                wordTranslation: coreData.wordTranslation,
                contextTranslation: coreData.contextTranslation,
                dateCreated: dateCreated,
                dateModified: dateModified
            )
        }
        
        static func fromCreateArgs(_ args: FlashcardCreateArguments) -> Self {
            return Flashcard(
                id: UUID(),
                dueDate: Date(),
                easeFactor: 2.5,
                interval: 0,
                lastReviewedAt: nil,
                repetitions: 0,
                sentenceToken: args.sentenceToken,
                originalWord: args.originalWord,
                originalContext: args.originalContext,
                wordTranslation: args.wordTranslation,
                contextTranslation: args.contextTranslation,
                dateCreated: Date(),
                dateModified: Date()
            )
        }
    }
    
    struct FlashcardCreateArguments {
        let originalWord: String
        let originalContext: String?
        let wordTranslation: String?
        let contextTranslation: String?
        let sentenceToken: SegmentationProvider.SentenceToken?
    }
    
    struct FilterArguments {
        /// When passed, only return flashcards for the given article.
        /// Returns an empty list if the article doesn't exist.
        let articleId: String?
        
        /// Filter to only flashcards that are due.
        let dueOnly: Bool?
        
        /// Filter by the contents of the flashcard (original word, context, translation + context translation).
        let contents: String?
    }
    
    enum SortCriteria: Hashable, Sendable {
        case dueDate(SortOrder)
        case dateModified(SortOrder)
        case dateCreated(SortOrder)
    }
    
    enum Error: Swift.Error, LocalizedError {
        case failedConversionToDomainModel
        
        public var errorDescription: String? {
            switch self {
            case .failedConversionToDomainModel:
                return "Unable to convert a Core Data entity to a domain model."
            }
        }
    }
}
