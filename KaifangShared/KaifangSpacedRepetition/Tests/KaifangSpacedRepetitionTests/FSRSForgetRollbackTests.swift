//
//  FSRSForgetRollbackTests.swift
//  KaifangSpacedRepetition
//
//  Created by Brendan Chen on 2026.06.03.
//
//  Ports ts-fsrs rollback.test.ts and forget.test.ts: behavioural-identity
//  tests (round-trip equality and field-by-field snapshots) rather than
//  hardcoded numerics, extended to every starting state.
//

import Foundation
import Testing

@testable import KaifangSpacedRepetition

@Suite("Rollback")
struct RollbackTests {
    let fsrs = FSRS()

    @Test("Round-trips from .new for every grade")
    func fromNew() {
        let original = FSRS.newCard(now: refDate)
        let preview = fsrs.repeat(card: original, now: refDate)
        for rating in Rating.allCases {
            let item = preview[rating]!
            #expect(fsrs.rollback(card: item.card, log: item.log) == original)
        }
    }

    @Test("Round-trips from .learning, .review, .relearning for every grade")
    func fromOtherStates() {
        let new = FSRS.newCard(now: refDate)
        let learning = fsrs.next(card: new, now: refDate, grade: .good).card
        let review = fsrs.next(card: new, now: refDate, grade: .easy).card
        let relearning = fsrs.next(card: review, now: review.due, grade: .again).card
        #expect(learning.state == .learning)
        #expect(review.state == .review)
        #expect(relearning.state == .relearning)

        for snapshot in [learning, review, relearning] {
            let preview = fsrs.repeat(card: snapshot, now: snapshot.due)
            for rating in Rating.allCases {
                let item = preview[rating]!
                #expect(fsrs.rollback(card: item.card, log: item.log) == snapshot,
                        "rollback from \(snapshot.state) + \(rating) failed")
            }
        }
    }

    @Test("Decrements lapses only for Again on a Review card")
    func lapseDecrement() {
        let review = fsrs.next(card: FSRS.newCard(now: refDate), now: refDate, grade: .easy).card
        let again = fsrs.next(card: review, now: review.due, grade: .again)
        #expect(again.card.lapses == review.lapses + 1)
        #expect(fsrs.rollback(card: again.card, log: again.log).lapses == review.lapses)

        let good = fsrs.next(card: review, now: review.due, grade: .good)
        #expect(fsrs.rollback(card: good.card, log: good.log).lapses == review.lapses)
    }

    @Test("reps decrements but clamps at zero")
    func repsClamp() {
        let result = fsrs.next(card: FSRS.newCard(now: refDate), now: refDate, grade: .good)
        #expect(fsrs.rollback(card: result.card, log: result.log).reps == 0)
    }

    @Test("Sequential rollback peels reviews in reverse")
    func sequential() {
        var card = FSRS.newCard(now: refDate)
        let r1 = fsrs.next(card: card, now: refDate, grade: .good)
        let snapshot1 = card
        card = r1.card
        let r2 = fsrs.next(card: card, now: card.due, grade: .good)
        let snapshot2 = card
        card = r2.card

        let once = fsrs.rollback(card: card, log: r2.log)
        #expect(once == snapshot2)
        #expect(fsrs.rollback(card: once, log: r1.log) == snapshot1)
    }
}

@Suite("Forget")
struct ForgetTests {
    let fsrs = FSRS()

    @Test("Resets a reviewed card to .new, preserving lastReview")
    func resetsReviewed() {
        var card = fsrs.next(card: FSRS.newCard(now: refDate), now: refDate, grade: .easy).card
        card = fsrs.next(card: card, now: card.due, grade: .again).card  // +1 lapse
        let repsBefore = card.reps
        let lapsesBefore = card.lapses
        let lastReviewBefore = card.lastReview

        let result = fsrs.forget(card: card, now: dateAfter(days: 30))
        #expect(result.card.state == .new)
        #expect(result.card.stability == 0)
        #expect(result.card.difficulty == 0)
        #expect(result.card.scheduledDays == 0)
        #expect(result.card.step == 0)
        #expect(result.card.due == dateAfter(days: 30))
        #expect(result.card.lastReview == lastReviewBefore)
        // Counters preserved by default.
        #expect(result.card.reps == repsBefore)
        #expect(result.card.lapses == lapsesBefore)
    }

    @Test("resetCount zeroes reps and lapses")
    func resetCount() {
        var card = fsrs.next(card: FSRS.newCard(now: refDate), now: refDate, grade: .easy).card
        card = fsrs.next(card: card, now: card.due, grade: .again).card
        let result = fsrs.forget(card: card, now: dateAfter(days: 30), resetCount: true)
        #expect(result.card.reps == 0)
        #expect(result.card.lapses == 0)
    }

    @Test("Forget log captures pre-forget snapshot")
    func logSnapshot() {
        let card = fsrs.next(card: FSRS.newCard(now: refDate), now: refDate, grade: .easy).card
        let forgetTime = dateAfter(days: 3)
        let log = fsrs.forget(card: card, now: forgetTime).log
        #expect(log.state == .review)
        #expect(log.stability == card.stability)
        #expect(log.difficulty == card.difficulty)
        #expect(log.elapsedDays == 0)
        #expect(log.reviewedAt == forgetTime)
        #expect(log.previousDue == card.due)
        #expect(log.previousLastReview == card.lastReview)
        #expect(log.previousStep == card.step)
    }

    @Test("Forget log scheduledDays = whole days between due and now (non-new)")
    func logScheduledDays() {
        let card = fsrs.next(card: FSRS.newCard(now: refDate), now: refDate, grade: .easy).card
        let forgetTime = card.due.addingTimeInterval(2 * 86_400)
        #expect(fsrs.forget(card: card, now: forgetTime).log.scheduledDays == 2)
        // New cards report 0.
        #expect(fsrs.forget(card: FSRS.newCard(now: refDate), now: dateAfter(days: 5)).log.scheduledDays == 0)
    }

    @Test("Forgotten card schedules like a fresh card")
    func schedulesLikeNew() {
        var card = fsrs.next(card: FSRS.newCard(now: refDate), now: refDate, grade: .easy).card
        let forgotten = fsrs.forget(card: card, now: dateAfter(days: 30)).card
        let fresh = FSRS.newCard(now: dateAfter(days: 30))
        let onForgotten = fsrs.next(card: forgotten, now: dateAfter(days: 30), grade: .good).card
        let onFresh = fsrs.next(card: fresh, now: dateAfter(days: 30), grade: .good).card
        #expect(onForgotten.stability == onFresh.stability)
        #expect(onForgotten.difficulty == onFresh.difficulty)
        #expect(onForgotten.state == onFresh.state)
        card = forgotten
        _ = card
    }
}
