//
//  FSRSAlgorithmTests.swift
//  KaifangSpacedRepetition
//
//  Created by Brendan Chen on 2026.06.03.
//
//  Byte-for-byte parity for the nine FSRS-6 formulas. Expected values are the
//  rounded (8-decimal) reference values from ts-fsrs algorithm.test.ts and
//  FSRS-6.test.ts. Assertions use exact `==` — these are not approximations.
//

import Foundation
import Testing

@testable import KaifangSpacedRepetition

@Suite("Algorithm — forgetting curve")
struct ForgettingCurveTests {
    let algo = FSRSAlgorithm(parameters: FSRSParameters())

    /// algorithm.test.ts:114 — R(t, 1.0) for t = 0…3.
    @Test("R(t, 1.0) for t = 0…3")
    func curveAtStabilityOne() {
        #expect(algo.retrievability(elapsed: 0, stability: 1.0) == 1.0)
        #expect(algo.retrievability(elapsed: 1, stability: 1.0) == 0.9)
        #expect(algo.retrievability(elapsed: 2, stability: 1.0) == 0.84588465)
        #expect(algo.retrievability(elapsed: 3, stability: 1.0) == 0.8093881)
    }

    /// The curve passes through R(S, S) = 0.9 by construction, and matches the
    /// reference at assorted stabilities.
    @Test("R(t, S) at varied S")
    func curveVariedStability() {
        #expect(algo.retrievability(elapsed: 0, stability: 5.0) == 1.0)
        #expect(algo.retrievability(elapsed: 1, stability: 5.0) == 0.97276956)
        #expect(algo.retrievability(elapsed: 5, stability: 5.0) == 0.9)
        #expect(algo.retrievability(elapsed: 10, stability: 5.0) == 0.84588465)
        #expect(algo.retrievability(elapsed: 50, stability: 100.0) == 0.94034429)
        #expect(algo.retrievability(elapsed: 100, stability: 100.0) == 0.9)
        #expect(algo.retrievability(elapsed: 200, stability: 100.0) == 0.84588465)
    }

    @Test("R(t, S) at the stability bounds")
    func curveExtremes() {
        #expect(algo.retrievability(elapsed: 1, stability: 0.001) == 0.34566944)
        #expect(algo.retrievability(elapsed: 1, stability: 36500.0) == 0.99999586)
    }
}

@Suite("Algorithm — initial stability")
struct InitialStabilityTests {
    let algo = FSRSAlgorithm(parameters: FSRSParameters())

    /// algorithm.test.ts:129 and FSRS-6.test.ts:153 — S0(g) = w[g-1].
    @Test("S0(g) = w[g-1] for every grade")
    func allGrades() {
        #expect(algo.initialStability(.again) == 0.212)
        #expect(algo.initialStability(.hard) == 1.2931)
        #expect(algo.initialStability(.good) == 2.3065)
        #expect(algo.initialStability(.easy) == 8.2956)
    }
}

@Suite("Algorithm — initial difficulty")
struct InitialDifficultyTests {
    let algo = FSRSAlgorithm(parameters: FSRSParameters())

    /// FSRS-6.test.ts:154 — first-review difficulty for each grade (Easy's raw
    /// value is negative and clamps to 1.0).
    @Test("D0(g) for every grade")
    func allGrades() {
        #expect(algo.initialDifficulty(.again) == 6.4133)
        #expect(algo.initialDifficulty(.hard) == 5.11217071)
        #expect(algo.initialDifficulty(.good) == 2.11810397)
        #expect(algo.initialDifficulty(.easy) == 1.0)
    }
}

@Suite("Algorithm — next difficulty")
struct NextDifficultyTests {
    let algo = FSRSAlgorithm(parameters: FSRSParameters())

    /// algorithm.test.ts:202 — D' from D = 5 for each grade.
    @Test("D' from D = 5")
    func fromFive() {
        #expect(algo.nextDifficulty(current: 5.0, rating: .again) == 8.34176237)
        #expect(algo.nextDifficulty(current: 5.0, rating: .hard) == 6.66599536)
        #expect(algo.nextDifficulty(current: 5.0, rating: .good) == 4.99022837)
        #expect(algo.nextDifficulty(current: 5.0, rating: .easy) == 3.31446137)
    }

    @Test("D' from low D (mean reversion + clamp)")
    func fromLow() {
        #expect(algo.nextDifficulty(current: 1.0, rating: .again) == 7.02698957)
        #expect(algo.nextDifficulty(current: 1.0, rating: .hard) == 4.01060897)
        #expect(algo.nextDifficulty(current: 1.0, rating: .good) == 1.0)
        #expect(algo.nextDifficulty(current: 1.0, rating: .easy) == 1.0)
        #expect(algo.nextDifficulty(current: 2.5, rating: .again) == 7.52002937)
        #expect(algo.nextDifficulty(current: 2.5, rating: .easy) == 1.0)
    }

    @Test("D' from high D (damping)")
    func fromHigh() {
        #expect(algo.nextDifficulty(current: 7.5, rating: .again) == 9.16349536)
        #expect(algo.nextDifficulty(current: 7.5, rating: .hard) == 8.32561187)
        #expect(algo.nextDifficulty(current: 7.5, rating: .good) == 7.48772837)
        #expect(algo.nextDifficulty(current: 7.5, rating: .easy) == 6.64984487)
        #expect(algo.nextDifficulty(current: 9.5, rating: .again) == 9.82088177)
        #expect(algo.nextDifficulty(current: 9.5, rating: .easy) == 9.31815167)
    }
}

@Suite("Algorithm — recall stability")
struct RecallStabilityTests {
    let algo = FSRSAlgorithm(parameters: FSRSParameters())

    /// algorithm.test.ts:311 — Hard/Good/Easy at d = 2…4, s = 5, varied r.
    @Test("S' after recall (reference vector)")
    func referenceVector() {
        #expect(algo.recallStability(difficulty: 2.0, stability: 5.0, retrievability: 0.8, rating: .hard) == 28.22657096)
        #expect(algo.recallStability(difficulty: 3.0, stability: 5.0, retrievability: 0.7, rating: .good) == 58.65599107)
        #expect(algo.recallStability(difficulty: 4.0, stability: 5.0, retrievability: 0.6, rating: .easy) == 127.2266925)
    }

    @Test("S' after recall at D = 5, S = 10, R = 0.9")
    func midRange() {
        #expect(algo.recallStability(difficulty: 5.0, stability: 10.0, retrievability: 0.9, rating: .hard) == 23.24687511)
        #expect(algo.recallStability(difficulty: 5.0, stability: 10.0, retrievability: 0.9, rating: .good) == 32.02672948)
        #expect(algo.recallStability(difficulty: 5.0, stability: 10.0, retrievability: 0.9, rating: .easy) == 51.25386165)
    }

    @Test("S' after recall — extremes")
    func extremes() {
        #expect(algo.recallStability(difficulty: 1.0, stability: 100.0, retrievability: 0.5, rating: .good) == 1575.89834135)
        #expect(algo.recallStability(difficulty: 10.0, stability: 100.0, retrievability: 0.5, rating: .good) == 247.58983414)
        #expect(algo.recallStability(difficulty: 1.0, stability: 0.5, retrievability: 0.99, rating: .good) == 0.79164225)
        #expect(algo.recallStability(difficulty: 5.0, stability: 1.0, retrievability: 0.7, rating: .easy) == 20.70935775)
    }
}

@Suite("Algorithm — forget stability")
struct ForgetStabilityTests {
    let algo = FSRSAlgorithm(parameters: FSRSParameters())

    /// algorithm.test.ts:315 — Sf at d = 1…4, s = 5, varied r.
    @Test("S' after lapse (reference vector)")
    func referenceVector() {
        #expect(algo.forgetStability(difficulty: 1.0, stability: 5.0, retrievability: 0.9) == 1.05253961)
        #expect(algo.forgetStability(difficulty: 2.0, stability: 5.0, retrievability: 0.8) == 1.18943295)
        #expect(algo.forgetStability(difficulty: 3.0, stability: 5.0, retrievability: 0.7) == 1.36808387)
        #expect(algo.forgetStability(difficulty: 4.0, stability: 5.0, retrievability: 0.6) == 1.58498896)
    }

    @Test("S' after lapse — extra vectors")
    func extra() {
        #expect(algo.forgetStability(difficulty: 5.0, stability: 20.0, retrievability: 0.9) == 1.94358119)
        #expect(algo.forgetStability(difficulty: 5.0, stability: 20.0, retrievability: 0.5) == 3.75786977)
        #expect(algo.forgetStability(difficulty: 1.0, stability: 10.0, retrievability: 0.8) == 1.81191028)
        #expect(algo.forgetStability(difficulty: 10.0, stability: 10.0, retrievability: 0.8) == 1.57302885)
        #expect(algo.forgetStability(difficulty: 5.0, stability: 100.0, retrievability: 0.7) == 5.21058548)
        #expect(algo.forgetStability(difficulty: 5.0, stability: 0.5, retrievability: 0.95) == 0.16415724)
    }
}

@Suite("Algorithm — short-term stability")
struct ShortTermStabilityTests {
    let algo = FSRSAlgorithm(parameters: FSRSParameters())

    /// algorithm.test.ts:320 — same-day stability at s = 5 (Hard/Good clamp to S).
    @Test("S' same-day at S = 5")
    func atFive() {
        #expect(algo.shortTermStability(stability: 5.0, rating: .again) == 1.596818)
        #expect(algo.shortTermStability(stability: 5.0, rating: .hard) == 5.0)
        #expect(algo.shortTermStability(stability: 5.0, rating: .good) == 5.0)
        #expect(algo.shortTermStability(stability: 5.0, rating: .easy) == 8.12960956)
    }

    @Test("S' same-day at varied S (v6 dampening)")
    func variedStability() {
        #expect(algo.shortTermStability(stability: 1.0, rating: .again) == 0.35504029)
        #expect(algo.shortTermStability(stability: 1.0, rating: .hard) == 1.0)
        #expect(algo.shortTermStability(stability: 1.0, rating: .good) == 1.05072037)
        #expect(algo.shortTermStability(stability: 1.0, rating: .easy) == 1.80755662)
        #expect(algo.shortTermStability(stability: 10.0, rating: .again) == 3.05124894)
        #expect(algo.shortTermStability(stability: 10.0, rating: .easy) == 15.53430795)
        #expect(algo.shortTermStability(stability: 50.0, rating: .good) == 50.0)
        #expect(algo.shortTermStability(stability: 100.0, rating: .good) == 100.0)
        #expect(algo.shortTermStability(stability: 0.5, rating: .hard) == 0.5)
    }
}

@Suite("Algorithm — interval")
struct IntervalTests {
    /// algorithm.test.ts:347 — interval at S = 1 across retention 0.1…0.9.
    @Test("Interval at S = 1 for retention 0.1…0.9")
    func referenceTable() {
        func interval(retention: Double) -> Int {
            FSRSAlgorithm(parameters: FSRSParameters(requestRetention: retention, maximumInterval: Int.max))
                .interval(stability: 1.0)
        }
        #expect(interval(retention: 0.1) == 3_116_769)
        #expect(interval(retention: 0.2) == 34_793)
        #expect(interval(retention: 0.3) == 2_508)
        #expect(interval(retention: 0.4) == 387)
        #expect(interval(retention: 0.5) == 90)
        #expect(interval(retention: 0.6) == 27)
        #expect(interval(retention: 0.7) == 9)
        #expect(interval(retention: 0.8) == 3)
        #expect(interval(retention: 0.9) == 1)
    }

    /// At retention 0.9 the modifier is 1.0, so the interval ≈ round(S).
    @Test("Interval at default config ≈ round(S), clamped")
    func defaultConfig() {
        let algo = FSRSAlgorithm(parameters: FSRSParameters())
        #expect(algo.interval(stability: 0.5) == 1)
        #expect(algo.interval(stability: 1.0) == 1)
        #expect(algo.interval(stability: 2.3065) == 2)
        #expect(algo.interval(stability: 8.2956) == 8)
        #expect(algo.interval(stability: 10.0) == 10)
        #expect(algo.interval(stability: 30.0) == 30)
        #expect(algo.interval(stability: 100.0) == 100)
        #expect(algo.interval(stability: 1000.0) == 1000)
        #expect(algo.interval(stability: 50_000.0) == 36_500)
    }
}

@Suite("Algorithm — next state dispatch")
struct NextStateTests {
    let algo = FSRSAlgorithm(parameters: FSRSParameters())

    /// New card routes to the initial formulas (FSRS-6.test.ts:153-154).
    @Test("From a new card")
    func newCard() {
        let again = algo.nextState(stability: 0, difficulty: 0, elapsed: 0, rating: .again)
        #expect(again.stability == 0.212)
        #expect(again.difficulty == 6.4133)
        let good = algo.nextState(stability: 0, difficulty: 0, elapsed: 0, rating: .good)
        #expect(good.stability == 2.3065)
        #expect(good.difficulty == 2.11810397)
        let easy = algo.nextState(stability: 0, difficulty: 0, elapsed: 0, rating: .easy)
        #expect(easy.stability == 8.2956)
        #expect(easy.difficulty == 1.0)
    }

    @Test("Same-day Good routes to short-term stability")
    func sameDayGood() {
        let r = algo.nextState(stability: 10.0, difficulty: 5.0, elapsed: 0, rating: .good)
        #expect(r.stability == 10.0)
        #expect(r.difficulty == 4.99022837)
    }

    @Test("Recall at S = 10, D = 5, t = 5")
    func recall() {
        let hard = algo.nextState(stability: 10.0, difficulty: 5.0, elapsed: 5, rating: .hard)
        #expect(hard.stability == 17.77531755)
        #expect(hard.difficulty == 6.66599536)
        let good = algo.nextState(stability: 10.0, difficulty: 5.0, elapsed: 5, rating: .good)
        #expect(good.stability == 22.92869563)
        #expect(good.difficulty == 4.99022837)
        let easy = algo.nextState(stability: 10.0, difficulty: 5.0, elapsed: 5, rating: .easy)
        #expect(easy.stability == 34.21415404)
        #expect(easy.difficulty == 3.31446137)
    }

    @Test("Lapse at S = 10, D = 5, t = 5 (short-term floor wins)")
    func lapseShortTerm() {
        let r = algo.nextState(stability: 10.0, difficulty: 5.0, elapsed: 5, rating: .again)
        #expect(r.stability == 1.30243125)
        #expect(r.difficulty == 8.34176237)
    }

    @Test("Mature card recall and lapse")
    func mature() {
        let good = algo.nextState(stability: 50.0, difficulty: 7.0, elapsed: 30, rating: .good)
        #expect(good.stability == 88.1798008)
        #expect(good.difficulty == 6.98822837)
        let again = algo.nextState(stability: 50.0, difficulty: 7.0, elapsed: 30, rating: .again)
        #expect(again.stability == 2.67112701)
        #expect(again.difficulty == 8.99914877)
    }

    @Test("High-difficulty lapse")
    func highDifficultyLapse() {
        let r = algo.nextState(stability: 2.0, difficulty: 9.0, elapsed: 1, rating: .again)
        #expect(r.stability == 0.47891956)
        #expect(r.difficulty == 9.65653517)
    }

    @Test("Long-term mode wires the same as the reference")
    func longTermMode() {
        let lt = FSRSAlgorithm(parameters: FSRSParameters(enableShortTerm: false))
        let again = lt.nextState(stability: 10.0, difficulty: 5.0, elapsed: 5, rating: .again)
        #expect(again.stability == 1.30243125)
        #expect(again.difficulty == 8.34176237)
        let good = lt.nextState(stability: 10.0, difficulty: 5.0, elapsed: 5, rating: .good)
        #expect(good.stability == 22.92869563)
        #expect(good.difficulty == 4.99022837)
    }
}

@Suite("Weights & parameters")
struct WeightsParametersTests {
    @Test("Default w[0] = 0.212")
    func defaultFirstWeight() {
        #expect(FSRSWeights.default[0] == 0.212)
        #expect(FSRSWeights.default.values.count == 21)
    }

    @Test("Out-of-range weights clamp to their FSRS-6 bounds")
    func clamping() {
        let low = FSRSWeights(values: Array(repeating: -100.0, count: 21))
        #expect(low[0] >= 0.001)
        #expect(low[4] >= 1.0)
        #expect(low[20] >= 0.1)
        let high = FSRSWeights(values: Array(repeating: 1000.0, count: 21))
        #expect(high[0] <= 100.0)
        #expect(high[4] <= 10.0)
        #expect(high[20] <= 0.8)
    }

    @Test("Request retention clamps to [0.01, 0.99]")
    func retentionClamp() {
        #expect(FSRSParameters(requestRetention: 0.0).requestRetention >= 0.01)
        #expect(FSRSParameters(requestRetention: 1.0).requestRetention <= 0.99)
    }
}
