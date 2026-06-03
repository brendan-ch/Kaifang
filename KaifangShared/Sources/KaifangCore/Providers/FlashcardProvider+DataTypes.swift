//
//  FlashcardProvider+DataTypes.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.06.02.
//

import Foundation

public extension FlashcardProvider {
    /// Maps to ``CDFlashcard``.
    struct Flashcard: Equatable, Sendable {
        // MARK: Properties
        let id: UUID
        
        let dueDate: Date
        let easeFactor: Double
        let interval: Int32
        let lastReviewedAt: Date?
        let repetitions: Int32
        
        /// The sentence token from which the flashcard was saved.
        /// If the information exists, it can be used to link back to that token.
        let sentenceToken: SegmentationProvider.SentenceToken?
        
        // map to translation lookup arguments
        let originalText: String
        let originalTextContext: String?
        let originalTextLang: Locale.Language
        let translatedTextLang: Locale.Language
        
        let dateCreated: Date
        let dateModified: Date
        
        // MARK: Creation
        
        static func fromCoreData(_ coreData: CDFlashcard) throws -> Self {
            guard let id = coreData.id,
                  let dueDate = coreData.dueDate,
                  let originalWord = coreData.originalWord,
                  let dateCreated = coreData.dateCreated,
                  let dateModified = coreData.dateModified,
                  let originalTextLangRaw = coreData.originalTextLangRaw,
                  let translatedTextLangRaw = coreData.translatedTextLangRaw else {
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
                originalText: originalWord,
                originalTextContext: coreData.originalContext,
                originalTextLang: Locale.Language(identifier: originalTextLangRaw),
                translatedTextLang: Locale.Language(identifier: translatedTextLangRaw),
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
                originalText: args.originalWord,
                originalTextContext: args.originalContext,
                originalTextLang: args.originalTextLang,
                translatedTextLang: args.translatedTextLang,
                dateCreated: Date(),
                dateModified: Date()
            )
        }
        
        // MARK: Transformations
        
        func reviewed(option: ReviewOption) -> Self {
            // apply the spaced repetition algorithm
            return self
        }
        
    }
    
    struct FlashcardCreateArguments: Sendable {
        let originalWord: String
        let originalContext: String?
        let originalTextLang: Locale.Language
        let translatedTextLang: Locale.Language
        let sentenceToken: SegmentationProvider.SentenceToken?
    }
    
    struct FilterArguments: Sendable {
        /// When passed, only return flashcards for the given article.
        /// Returns an empty list if the article doesn't exist.
        let articleId: UUID?
        
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
    
    enum ReviewOption: Sendable {
        case again
        case hard
        case good
        case easy
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
