//
//  Card.swift
//  KaifangSpacedRepetition
//
//  Created by Brendan Chen on 2026.06.03.
//

import Foundation

/// The scheduling state of a single card.
///
/// `Card` is a pure value type holding everything FSRS needs to compute the
/// next interval. It is deliberately storage-agnostic: the host app converts
/// between `Card` and its own persistence layer. All stored properties are
/// `public` and there is a full memberwise initializer so a host can both
/// build a card from persisted columns and read every field back out.
public struct Card: Sendable, Codable, Equatable {
    /// When the card is next due for review.
    public var due: Date

    /// Memory stability `S`: the number of days after which retrievability
    /// falls to the request-retention target (0.9 by default). `0` for a card
    /// that has never been reviewed.
    public var stability: Double

    /// Memory difficulty `D`, on a 1 (easiest) … 10 (hardest) scale. `0` for a
    /// card that has never been reviewed.
    public var difficulty: Double

    /// Position in the FSRS state machine.
    public var state: State

    /// Index into the active learning/relearning step list. Only meaningful
    /// while `state` is `.learning` or `.relearning`.
    public var step: Int

    /// Number of times the card has been reviewed.
    public var reps: Int

    /// Number of times the card has lapsed (rated Again while in `.review`).
    public var lapses: Int

    /// The whole-day interval the scheduler assigned at the most recent review.
    /// `0` for sub-day (re)learning steps and for never-scheduled cards.
    public var scheduledDays: Int

    /// When the card was last reviewed, or `nil` if never reviewed.
    public var lastReview: Date?

    /// Full memberwise initializer. Hosts converting from persistence supply
    /// every field; defaults describe a brand-new card.
    public init(
        due: Date,
        stability: Double = 0,
        difficulty: Double = 0,
        state: State = .new,
        step: Int = 0,
        reps: Int = 0,
        lapses: Int = 0,
        scheduledDays: Int = 0,
        lastReview: Date? = nil
    ) {
        self.due = due
        self.stability = stability
        self.difficulty = difficulty
        self.state = state
        self.step = step
        self.reps = reps
        self.lapses = lapses
        self.scheduledDays = scheduledDays
        self.lastReview = lastReview
    }

    /// A brand-new card, due immediately at `now`.
    public static func new(now: Date = Date()) -> Card {
        Card(due: now)
    }

    /// Whole UTC calendar days elapsed between the last review and `now`.
    ///
    /// FSRS measures elapsed time as the number of midnight-UTC boundaries
    /// crossed, not the raw seconds. A review at 23:00 UTC followed by one at
    /// 01:00 UTC the next day counts as one day even though only two hours
    /// passed. Returns `0` for new cards and clamps negative deltas to `0`.
    public func elapsedDays(now: Date) -> Int {
        guard let lastReview else { return 0 }
        let secondsPerDay = 86_400.0
        let last = (lastReview.timeIntervalSince1970 / secondsPerDay).rounded(.down)
        let current = (now.timeIntervalSince1970 / secondsPerDay).rounded(.down)
        return max(0, Int(current - last))
    }
}
