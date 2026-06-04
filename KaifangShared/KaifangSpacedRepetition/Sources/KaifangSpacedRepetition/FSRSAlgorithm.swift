//
//  FSRSAlgorithm.swift
//  KaifangSpacedRepetition
//
//  Created by Brendan Chen on 2026.06.03.
//

import Foundation

/// The pure mathematical core of FSRS-6: the forgetting curve, the
/// stability/difficulty update formulas, and interval conversion.
///
/// Every method is a deterministic function of the weights. The schedulers
/// (`BasicScheduler`, `LongTermScheduler`) build on these primitives to walk a
/// card through its state machine. Intermediate results are rounded to eight
/// decimals at the same points the FSRS reference does, so output matches the
/// reference bit-for-bit.
struct FSRSAlgorithm: Sendable {

    // MARK: Bounds

    static let minStability = 0.001
    static let maxStability = 36_500.0
    static let minDifficulty = 1.0
    static let maxDifficulty = 10.0

    // MARK: Configuration

    let weights: FSRSWeights
    let enableShortTerm: Bool
    let maximumInterval: Int

    /// Forgetting-curve decay, `-w[20]`. Negative because retrievability falls
    /// with time. (v5 fixed this at -0.5; v6 makes it trainable.)
    let decay: Double

    /// Curve scaling factor chosen so that `R(S, S) == 0.9`:
    /// `factor = exp(ln(0.9) / decay) - 1`.
    let factor: Double

    /// Multiplier turning stability into an interval at the configured
    /// retention: `(retention^(1/decay) - 1) / factor`. Collapses to `1.0`
    /// when retention is 0.9.
    let intervalModifier: Double

    init(parameters: FSRSParameters) {
        self.weights = parameters.weights
        self.enableShortTerm = parameters.enableShortTerm
        self.maximumInterval = parameters.maximumInterval

        let decay = -parameters.weights[20]
        self.decay = decay
        // The factor is rounded; the decay is used raw — matching the reference.
        self.factor = Self.round8(exp(log(0.9) / decay) - 1.0)
        self.intervalModifier = Self.round8(
            (pow(parameters.requestRetention, 1.0 / decay) - 1.0) / self.factor
        )
    }

    // MARK: Rounding

    /// Rounds to eight decimal places using "half away from zero" — the same
    /// rule as JavaScript's `Math.round` over the non-negative FSRS domain.
    @inlinable
    static func round8(_ value: Double) -> Double {
        let scale = 100_000_000.0  // 10^8
        return (value * scale).rounded(.toNearestOrAwayFromZero) / scale
    }

    // MARK: Forgetting curve

    /// Probability of recall after `elapsed` days at stability `stability`.
    /// `R = (1 + factor · t / S) ^ decay`. Returns `1.0` at `t = 0` and `0.9`
    /// at `t = S` by construction.
    func retrievability(elapsed: Double, stability: Double) -> Double {
        guard stability >= Self.minStability else { return 0 }
        return Self.round8(pow(1.0 + factor * elapsed / stability, decay))
    }

    // MARK: Initial state (first review of a new card)

    /// Initial stability: `S0(g) = max(w[g-1], 0.1)`.
    func initialStability(_ rating: Rating) -> Double {
        max(weights[rating.rawValue - 1], 0.1)
    }

    /// Initial difficulty, clamped to `[1, 10]`.
    func initialDifficulty(_ rating: Rating) -> Double {
        clampDifficulty(rawInitialDifficulty(rating))
    }

    /// Initial difficulty before clamping (but rounded). The mean-reversion
    /// target in ``nextDifficulty(current:rating:)`` uses this raw value — the
    /// reference reverts toward the unclamped `D0(Easy)` (≈ -4.77 with default
    /// weights), and clamping it would move the equilibrium.
    private func rawInitialDifficulty(_ rating: Rating) -> Double {
        let g = Double(rating.rawValue)
        return Self.round8(weights[4] - exp((g - 1.0) * weights[5]) + 1.0)
    }

    // MARK: Difficulty update

    /// Difficulty after a review: linear damping (smaller changes near D=10)
    /// plus mean reversion toward `D0(Easy)`, then clamped to `[1, 10]`.
    func nextDifficulty(current difficulty: Double, rating: Rating) -> Double {
        let g = Double(rating.rawValue)
        let delta = -weights[6] * (g - 3.0)
        let damped = Self.round8(delta * (10.0 - difficulty) / 9.0)
        let shifted = difficulty + damped  // not rounded; only the parts are
        let target = rawInitialDifficulty(.easy)
        let reverted = Self.round8(weights[7] * target + (1.0 - weights[7]) * shifted)
        return clampDifficulty(reverted)
    }

    // MARK: Stability after successful recall

    /// Stability after Hard/Good/Easy with at least one day elapsed.
    /// Higher difficulty and higher current stability both dampen the gain;
    /// lower retrievability (reviewing closer to forgetting) amplifies it.
    func recallStability(difficulty: Double, stability: Double, retrievability r: Double, rating: Rating) -> Double {
        let hardPenalty = rating == .hard ? weights[15] : 1.0
        let easyBonus = rating == .easy ? weights[16] : 1.0
        let result = stability * (1.0
            + exp(weights[8])
            * (11.0 - difficulty)
            * pow(stability, -weights[9])
            * (exp(weights[10] * (1.0 - r)) - 1.0)
            * hardPenalty
            * easyBonus)
        return Self.round8(clampStability(result))
    }

    // MARK: Stability after a lapse

    /// Stability after an Again with at least one day elapsed.
    func forgetStability(difficulty: Double, stability: Double, retrievability r: Double) -> Double {
        let result = weights[11]
            * pow(difficulty, -weights[12])
            * (pow(stability + 1.0, weights[13]) - 1.0)
            * exp(weights[14] * (1.0 - r))
        return Self.round8(clampStability(result))
    }

    // MARK: Stability after a same-day review

    /// Stability after a same-day review (`t == 0`) in short-term mode. The
    /// `S^(-w[19])` term (new in v6) damps repeated same-day growth. For
    /// Hard/Good/Easy the multiplier can't fall below 1, so stability never
    /// drops on a passing same-day review.
    func shortTermStability(stability: Double, rating: Rating) -> Double {
        let g = Double(rating.rawValue)
        var multiplier = pow(stability, -weights[19]) * exp(weights[17] * (g - 3.0 + weights[18]))
        if rating >= .hard {
            multiplier = max(multiplier, 1.0)
        }
        return Self.round8(clampStability(stability * multiplier))
    }

    // MARK: Interval

    /// Converts stability to a whole-day interval, clamped to
    /// `[1, maximumInterval]`.
    func interval(stability: Double) -> Int {
        let raw = stability * intervalModifier
        let rounded = raw.rounded(.toNearestOrAwayFromZero)
        return Int(min(max(rounded, 1.0), Double(maximumInterval)))
    }

    // MARK: Dispatch

    /// Computes the next stability/difficulty pair for a card, dispatching to
    /// the right formula based on whether the card is new, reviewed same-day,
    /// lapsing, or being recalled after a day or more.
    func nextState(
        stability: Double,
        difficulty: Double,
        elapsed: Int,
        rating: Rating
    ) -> (stability: Double, difficulty: Double) {
        // New card: no prior memory state.
        if stability < Self.minStability && difficulty < Self.minDifficulty {
            return (initialStability(rating), initialDifficulty(rating))
        }

        let r = retrievability(elapsed: Double(elapsed), stability: stability)
        let newDifficulty = nextDifficulty(current: difficulty, rating: rating)
        let newStability: Double

        if elapsed == 0 && enableShortTerm {
            newStability = shortTermStability(stability: stability, rating: rating)
        } else if rating == .again {
            let forgotten = forgetStability(difficulty: difficulty, stability: stability, retrievability: r)
            // Floor that prevents relearning steps from later inflating stability
            // back above the pre-lapse value. In long-term mode there are no
            // such steps, so the floor is simply the pre-lapse stability.
            let floor = enableShortTerm
                ? stability / exp(weights[17] * weights[18])
                : stability
            let roundedFloor = Self.round8(floor)
            newStability = min(max(roundedFloor, Self.minStability), forgotten)
        } else {
            newStability = recallStability(
                difficulty: difficulty, stability: stability, retrievability: r, rating: rating
            )
        }

        return (newStability, newDifficulty)
    }

    // MARK: Clamping

    private func clampStability(_ value: Double) -> Double {
        min(max(value, Self.minStability), Self.maxStability)
    }

    private func clampDifficulty(_ value: Double) -> Double {
        min(max(value, Self.minDifficulty), Self.maxDifficulty)
    }
}
