//
//  FSRSSchedulerTests.swift
//  KaifangSpacedRepetition
//
//  Created by Brendan Chen on 2026.06.03.
//
//  Scheduler behaviour and long-sequence parity. The `ivl_history` and
//  `memory state` cases reproduce ts-fsrs FSRS-6.test.ts verbatim.
//

import Foundation
import Testing

@testable import KaifangSpacedRepetition

// MARK: - Learning steps (basic scheduler)

@Suite("Basic scheduler — learning steps [1m, 10m]")
struct LearningStepsTests {
    let fsrs = FSRS(parameters: FSRSParameters(learningSteps: [60, 600]))

    @Test("New card: Again 1m / Hard 6m / Good 10m / Easy graduates")
    func newCardAllGrades() {
        let card = FSRS.newCard(now: refDate)
        let result = fsrs.repeat(card: card, now: refDate)

        #expect(result[.again]!.card.state == .learning)
        #expect(result[.again]!.card.step == 0)
        #expect(result[.again]!.card.scheduledDays == 0)
        expectExactDue(result[.again]!.card.due, refDate.addingTimeInterval(60))

        // Hard duration = round((1 + 10) / 2) = 6 minutes.
        #expect(result[.hard]!.card.state == .learning)
        #expect(result[.hard]!.card.step == 0)
        expectExactDue(result[.hard]!.card.due, refDate.addingTimeInterval(360))

        #expect(result[.good]!.card.state == .learning)
        #expect(result[.good]!.card.step == 1)
        expectExactDue(result[.good]!.card.due, refDate.addingTimeInterval(600))

        #expect(result[.easy]!.card.state == .review)
        #expect(result[.easy]!.card.step == 0)
    }

    @Test("Learning step 1: Again resets, Hard repeats step 1, Good graduates")
    func learningStepOne() {
        let card = fsrs.next(card: FSRS.newCard(now: refDate), now: refDate, grade: .good).card
        #expect(card.step == 1)
        let now = card.due
        let result = fsrs.repeat(card: card, now: now)

        #expect(result[.again]!.card.state == .learning)
        #expect(result[.again]!.card.step == 0)
        expectExactDue(result[.again]!.card.due, now.addingTimeInterval(60))

        #expect(result[.hard]!.card.state == .learning)
        #expect(result[.hard]!.card.step == 1)
        expectExactDue(result[.hard]!.card.due, now.addingTimeInterval(360))

        #expect(result[.good]!.card.state == .review)  // step 2 exhausted → graduate
        #expect(result[.good]!.card.step == 0)
    }

    @Test("Single-step config [1m]: Hard = round(1×1.5) = 2m, Good graduates")
    func singleStep() {
        let fsrs = FSRS(parameters: FSRSParameters(learningSteps: [60]))
        let result = fsrs.repeat(card: FSRS.newCard(now: refDate), now: refDate)
        expectExactDue(result[.hard]!.card.due, refDate.addingTimeInterval(120))
        #expect(result[.good]!.card.state == .review)
    }

    @Test("Long step (≥ 1 day) graduates to Review carrying scheduledDays")
    func longStepGraduates() {
        let fsrs = FSRS(parameters: FSRSParameters(learningSteps: [60, 86_400 * 3]))
        let result = fsrs.next(card: FSRS.newCard(now: refDate), now: refDate, grade: .good)
        #expect(result.card.state == .review)
        #expect(result.card.step == 1)
        #expect(result.card.scheduledDays == 3)
        expectExactDue(result.card.due, refDate.addingTimeInterval(86_400 * 3))
    }
}

@Suite("Basic scheduler — relearning steps")
struct RelearningStepsTests {
    @Test("Review + Again → Relearning at 10m; relearning Hard = 15m")
    func relearningSingleStep() {
        let fsrs = FSRS(parameters: FSRSParameters(relearningSteps: [600]))
        var card = fsrs.next(card: FSRS.newCard(now: refDate), now: refDate, grade: .easy).card
        #expect(card.state == .review)

        let lapsed = fsrs.next(card: card, now: card.due, grade: .again).card
        #expect(lapsed.state == .relearning)
        #expect(lapsed.step == 0)
        #expect(lapsed.scheduledDays == 0)
        expectExactDue(lapsed.due, card.due.addingTimeInterval(600))

        let result = fsrs.repeat(card: lapsed, now: lapsed.due)
        expectExactDue(result[.again]!.card.due, lapsed.due.addingTimeInterval(600))
        expectExactDue(result[.hard]!.card.due, lapsed.due.addingTimeInterval(900))
        card = result[.again]!.card  // silence unused warning path
        _ = card
    }

    @Test("Empty relearning steps: Review + Again stays in Review")
    func emptyRelearning() {
        let fsrs = FSRS(parameters: FSRSParameters(relearningSteps: []))
        let card = fsrs.next(card: FSRS.newCard(now: refDate), now: refDate, grade: .easy).card
        let now = card.lastReview!.addingTimeInterval(5 * 86_400)
        let result = fsrs.next(card: card, now: now, grade: .again)
        #expect(result.card.state == .review)
        #expect(result.card.lapses == 1)
    }
}

// MARK: - Ordering, counters, preview consistency

@Suite("Basic scheduler — ordering & counters")
struct BasicOrderingCountersTests {
    let fsrs = FSRS()

    @Test("Review intervals satisfy hard < good < easy")
    func reviewOrdering() {
        var card = fsrs.next(card: FSRS.newCard(now: refDate), now: refDate, grade: .easy).card
        for iteration in 0..<5 {
            let now = card.lastReview!.addingTimeInterval(Double(iteration + 1) * 5 * 86_400)
            let result = fsrs.repeat(card: card, now: now)
            let h = result[.hard]!.card.scheduledDays
            let g = result[.good]!.card.scheduledDays
            let e = result[.easy]!.card.scheduledDays
            #expect(h < g)
            #expect(g < e)
            card = result[.good]!.card
        }
    }

    @Test("reps increments by one per review")
    func repsIncrement() {
        let card = FSRS.newCard(now: refDate)
        for rating in Rating.allCases {
            #expect(fsrs.next(card: card, now: refDate, grade: rating).card.reps == 1)
        }
    }

    @Test("lapses increments only on Again from Review")
    func lapsesOnlyReviewAgain() {
        let new = FSRS.newCard(now: refDate)
        for rating in Rating.allCases {
            #expect(fsrs.next(card: new, now: refDate, grade: rating).card.lapses == 0)
        }
        let review = fsrs.next(card: new, now: refDate, grade: .easy).card
        let now = review.lastReview!.addingTimeInterval(5 * 86_400)
        for rating in Rating.allCases {
            let expected = rating == .again ? 1 : 0
            #expect(fsrs.next(card: review, now: now, grade: rating).card.lapses == expected)
        }
    }

    @Test("repeat[rating] equals next(grade:) for every state")
    func previewConsistency() {
        var card = FSRS.newCard(now: refDate)
        // new, learning, review, relearning
        let states: [Card] = {
            let learning = fsrs.next(card: card, now: refDate, grade: .again).card
            let review = fsrs.next(card: card, now: refDate, grade: .easy).card
            let relearning = fsrs.next(card: review, now: review.due, grade: .again).card
            return [card, learning, review, relearning]
        }()
        for state in states {
            let now = state.due
            let preview = fsrs.repeat(card: state, now: now)
            for rating in Rating.allCases {
                #expect(preview[rating]! == fsrs.next(card: state, now: now, grade: rating))
            }
        }
        card = states[0]
        _ = card
    }
}

// MARK: - Long-term scheduler

@Suite("Long-term scheduler")
struct LongTermSchedulerTests {
    let fsrs = FSRS(parameters: FSRSParameters(enableShortTerm: false))

    @Test("Every grade from a new card lands in Review")
    func newToReview() {
        let result = fsrs.repeat(card: FSRS.newCard(now: refDate), now: refDate)
        for rating in Rating.allCases {
            #expect(result[rating]!.card.state == .review)
            #expect(result[rating]!.card.step == 0)
        }
    }

    @Test("Intervals satisfy again < hard < good < easy")
    func ordering() {
        let result = fsrs.repeat(card: FSRS.newCard(now: refDate), now: refDate)
        let a = result[.again]!.card.scheduledDays
        let h = result[.hard]!.card.scheduledDays
        let g = result[.good]!.card.scheduledDays
        let e = result[.easy]!.card.scheduledDays
        #expect(a < h)
        #expect(h < g)
        #expect(g < e)
    }

    @Test("First Again does not lapse; later Again does")
    func lapses() {
        let new = FSRS.newCard(now: refDate)
        #expect(fsrs.next(card: new, now: refDate, grade: .again).card.lapses == 0)
        var card = fsrs.next(card: new, now: refDate, grade: .good).card
        card = fsrs.next(card: card, now: card.due, grade: .again).card
        #expect(card.lapses == 1)
    }
}

// MARK: - ts-fsrs FSRS-6.test.ts byte-for-byte sequences

@Suite("ts-fsrs FSRS-6 parity — sequences")
struct FSRS6SequenceParityTests {

    /// FSRS-6.test.ts `ivl_history`: G,G,G,G,G,G,A,A,G,G,G,G,G produces the
    /// scheduled-day sequence below in basic mode.
    @Test("ivl_history")
    func ivlHistory() {
        let fsrs = FSRS()
        var card = FSRS.newCard(now: refDate)
        var now = refDate
        let ratings: [Rating] = [.good, .good, .good, .good, .good, .good,
                                 .again, .again,
                                 .good, .good, .good, .good, .good]
        let expected = [0, 2, 11, 46, 163, 498, 0, 0, 2, 4, 7, 12, 21]
        var observed: [Int] = []
        for rating in ratings {
            card = fsrs.next(card: card, now: now, grade: rating).card
            observed.append(card.scheduledDays)
            now = card.due
        }
        #expect(observed == expected)
    }

    /// FSRS-6.test.ts `memory state` (short-term): A,G,G,G,G,G with day gaps
    /// [0,0,1,3,8,21] → S ≈ 53.62691, D ≈ 6.3574867 (4-decimal tolerance).
    @Test("memory state — short-term")
    func memoryStateShortTerm() {
        let fsrs = FSRS()
        var card = FSRS.newCard(now: refDate)
        var now = refDate
        for (rating, gap) in [(Rating.again, 0), (.good, 0), (.good, 1), (.good, 3), (.good, 8), (.good, 21)] {
            now = now.addingTimeInterval(Double(gap) * 86_400.0)
            card = fsrs.next(card: card, now: now, grade: rating).card
        }
        #expect(abs(card.stability - 53.62691) < 1e-4)
        #expect(abs(card.difficulty - 6.3574867) < 1e-4)
    }

    /// FSRS-6.test.ts `memory state` (long-term): same sequence, long-term mode
    /// → S ≈ 53.335106, D ≈ 6.3574867.
    @Test("memory state — long-term")
    func memoryStateLongTerm() {
        let fsrs = FSRS(parameters: FSRSParameters(enableShortTerm: false))
        var card = FSRS.newCard(now: refDate)
        var now = refDate
        for (rating, gap) in [(Rating.again, 0), (.good, 0), (.good, 1), (.good, 3), (.good, 8), (.good, 21)] {
            now = now.addingTimeInterval(Double(gap) * 86_400.0)
            card = fsrs.next(card: card, now: now, grade: rating).card
        }
        #expect(abs(card.stability - 53.335106) < 1e-4)
        #expect(abs(card.difficulty - 6.3574867) < 1e-4)
    }

    /// An all-Good long-term trajectory pinned to the 8-decimal reference at
    /// each step — the canary for any rounding drift through the pipeline.
    @Test("All-Good long-term trajectory (3 steps)")
    func allGoodLongTerm() {
        let fsrs = FSRS(parameters: FSRSParameters(enableShortTerm: false))
        var card = FSRS.newCard(now: refDate)
        card = fsrs.next(card: card, now: refDate, grade: .good).card
        #expect(card.stability == 2.3065)
        #expect(card.difficulty == 2.11810397)

        let t2 = refDate.addingTimeInterval(2 * 86_400)
        card = fsrs.next(card: card, now: t2, grade: .good).card
        #expect(card.stability == 10.96433194)
        #expect(card.difficulty == 2.11121424)

        let t3 = t2.addingTimeInterval(11 * 86_400)
        card = fsrs.next(card: card, now: t3, grade: .good).card
        #expect(card.stability == 46.28021494)
        #expect(card.difficulty == 2.10433140)
    }

    /// Five consecutive Easy reviews from new (basic mode): difficulty pins to
    /// 1.0, stability compounds with the Easy bonus.
    @Test("Easy graduation cascade (5 reviews)")
    func easyCascade() {
        let fsrs = FSRS()
        var card = FSRS.newCard(now: refDate)
        var now = refDate
        let expected: [(s: Double, days: Int)] = [
            (8.29560000, 8), (65.62422648, 66), (396.77501923, 397),
            (1874.91696522, 1875), (7265.43276492, 7265),
        ]
        for step in expected {
            card = fsrs.next(card: card, now: now, grade: .easy).card
            #expect(card.stability == step.s)
            #expect(card.difficulty == 1.0)
            #expect(card.scheduledDays == step.days)
            now = card.due
        }
    }
}

// MARK: - Retrievability

@Suite("Retrievability")
struct RetrievabilityTests {
    let fsrs = FSRS()

    @Test("New card has zero retrievability; reviewed card follows the curve")
    func lifecycle() {
        var card = FSRS.newCard(now: refDate)
        #expect(fsrs.retrievability(of: card, now: refDate) == 0)

        card = fsrs.next(card: card, now: refDate, grade: .good).card
        card = fsrs.next(card: card, now: card.due, grade: .good).card

        expectApprox(fsrs.retrievability(of: card, now: card.lastReview!), 1.0, tolerance: 0.05)
        expectApprox(fsrs.retrievability(of: card, now: card.due), 0.9, tolerance: 0.05)
        #expect(fsrs.retrievability(of: card, now: card.due.addingTimeInterval(30 * 86_400)) < 0.9)
    }
}
