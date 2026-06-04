//
//  FlashcardProvider+FSRS.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.06.03.
//
//  Bridges the persisted Kaifang flashcard types to the FSRS engine in
//  KaifangSpacedRepetition. The engine owns the algorithm and the `Card` /
//  `ReviewLog` models; KaifangShared keeps `Flashcard` (which couples to
//  article tokens and locales) and converts to/from the engine's value types.
//

import Foundation
import KaifangSpacedRepetition

// MARK: - Enum bridges

extension FlashcardProvider.ReviewState {
    /// The engine state with the same raw value.
    var fsrsState: State { State(rawValue: rawValue) ?? .new }

    init(_ state: State) {
        self = FlashcardProvider.ReviewState(rawValue: state.rawValue) ?? .new
    }
}

extension FlashcardProvider.ReviewRating {
    /// The engine grade with the same raw value (both are one-based).
    var fsrsRating: Rating { Rating(rawValue: rawValue) ?? .again }

    init(_ rating: Rating) {
        self = FlashcardProvider.ReviewRating(rawValue: rating.rawValue) ?? .again
    }
}

// MARK: - Metadata ⇄ Card

extension FlashcardProvider.SpacedRepetitionMetadata {
    /// Projects the persisted metadata into an FSRS ``Card`` for scheduling.
    var fsrsCard: Card {
        Card(
            due: due,
            stability: stability ?? 0,
            difficulty: difficulty ?? 0,
            state: reviewState.fsrsState,
            step: Int(learningStep),
            reps: Int(repetitions),
            lapses: Int(lapses),
            scheduledDays: Int(scheduledDays),
            lastReview: lastReviewedAt
        )
    }

    /// Rebuilds metadata from a scheduled FSRS ``Card``.
    init(fsrsCard card: Card) {
        self.init(
            due: card.due,
            lastReviewedAt: card.lastReview,
            reviewState: FlashcardProvider.ReviewState(card.state),
            stability: card.stability,
            difficulty: card.difficulty,
            repetitions: Int32(card.reps),
            lapses: Int32(card.lapses),
            scheduledDays: Int32(card.scheduledDays),
            learningStep: Int32(card.step)
        )
    }
}

// MARK: - ReviewLog → FlashcardReview

extension FlashcardProvider.FlashcardReview {
    /// Builds a persistable review record from an engine ``ReviewLog``,
    /// attaching the Kaifang-only fields (`flashcardUUID`, `reviewDurationMs`)
    /// the engine doesn't model.
    init(from log: ReviewLog, flashcardUUID: UUID, reviewDurationMs: Int32 = 0) {
        self.init(
            id: UUID(),
            flashcardUUID: flashcardUUID,
            reviewedAt: log.reviewedAt,
            difficultyBefore: log.difficulty,
            stabilityBefore: log.stability,
            stateBefore: FlashcardProvider.ReviewState(log.state),
            rating: FlashcardProvider.ReviewRating(log.rating),
            elapsedDays: Double(log.elapsedDays),
            scheduledDays: Double(log.scheduledDays),
            reviewDurationMs: reviewDurationMs
        )
    }
}

// MARK: - Flashcard review transformation

extension FlashcardProvider.Flashcard {
    /// Applies a review grade, returning a new flashcard with updated
    /// scheduling metadata alongside the review log that produced it.
    ///
    /// Immutable: the receiver is unchanged. The host persists the returned
    /// flashcard and appends the review to the replay log.
    func reviewed(
        rating: FlashcardProvider.ReviewRating,
        now: Date = Date(),
        using fsrs: FSRS = FSRS(),
        reviewDurationMs: Int32 = 0
    ) -> (flashcard: Self, review: FlashcardProvider.FlashcardReview) {
        let item = fsrs.next(card: spacedRepetitionMetadata.fsrsCard, now: now, grade: rating.fsrsRating)
        let updated = applying(
            metadata: FlashcardProvider.SpacedRepetitionMetadata(fsrsCard: item.card),
            modifiedAt: now
        )
        let review = FlashcardProvider.FlashcardReview(
            from: item.log, flashcardUUID: id, reviewDurationMs: reviewDurationMs
        )
        return (updated, review)
    }

    /// Returns a copy with new scheduling metadata and an updated
    /// modification date, leaving every other field intact.
    func applying(
        metadata: FlashcardProvider.SpacedRepetitionMetadata,
        modifiedAt: Date
    ) -> Self {
        FlashcardProvider.Flashcard(
            id: id,
            spacedRepetitionMetadata: metadata,
            sentenceToken: sentenceToken,
            originalText: originalText,
            originalTextContext: originalTextContext,
            originalTextLang: originalTextLang,
            translatedTextLang: translatedTextLang,
            dateCreated: dateCreated,
            dateModified: modifiedAt
        )
    }
}
