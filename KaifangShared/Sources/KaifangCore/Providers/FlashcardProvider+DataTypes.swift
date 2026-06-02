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
