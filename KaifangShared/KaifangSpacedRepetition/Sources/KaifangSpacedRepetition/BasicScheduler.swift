//
//  BasicScheduler.swift
//  KaifangSpacedRepetition
//
//  Created by Brendan Chen on 2026.06.03.
//

import Foundation

/// The default scheduler: new and lapsed cards walk through sub-day learning
/// steps before graduating to day-scale FSRS intervals.
///
/// Per-rating step behaviour:
/// - **Again** restarts at step 0.
/// - **Hard** repeats the current step using a step-independent duration.
/// - **Good** advances one step, graduating when the steps run out.
/// - **Easy** graduates immediately.
struct BasicScheduler: Sendable {
    let algorithm: FSRSAlgorithm
    let parameters: FSRSParameters

    func schedule(card: Card, now: Date) -> RecordLog {
        switch card.state {
        case .new, .learning:
            return steppedSchedule(card: card, now: now,
                                   steps: parameters.learningSteps, learningState: .learning)
        case .relearning:
            return steppedSchedule(card: card, now: now,
                                   steps: parameters.relearningSteps, learningState: .relearning)
        case .review:
            return reviewSchedule(card: card, now: now)
        }
    }

    // MARK: New / Learning / Relearning

    /// Shared logic for the three "stepped" states. A new card has `step == 0`,
    /// so it follows the same branches as a learning card on step 0.
    private func steppedSchedule(
        card: Card, now: Date, steps: [TimeInterval], learningState: State
    ) -> RecordLog {
        let elapsed = card.elapsedDays(now: now)

        func outcome(_ rating: Rating) -> RecordLogItem {
            let (newS, newD) = algorithm.nextState(
                stability: card.stability, difficulty: card.difficulty,
                elapsed: elapsed, rating: rating
            )
            var updated = card
            updated.stability = newS
            updated.difficulty = newD
            updated.reps += 1
            updated.lastReview = now

            switch rating {
            case .again:
                applyStep(0, steps: steps, to: &updated, now: now, learningState: learningState)
            case .hard:
                applyHard(currentStep: card.step, steps: steps, stability: newS,
                          to: &updated, now: now, learningState: learningState)
            case .good:
                applyStep(card.step + 1, steps: steps, to: &updated, now: now, learningState: learningState)
            case .easy:
                graduate(&updated, stability: newS, now: now)
            }

            return RecordLogItem(card: updated, log: makeLog(rating: rating, card: card, elapsed: elapsed, now: now))
        }

        return buildLog(outcome)
    }

    // MARK: Review

    private func reviewSchedule(card: Card, now: Date) -> RecordLog {
        let elapsed = card.elapsedDays(now: now)

        var memory: [Rating: (stability: Double, difficulty: Double)] = [:]
        for rating in Rating.allCases {
            memory[rating] = algorithm.nextState(
                stability: card.stability, difficulty: card.difficulty,
                elapsed: elapsed, rating: rating
            )
        }

        // Order the passing intervals so Hard < Good < Easy. Cap Hard at Good
        // first, then push Good past Hard — the reverse would let Hard climb
        // arbitrarily high.
        var hardInterval = algorithm.interval(stability: memory[.hard]!.stability)
        var goodInterval = algorithm.interval(stability: memory[.good]!.stability)
        hardInterval = min(hardInterval, goodInterval)
        goodInterval = max(goodInterval, hardInterval + 1)
        let easyInterval = max(algorithm.interval(stability: memory[.easy]!.stability), goodInterval + 1)

        var intervals: [Rating: Int] = [.hard: hardInterval, .good: goodInterval, .easy: easyInterval]
        if parameters.enableFuzz {
            let seed = fuzzSeed(card: card, now: now)
            for rating: Rating in [.hard, .good, .easy] {
                intervals[rating] = IntervalFuzzer.fuzz(
                    interval: intervals[rating]!, elapsedDays: elapsed,
                    maximumInterval: parameters.maximumInterval, seed: seed
                )
            }
        }

        func outcome(_ rating: Rating) -> RecordLogItem {
            let (newS, newD) = memory[rating]!
            var updated = card
            updated.stability = newS
            updated.difficulty = newD
            updated.reps += 1
            updated.lastReview = now

            if rating == .again {
                updated.lapses += 1
                if parameters.relearningSteps.isEmpty {
                    let interval = algorithm.interval(stability: newS)
                    updated.state = .review
                    updated.step = 0
                    updated.scheduledDays = interval
                    updated.due = now.addingTimeInterval(Double(interval) * 86_400.0)
                } else {
                    updated.state = .relearning
                    updated.step = 0
                    updated.scheduledDays = 0
                    updated.due = now.addingTimeInterval(parameters.relearningSteps[0])
                }
            } else {
                let interval = intervals[rating]!
                updated.state = .review
                updated.step = 0
                updated.scheduledDays = interval
                updated.due = now.addingTimeInterval(Double(interval) * 86_400.0)
            }

            return RecordLogItem(card: updated, log: makeLog(rating: rating, card: card, elapsed: elapsed, now: now))
        }

        return buildLog(outcome)
    }

    // MARK: Step helpers

    /// Schedules `targetStep`, or graduates if the steps are exhausted.
    private func applyStep(
        _ targetStep: Int, steps: [TimeInterval], to card: inout Card, now: Date, learningState: State
    ) {
        if steps.isEmpty || targetStep >= steps.count {
            graduate(&card, stability: card.stability, now: now)
        } else {
            applyDuration(steps[targetStep], targetStep: targetStep, to: &card, now: now, learningState: learningState)
        }
    }

    /// Schedules Hard, which stays on the current step but uses a
    /// step-independent duration. Graduates if the current step is out of range.
    private func applyHard(
        currentStep: Int, steps: [TimeInterval], stability: Double,
        to card: inout Card, now: Date, learningState: State
    ) {
        if steps.isEmpty || currentStep >= steps.count {
            graduate(&card, stability: stability, now: now)
        } else {
            applyDuration(hardDurationSeconds(steps: steps), targetStep: currentStep,
                          to: &card, now: now, learningState: learningState)
        }
    }

    /// Applies a raw step duration. A duration of a day or more routes the card
    /// to `.review` (keeping its step index) on a whole-day schedule; a sub-day
    /// duration keeps it in the learning/relearning state with no day schedule.
    private func applyDuration(
        _ duration: TimeInterval, targetStep: Int, to card: inout Card, now: Date, learningState: State
    ) {
        if duration >= 86_400 {
            card.state = .review
            card.step = targetStep
            card.scheduledDays = Int((duration / 86_400.0).rounded(.down))
            card.due = now.addingTimeInterval(duration)
        } else {
            card.state = learningState
            card.step = targetStep
            card.scheduledDays = 0
            card.due = now.addingTimeInterval(duration)
        }
    }

    /// The step-independent Hard duration: the rounded average of the first two
    /// steps, or `round(step0 × 1.5)` for a single-step configuration.
    private func hardDurationSeconds(steps: [TimeInterval]) -> TimeInterval {
        guard !steps.isEmpty else { return 0 }
        if steps.count == 1 {
            let minutes = steps[0] / 60.0
            return (minutes * 1.5).rounded(.toNearestOrAwayFromZero) * 60.0
        }
        let first = steps[0] / 60.0
        let second = steps[1] / 60.0
        return ((first + second) / 2.0).rounded(.toNearestOrAwayFromZero) * 60.0
    }

    /// Moves a card to `.review` with an FSRS-computed interval.
    private func graduate(_ card: inout Card, stability: Double, now: Date) {
        let interval = algorithm.interval(stability: stability)
        card.state = .review
        card.step = 0
        card.scheduledDays = interval
        card.due = now.addingTimeInterval(Double(interval) * 86_400.0)
    }

    // MARK: Shared

    private func fuzzSeed(card: Card, now: Date) -> String {
        let milliseconds = Int(now.timeIntervalSince1970 * 1000)
        return "\(milliseconds)_\(card.reps + 1)_\(card.difficulty * card.stability)"
    }

    private func makeLog(rating: Rating, card: Card, elapsed: Int, now: Date) -> ReviewLog {
        ReviewLog(
            rating: rating, state: card.state,
            stability: card.stability, difficulty: card.difficulty,
            elapsedDays: elapsed, scheduledDays: card.scheduledDays,
            reviewedAt: now, previousDue: card.due,
            previousLastReview: card.lastReview, previousStep: card.step
        )
    }

    private func buildLog(_ outcome: (Rating) -> RecordLogItem) -> RecordLog {
        [.again: outcome(.again), .hard: outcome(.hard), .good: outcome(.good), .easy: outcome(.easy)]
    }
}
