//
//  AleaTests.swift
//  KaifangSpacedRepetition
//
//  Created by Brendan Chen on 2026.06.03.
//
//  Parity vectors for the Alea PRNG and interval fuzzer. Expected values are
//  copied byte-for-byte from ts-fsrs __tests__/alea.test.ts. If these drift,
//  the fuzz stream has diverged from the reference.
//

import Foundation
import Testing

@testable import KaifangSpacedRepetition

@Suite("Alea PRNG — parity vectors")
struct AleaParityTests {
    @Test("seed '12345' next() stream")
    func nextStream() {
        var generator = Alea(seed: "12345")
        #expect(generator.next() == 0.27138191112317145)
        #expect(generator.next() == 0.19615925149992108)
        #expect(generator.next() == 0.6810678059700876)
    }

    @Test("seed '12345' int32() stream (signed)")
    func int32Stream() {
        var generator = Alea(seed: "12345")
        #expect(generator.int32() == 1_165_576_433)
        #expect(generator.int32() == 842_497_570)
        #expect(generator.int32() == -1_369_803_343)
    }

    @Test("seeds exercising the s0/s1/s2 < 0 wrap branches")
    func negativeWrapBranches() {
        var a = Alea(seed: "1727015666066")
        #expect(a.next() == 0.6320083506871015)
        var b = Alea(seed: "Seedp5fxh9kf4r0")
        #expect(b.next() == 0.14867847645655274)
        var c = Alea(seed: "NegativeS2Seed")
        #expect(c.next() == 0.830770346801728)
    }

    @Test("Same seed is deterministic; output stays in [0, 1)")
    func deterministicInRange() {
        var a = Alea(seed: "abc")
        var b = Alea(seed: "abc")
        for _ in 0..<200 {
            let v = a.next()
            #expect(v == b.next())
            #expect(v >= 0.0 && v < 1.0)
        }
    }
}

@Suite("Interval fuzzer — parity & guards")
struct IntervalFuzzerTests {
    @Test("Intervals below 3 days are not fuzzed")
    func tinyUnchanged() {
        for interval in 0...2 {
            #expect(IntervalFuzzer.fuzz(interval: interval, elapsedDays: 0, maximumInterval: 365, seed: "any") == interval)
        }
    }

    /// Hand-derived from the alea vector for seed "12345":
    /// range [8, 12], floor(0.27138… × 5 + 8) = 9.
    @Test("fuzz(10, 5, 365, '12345') == 9")
    func fuzzNarrowRange() {
        #expect(IntervalFuzzer.fuzz(interval: 10, elapsedDays: 5, maximumInterval: 365, seed: "12345") == 9)
    }

    /// range [27, 33], floor(0.27138… × 7 + 27) = 28.
    @Test("fuzz(30, 0, 365, '12345') == 28")
    func fuzzWideRange() {
        #expect(IntervalFuzzer.fuzz(interval: 30, elapsedDays: 0, maximumInterval: 365, seed: "12345") == 28)
    }

    @Test("interval == elapsedDays does not bump the lower bound")
    func atElapsedBoundary() {
        #expect(IntervalFuzzer.fuzz(interval: 10, elapsedDays: 10, maximumInterval: 365, seed: "12345") == 9)
    }

    @Test("maximumInterval caps the fuzzed result")
    func cappedByMax() {
        for i in 0..<50 {
            #expect(IntervalFuzzer.fuzz(interval: 100, elapsedDays: 0, maximumInterval: 50, seed: "s\(i)") <= 50)
        }
    }

    @Test("Fuzz is deterministic for a fixed seed")
    func deterministic() {
        let a = IntervalFuzzer.fuzz(interval: 10, elapsedDays: 5, maximumInterval: 365, seed: "test")
        let b = IntervalFuzzer.fuzz(interval: 10, elapsedDays: 5, maximumInterval: 365, seed: "test")
        #expect(a == b)
    }
}

@Suite("Scheduler fuzz determinism")
struct SchedulerFuzzTests {
    private func reviewCard() -> Card {
        Card(due: Date(timeIntervalSince1970: 1_700_000_000),
             stability: 10, difficulty: 5, state: .review, step: 0,
             reps: 3, lapses: 0, scheduledDays: 10,
             lastReview: Date(timeIntervalSince1970: 1_700_000_000))
    }

    @Test("Identical inputs yield identical fuzzed due dates")
    func idempotent() {
        let fsrs = FSRS(parameters: FSRSParameters(enableFuzz: true))
        let card = reviewCard()
        let now = Date(timeIntervalSince1970: 1_700_864_000)
        let r1 = fsrs.repeat(card: card, now: now)
        let r2 = fsrs.repeat(card: card, now: now)
        for rating in Rating.allCases {
            #expect(r1[rating]!.card.due == r2[rating]!.card.due)
        }
    }
}
