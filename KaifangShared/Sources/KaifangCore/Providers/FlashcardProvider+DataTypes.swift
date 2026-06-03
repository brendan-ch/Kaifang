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
        let spacedRepetitionMetadata: SpacedRepetitionMetadata

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
                  let due = coreData.due,
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
                spacedRepetitionMetadata: .init(
                    due: due,
                    lastReviewedAt: coreData.lastReviewedAt,
                    reviewState: ReviewState(rawValue: Int(coreData.reviewStateRaw)) ?? .new,
                    stability: coreData.stability,
                    difficulty: coreData.difficulty,
                    repetitions: coreData.repetitions,
                    lapses: coreData.lapses
                ),
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
                spacedRepetitionMetadata: .init(
                    due: Date(),
                    lastReviewedAt: nil,
                    reviewState: .new,
                    stability: nil,
                    difficulty: nil,
                    repetitions: 0,
                    lapses: 0
                ),
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
        
        func reviewed(option: ReviewRating) -> Self {
            // apply the spaced repetition algorithm
            return self
        }
        
    }
    
    /// Maps to ``CDFlashcardReview``.
    /// Tracks properties for a deterministic replay of all flashcard reviews.
    struct FlashcardReview {
        // MARK: Properties
        let id: UUID
        let flashcardUUID: UUID
        
        let reviewedAt: Date
        let difficultyBefore: Double
        let stabilityBefore: Double
        let stateBefore: ReviewState
        let rating: ReviewRating
        let elapsedDays: Double
        let scheduledDays: Double
        let reviewDurationMs: Int32
        
        static func fromCoreData(_ coreData: CDFlashcardReview) throws -> Self {
            guard let id = coreData.id,
                  let reviewedAt = coreData.reviewedAt,
                  let stateBefore = ReviewState(rawValue: Int(coreData.stateBeforeRaw)),
                  let rating = ReviewRating(rawValue: Int(coreData.ratingRaw)),
                  let flashcardUUID = coreData.flashcardUUID else {
                throw Error.failedConversionToDomainModel
            }
            
            return FlashcardReview(
                id: id,
                flashcardUUID: flashcardUUID,
                reviewedAt: reviewedAt,
                difficultyBefore: coreData.difficultyBefore,
                stabilityBefore: coreData.stabilityBefore,
                stateBefore: stateBefore,
                rating: rating,
                elapsedDays: coreData.elapsedDays,
                scheduledDays: coreData.scheduledDays,
                reviewDurationMs: coreData.reviewDurationMs
            )
        }
    }
    
    struct SpacedRepetitionMetadata: Equatable, Sendable {
        let due: Date
        let lastReviewedAt: Date?
        let reviewState: ReviewState
        let stability: Double?
        let difficulty: Double?
        let repetitions: Int32
        let lapses: Int32
    }
    
    enum ReviewState: Int, Sendable {
        case new
        case learning
        case review
        case relearning
    }
    

    enum ReviewRating: Int {
        case again
        case hard
        case good
        case easy
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
