//
//  LongTermScheduler.swift
//  KaifangSpacedRepetition
//
//  Created by Brendan Chen on 2026.06.03.
//

import Foundation

/// A scheduler with no learning steps: every review, from any state, lands the
/// card directly in `.review` with an FSRS-computed whole-day interval.
///
/// Used when ``FSRSParameters/enableShortTerm`` is `false`. Produces longer
/// initial intervals than ``BasicScheduler`` because there is no sub-day warmup.
struct LongTermScheduler: Sendable {
    let algorithm: FSRSAlgorithm
    let parameters: FSRSParameters

    func schedule(card: Card, now: Date) -> RecordLog {
        let elapsed = card.elapsedDays(now: now)

        var memory: [Rating: (stability: Double, difficulty: Double)] = [:]
        var intervals: [Rating: Int] = [:]
        for rating in Rating.allCases {
            let state = algorithm.nextState(
                stability: card.stability, difficulty: card.difficulty,
                elapsed: elapsed, rating: rating
            )
            memory[rating] = state
            intervals[rating] = algorithm.interval(stability: state.stability)
        }

        // Strict ordering again < hard < good < easy: cap Again at Hard first,
        // then push each higher grade at least one day past the previous.
        var againInterval = intervals[.again]!
        var hardInterval = intervals[.hard]!
        againInterval = min(againInterval, hardInterval)
        hardInterval = max(hardInterval, againInterval + 1)
        let goodInterval = max(intervals[.good]!, hardInterval + 1)
        let easyInterval = max(intervals[.easy]!, goodInterval + 1)

        var ordered: [Rating: Int] = [
            .again: againInterval, .hard: hardInterval, .good: goodInterval, .easy: easyInterval,
        ]
        if parameters.enableFuzz {
            let seed = fuzzSeed(card: card, now: now)
            for rating in Rating.allCases {
                ordered[rating] = IntervalFuzzer.fuzz(
                    interval: ordered[rating]!, elapsedDays: elapsed,
                    maximumInterval: parameters.maximumInterval, seed: seed
                )
            }
        }

        func outcome(_ rating: Rating) -> RecordLogItem {
            let (newS, newD) = memory[rating]!
            let interval = ordered[rating]!

            var updated = card
            updated.stability = newS
            updated.difficulty = newD
            updated.state = .review
            updated.step = 0
            updated.reps += 1
            updated.lastReview = now
            updated.scheduledDays = interval
            updated.due = now.addingTimeInterval(Double(interval) * 86_400.0)

            // Again counts as a lapse for any card that has been reviewed
            // before. The first review of a brand-new card never lapses.
            if rating == .again && card.state != .new {
                updated.lapses += 1
            }

            let log = ReviewLog(
                rating: rating, state: card.state,
                stability: card.stability, difficulty: card.difficulty,
                elapsedDays: elapsed, scheduledDays: card.scheduledDays,
                reviewedAt: now, previousDue: card.due,
                previousLastReview: card.lastReview, previousStep: card.step
            )
            return RecordLogItem(card: updated, log: log)
        }

        return [.again: outcome(.again), .hard: outcome(.hard), .good: outcome(.good), .easy: outcome(.easy)]
    }

    private func fuzzSeed(card: Card, now: Date) -> String {
        let milliseconds = Int(now.timeIntervalSince1970 * 1000)
        return "\(milliseconds)_\(card.reps + 1)_\(card.difficulty * card.stability)"
    }
}
