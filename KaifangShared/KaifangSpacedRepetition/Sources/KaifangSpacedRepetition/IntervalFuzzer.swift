//
//  IntervalFuzzer.swift
//  KaifangSpacedRepetition
//
//  Created by Brendan Chen on 2026.06.03.
//

import Foundation

/// Spreads day-scale intervals over a small window so cards with identical
/// histories don't all come due on the same day.
///
/// The window widens with the interval. Randomness comes from a seeded
/// ``Alea`` generator, so a stable seed (derived from the card's state)
/// produces a stable, reproducible result.
enum IntervalFuzzer {

    /// Fuzzes `interval` (in days) within its computed window, never below
    /// `elapsedDays + 1` once the interval has grown past the elapsed time, and
    /// never above `maximumInterval`. Intervals shorter than three days are
    /// returned unchanged.
    static func fuzz(interval: Int, elapsedDays: Int, maximumInterval: Int, seed: String) -> Int {
        guard interval >= 3 else { return interval }

        let value = Double(interval)
        var delta = 1.0
        delta += 0.15 * max(min(value, 7.0) - 2.5, 0)
        delta += 0.10 * max(min(value, 20.0) - 7.0, 0)
        delta += 0.05 * max(value - 20.0, 0)

        var lower = max(2, Int((value - delta).rounded(.toNearestOrAwayFromZero)))
        let upper = min(Int((value + delta).rounded(.toNearestOrAwayFromZero)), maximumInterval)
        if interval > elapsedDays {
            lower = max(lower, elapsedDays + 1)
        }
        lower = min(lower, upper)

        var generator = Alea(seed: seed)
        let sample = generator.next()
        let span = Double(upper - lower + 1)
        // Floor (not round) over the half-open window, matching the reference.
        return Int((sample * span + Double(lower)).rounded(.down))
    }
}
