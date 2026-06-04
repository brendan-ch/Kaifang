//
//  FSRSParameters.swift
//  KaifangSpacedRepetition
//
//  Created by Brendan Chen on 2026.06.03.
//

import Foundation

/// Configuration for an ``FSRS`` scheduler.
///
/// Bundles the retention target, interval cap, learning steps, fuzz toggle,
/// and the 21 trainable ``FSRSWeights``. Construct once and reuse — `FSRS` is
/// a value type built from these parameters.
public struct FSRSParameters: Sendable, Codable {

    /// Target probability of recall when a card comes due. Default 0.9. Clamped
    /// to `[0.01, 0.99]`; lower values produce shorter intervals.
    public var requestRetention: Double

    /// Hard cap on any scheduled interval, in whole days. Default 36500.
    public var maximumInterval: Int

    /// The 21 FSRS-6 weights.
    public var weights: FSRSWeights

    /// Whether to apply deterministic fuzz to day-scale intervals so that
    /// cards with identical histories don't all fall due on the same day.
    /// Off by default.
    public var enableFuzz: Bool

    /// Whether new and lapsed cards pass through sub-day learning steps before
    /// graduating to day-scale intervals. On by default (the "basic"
    /// scheduler). When off, every review goes straight to `.review` with an
    /// FSRS-computed interval (the "long-term" scheduler).
    public var enableShortTerm: Bool

    /// Sub-day steps (in seconds) for learning a new card. Default `[60, 600]`
    /// — one minute, then ten minutes.
    public var learningSteps: [TimeInterval]

    /// Sub-day steps (in seconds) for re-learning a lapsed card. Default
    /// `[600]` — ten minutes.
    public var relearningSteps: [TimeInterval]

    public init(
        requestRetention: Double = 0.9,
        maximumInterval: Int = 36500,
        weights: FSRSWeights = .default,
        enableFuzz: Bool = false,
        enableShortTerm: Bool = true,
        learningSteps: [TimeInterval] = [60, 600],
        relearningSteps: [TimeInterval] = [600]
    ) {
        self.requestRetention = min(max(requestRetention, 0.01), 0.99)
        self.maximumInterval = max(1, maximumInterval)
        self.weights = weights
        self.enableFuzz = enableFuzz
        self.enableShortTerm = enableShortTerm
        self.learningSteps = learningSteps
        self.relearningSteps = relearningSteps

        applyContextDependentWeightBounds()
    }

    /// Two weight bounds in FSRS-6 depend on scheduler context rather than on
    /// the weight alone, so they are applied here rather than in ``FSRSWeights``:
    ///
    /// - With more than one relearning step, the upper bound on `w[17]` and
    ///   `w[18]` is tightened so relearning steps can't push stability above
    ///   the pre-lapse value.
    /// - With short-term mode enabled, `w[19]` has a floor of `0.01` so the
    ///   `S^(-w[19])` dampening term isn't the identity for same-day reviews.
    private mutating func applyContextDependentWeightBounds() {
        let stepCount = relearningSteps.count
        if stepCount > 1 {
            let w = weights
            let numerator = -(log(w[11]) + log(pow(2.0, w[13]) - 1.0) + w[14] * 0.3)
            let ceiling = min(max(numerator / Double(stepCount), 0.01), 2.0)
            if weights[17] > ceiling { weights[17] = ceiling }
            if weights[18] > ceiling { weights[18] = ceiling }
        }
        if enableShortTerm && weights[19] < 0.01 {
            weights[19] = 0.01
        }
    }
}
