//
//  FSRS.swift
//  KaifangSpacedRepetition
//
//  Created by Brendan Chen on 2026.06.03.
//

import Foundation

/// The FSRS-6 spaced-repetition scheduler.
///
/// Build one from ``FSRSParameters`` (or accept the defaults) and reuse it:
/// `FSRS` is an immutable value type. Preview all four outcomes for a card with
/// ``repeat(card:now:)``, or commit a single grade with ``next(card:now:grade:)``.
///
/// ```swift
/// let fsrs = FSRS()
/// var card = FSRS.newCard()
/// let item = fsrs.next(card: card, now: Date(), grade: .good)
/// card = item.card           // card.due is when to show it next
/// ```
public struct FSRS: Sendable {

    /// The parameters backing this scheduler.
    public let parameters: FSRSParameters

    private let algorithm: FSRSAlgorithm

    /// Creates a scheduler. Uses FSRS-6 defaults when no parameters are given.
    public init(parameters: FSRSParameters = FSRSParameters()) {
        self.parameters = parameters
        self.algorithm = FSRSAlgorithm(parameters: parameters)
    }

    /// A brand-new card, due immediately at `now`.
    public static func newCard(now: Date = Date()) -> Card {
        Card.new(now: now)
    }

    // MARK: Scheduling

    /// Computes the outcome for every grade without committing to one.
    ///
    /// Use the returned ``RecordLog`` to show the next due date for each button
    /// before the learner chooses. Every grade is present.
    public func `repeat`(card: Card, now: Date = Date()) -> RecordLog {
        if parameters.enableShortTerm {
            BasicScheduler(algorithm: algorithm, parameters: parameters).schedule(card: card, now: now)
        } else {
            LongTermScheduler(algorithm: algorithm, parameters: parameters).schedule(card: card, now: now)
        }
    }

    /// Commits a single grade and returns the updated card plus its review log.
    public func next(card: Card, now: Date = Date(), grade: Rating) -> RecordLogItem {
        // Every grade is always present in the record, so this is total.
        self.repeat(card: card, now: now)[grade]!
    }

    // MARK: Retrievability

    /// The estimated probability the learner can recall the card at `now`.
    /// Returns `0` for never-reviewed cards.
    public func retrievability(of card: Card, now: Date = Date()) -> Double {
        guard card.state != .new, card.stability >= FSRSAlgorithm.minStability else { return 0 }
        let elapsed = card.elapsedDays(now: now)
        return algorithm.retrievability(elapsed: Double(elapsed), stability: card.stability)
    }

    // MARK: Undo

    /// Reverses a review, restoring the card to its pre-review state using the
    /// snapshot stored in `log`. Implements an "undo" for a mis-tap.
    ///
    /// `reps` is decremented (clamped at zero). `lapses` is only decremented
    /// when the review being undone was an Again on a `.review` card — the only
    /// case in which a lapse was counted.
    public func rollback(card: Card, log: ReviewLog) -> Card {
        var rolled = card
        rolled.state = log.state
        rolled.stability = log.stability
        rolled.difficulty = log.difficulty
        rolled.scheduledDays = log.scheduledDays
        rolled.step = log.previousStep
        rolled.reps = max(0, card.reps - 1)

        if log.state == .new {
            rolled.due = log.previousDue
            rolled.lastReview = nil
            rolled.lapses = 0
        } else {
            rolled.due = log.reviewedAt
            rolled.lastReview = log.previousLastReview
            let didLapse = log.rating == .again && log.state == .review
            rolled.lapses = max(0, card.lapses - (didLapse ? 1 : 0))
        }
        return rolled
    }

    // MARK: Reset

    /// Resets a card to `.new` with zeroed stability/difficulty and an
    /// immediate due date, returning it alongside an audit log entry.
    ///
    /// `lastReview` is preserved so the card keeps its history timestamp. By
    /// default `reps` and `lapses` survive; pass `resetCount: true` to clear
    /// them. The audit log uses ``Rating/again`` as a stand-in (FSRS's "manual"
    /// grade isn't modelled here), so it is **not** safe input to
    /// ``rollback(card:log:)``.
    public func forget(card: Card, now: Date = Date(), resetCount: Bool = false) -> RecordLogItem {
        let scheduledDaysAtForget: Int
        if card.state == .new {
            scheduledDaysAtForget = 0
        } else {
            let secondsPerDay = 86_400.0
            let dueDay = (card.due.timeIntervalSince1970 / secondsPerDay).rounded(.down)
            let nowDay = (now.timeIntervalSince1970 / secondsPerDay).rounded(.down)
            scheduledDaysAtForget = max(0, Int(nowDay - dueDay))
        }

        var forgotten = card
        forgotten.due = now
        forgotten.stability = 0
        forgotten.difficulty = 0
        forgotten.scheduledDays = 0
        forgotten.step = 0
        forgotten.state = .new
        if resetCount {
            forgotten.reps = 0
            forgotten.lapses = 0
        }
        // lastReview is intentionally preserved.

        let log = ReviewLog(
            rating: .again, state: card.state,
            stability: card.stability, difficulty: card.difficulty,
            elapsedDays: 0, scheduledDays: scheduledDaysAtForget,
            reviewedAt: now, previousDue: card.due,
            previousLastReview: card.lastReview, previousStep: card.step
        )
        return RecordLogItem(card: forgotten, log: log)
    }
}
