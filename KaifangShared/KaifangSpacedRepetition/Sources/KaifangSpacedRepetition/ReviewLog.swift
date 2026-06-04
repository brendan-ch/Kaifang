//
//  ReviewLog.swift
//  KaifangSpacedRepetition
//
//  Created by Brendan Chen on 2026.06.03.
//

import Foundation

/// An immutable record of one review, capturing the card's state *before* the
/// review was applied.
///
/// Storing the pre-review snapshot lets the host both (a) persist a faithful
/// review history for later analysis or optimizer training and (b) undo the
/// review via ``FSRS/rollback(card:log:)``. The `previous*` fields carry the
/// extra bits rollback needs that aren't otherwise recoverable from the card.
public struct ReviewLog: Sendable, Codable, Equatable {
    /// The grade applied at this review.
    public let rating: Rating

    /// The card's state immediately before the review.
    public let state: State

    /// The card's stability before the review.
    public let stability: Double

    /// The card's difficulty before the review.
    public let difficulty: Double

    /// Whole UTC days elapsed since the previous review (see
    /// ``Card/elapsedDays(now:)``).
    public let elapsedDays: Int

    /// The interval (in whole days) the card was carrying before this review.
    public let scheduledDays: Int

    /// When this review happened.
    public let reviewedAt: Date

    /// The card's `due` before the review. Lets rollback restore the original
    /// due date for cards that were `.new` (no review timeline to wait from).
    public let previousDue: Date

    /// The card's `lastReview` before the review (`nil` if it was `.new`).
    public let previousLastReview: Date?

    /// The card's `step` before the review.
    public let previousStep: Int

    public init(
        rating: Rating,
        state: State,
        stability: Double,
        difficulty: Double,
        elapsedDays: Int,
        scheduledDays: Int,
        reviewedAt: Date,
        previousDue: Date,
        previousLastReview: Date?,
        previousStep: Int
    ) {
        self.rating = rating
        self.state = state
        self.stability = stability
        self.difficulty = difficulty
        self.elapsedDays = elapsedDays
        self.scheduledDays = scheduledDays
        self.reviewedAt = reviewedAt
        self.previousDue = previousDue
        self.previousLastReview = previousLastReview
        self.previousStep = previousStep
    }
}
