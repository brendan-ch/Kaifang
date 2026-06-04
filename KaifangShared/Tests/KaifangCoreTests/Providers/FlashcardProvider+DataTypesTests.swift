//
//  FlashcardProvider+DataTypesTests.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.06.02.
//

import Testing
@testable import KaifangCore
import KaifangSpacedRepetition
import CoreData
import Foundation

@Suite(.serialized)
struct FlashcardTests {
    // MARK: Type aliases
    typealias Flashcard = FlashcardProvider.Flashcard
    typealias ReviewRating = FlashcardProvider.ReviewRating
    typealias ReviewState = FlashcardProvider.ReviewState
    typealias SpacedRepetitionMetadata = FlashcardProvider.SpacedRepetitionMetadata
    typealias CreateArguments = FlashcardProvider.FlashcardCreateArguments

    // MARK: Setup

    private let context: NSManagedObjectContext

    init() throws {
        context = try PersistenceController.getTestingContext()
    }

    private func makeNewFlashcard() -> Flashcard {
        Flashcard.fromCreateArgs(
            CreateArguments(
                originalWord: "你好",
                originalContext: "你好世界",
                originalTextLang: Locale.Language(identifier: "zh"),
                translatedTextLang: Locale.Language(identifier: "en"),
                sentenceToken: nil
            )
        )
    }

    // MARK: Transformation tests

    @Test(
        "Marking the flashcard as reviewed returns a new flashcard with updated metadata",
        arguments: [ReviewRating.again, .hard, .good, .easy]
    )
    func markingFlashcardAsReviewedReturnsFlashcardWithUpdatedMetadata(
        case rating: ReviewRating
    ) async throws {
        let original = makeNewFlashcard()
        let now = Date()

        let (updated, review) = original.reviewed(rating: rating, now: now)

        // The original is untouched (value semantics).
        #expect(original.spacedRepetitionMetadata.repetitions == 0)
        #expect(original.spacedRepetitionMetadata.reviewState == .new)

        // The updated card advanced exactly one review.
        #expect(updated.id == original.id)
        #expect(updated.spacedRepetitionMetadata.repetitions == 1)
        #expect(updated.dateModified == now)
        #expect(updated.spacedRepetitionMetadata.due > now)
        // Stability and difficulty are populated after the first review.
        #expect((updated.spacedRepetitionMetadata.stability ?? 0) > 0)
        #expect((updated.spacedRepetitionMetadata.difficulty ?? 0) > 0)

        // State transition for a new card under the default (short-term) scheduler.
        let expectedState: ReviewState = rating == .easy ? .review : .learning
        #expect(updated.spacedRepetitionMetadata.reviewState == expectedState)

        // The review log records the pre-review snapshot.
        #expect(review.flashcardUUID == original.id)
        #expect(review.rating == rating)
        #expect(review.stateBefore == .new)
        #expect(review.reviewedAt == now)
    }

    @Test("ReviewRating is one-based and bridges to the engine Rating by identity")
    func reviewRatingMatchesEngineRating() throws {
        #expect(ReviewRating.again.rawValue == 1)
        #expect(ReviewRating.hard.rawValue == 2)
        #expect(ReviewRating.good.rawValue == 3)
        #expect(ReviewRating.easy.rawValue == 4)

        for rating in [ReviewRating.again, .hard, .good, .easy] {
            #expect(rating.fsrsRating.rawValue == rating.rawValue)
            #expect(FlashcardProvider.ReviewRating(rating.fsrsRating) == rating)
        }
        // ReviewState bridges by identity too (both zero-based).
        for state in [ReviewState.new, .learning, .review, .relearning] {
            #expect(state.fsrsState.rawValue == state.rawValue)
            #expect(FlashcardProvider.ReviewState(state.fsrsState) == state)
        }
    }

    @Test("Metadata round-trips through the FSRS card representation")
    func metadataRoundTripsThroughCard() throws {
        let metadata = SpacedRepetitionMetadata(
            due: Date(timeIntervalSince1970: 1_700_000_000),
            lastReviewedAt: Date(timeIntervalSince1970: 1_699_000_000),
            reviewState: .review,
            stability: 12.5,
            difficulty: 6.25,
            repetitions: 7,
            lapses: 2,
            scheduledDays: 13,
            learningStep: 0
        )

        let card = metadata.fsrsCard
        #expect(card.due == metadata.due)
        #expect(card.lastReview == metadata.lastReviewedAt)
        #expect(card.state == .review)
        #expect(card.stability == 12.5)
        #expect(card.difficulty == 6.25)
        #expect(card.reps == 7)
        #expect(card.lapses == 2)
        #expect(card.scheduledDays == 13)
        #expect(card.step == 0)

        #expect(SpacedRepetitionMetadata(fsrsCard: card) == metadata)
    }

    @Test("Reviewing then persisting and re-reading round-trips through Core Data")
    func reviewPersistsLosslesslyThroughCoreData() throws {
        let original = makeNewFlashcard()
        let now = Date()
        let (reviewed, _) = original.reviewed(rating: .good, now: now)

        // Write the reviewed card's scheduling fields onto a CDFlashcard.
        let entity = CDFlashcard(context: context)
        let metadata = reviewed.spacedRepetitionMetadata
        entity.id = reviewed.id
        entity.originalWord = reviewed.originalText
        entity.originalTextLangRaw = reviewed.originalTextLang.minimalIdentifier
        entity.translatedTextLangRaw = reviewed.translatedTextLang.minimalIdentifier
        entity.dateCreated = reviewed.dateCreated
        entity.dateModified = reviewed.dateModified
        entity.due = metadata.due
        entity.lastReviewedAt = metadata.lastReviewedAt
        entity.reviewStateRaw = Int16(metadata.reviewState.rawValue)
        entity.stability = metadata.stability ?? 0
        entity.difficulty = metadata.difficulty ?? 0
        entity.repetitions = metadata.repetitions
        entity.lapses = metadata.lapses
        entity.scheduledDays = metadata.scheduledDays
        entity.learningStepIndex = Int16(metadata.learningStep)

        // Read it back; the scheduling metadata must survive the round-trip.
        let restored = try Flashcard.fromCoreData(entity)
        #expect(restored.spacedRepetitionMetadata == metadata)
        #expect(restored.spacedRepetitionMetadata.fsrsCard == reviewed.spacedRepetitionMetadata.fsrsCard)
    }
}
