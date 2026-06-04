//
//  FSRSWeights.swift
//  KaifangSpacedRepetition
//
//  Created by Brendan Chen on 2026.06.03.
//

import Foundation

/// The 21 trainable weights of FSRS-6.
///
/// The defaults are the published FSRS-6 values, pre-trained on aggregate
/// review data. A host can substitute weights produced by the FSRS optimizer.
/// Out-of-range values are clamped on construction to the bounds the FSRS-6
/// specification enforces, so the algorithm never sees a degenerate weight.
///
/// Weight roles, by index:
/// - `0…3`  initial stability for Again/Hard/Good/Easy
/// - `4,5`  initial difficulty (base, slope)
/// - `6,7`  difficulty update (change rate, mean-reversion weight)
/// - `8…10` stability after successful recall
/// - `11…14` stability after a lapse
/// - `15`   Hard penalty, `16` Easy bonus
/// - `17,18` short-term (same-day) stability
/// - `19`   short-term dampening (new in v6)
/// - `20`   forgetting-curve decay (new in v6; was fixed at 0.5 in v5)
public struct FSRSWeights: Sendable, Codable, Equatable {

    /// The number of weights in FSRS-6.
    public static let count = 21

    /// The clamped weight values.
    public private(set) var values: [Double]

    /// The published FSRS-6 default weights.
    public static let `default` = FSRSWeights(values: [
        0.212, 1.2931, 2.3065, 8.2956,
        6.4133, 0.8334,
        3.0194, 0.001,
        1.8722, 0.1666, 0.796,
        1.4835, 0.0614, 0.2629, 1.6483,
        0.6014, 1.8729,
        0.5425, 0.0912,
        0.0658,
        0.1542,
    ])

    /// Builds weights from a raw array of exactly 21 finite values, clamping
    /// each to its FSRS-6 valid range.
    public init(values: [Double]) {
        precondition(
            values.count == Self.count,
            "FSRS-6 requires exactly \(Self.count) weights, received \(values.count)"
        )
        precondition(
            values.allSatisfy { $0.isFinite },
            "FSRS weights must be finite (no NaN or infinity)"
        )
        self.values = values
        clamp()
    }

    public subscript(index: Int) -> Double {
        get { values[index] }
        set {
            values[index] = newValue
            clamp()
        }
    }

    /// Per-weight valid ranges from the FSRS-6 specification.
    private static let ranges: [ClosedRange<Double>] = [
        0.001...100.0,  // 0: S0(Again)
        0.001...100.0,  // 1: S0(Hard)
        0.001...100.0,  // 2: S0(Good)
        0.001...100.0,  // 3: S0(Easy)
        1.0...10.0,     // 4: D0 base
        0.001...4.0,    // 5: D0 slope
        0.001...4.0,    // 6: difficulty change rate
        0.001...0.75,   // 7: mean-reversion weight
        0.0...4.5,      // 8: recall stability exp factor
        0.0...0.8,      // 9: recall stability S power
        0.001...3.5,    // 10: recall stability R exponent
        0.001...5.0,    // 11: lapse stability multiplier
        0.001...0.25,   // 12: lapse stability D power
        0.001...0.9,    // 13: lapse stability S power
        0.0...4.0,      // 14: lapse stability R exponent
        0.0...1.0,      // 15: Hard penalty
        1.0...6.0,      // 16: Easy bonus
        0.0...2.0,      // 17: short-term exponent
        0.0...2.0,      // 18: short-term rating offset
        0.0...0.8,      // 19: short-term dampening
        0.1...0.8,      // 20: forgetting-curve decay
    ]

    private mutating func clamp() {
        for i in values.indices {
            let range = Self.ranges[i]
            values[i] = min(max(values[i], range.lowerBound), range.upperBound)
        }
    }
}
