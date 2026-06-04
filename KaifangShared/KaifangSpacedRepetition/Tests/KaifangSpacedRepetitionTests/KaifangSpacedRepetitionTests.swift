//
//  KaifangSpacedRepetitionTests.swift
//  KaifangSpacedRepetition
//
//  Created by Brendan Chen on 2026.06.03.
//
//  Root test file. Shared fixtures and helpers live here; the individual
//  suites live in sibling files. The numeric expectations across this suite
//  are copied byte-for-byte from the canonical ts-fsrs test suite
//  (packages/fsrs/__tests__/algorithm.test.ts and FSRS-6.test.ts). A failure
//  means the implementation has drifted from the FSRS-6 reference — fix the
//  code, not the expectation.
//

import Foundation
import Testing

@testable import KaifangSpacedRepetition

/// A fixed reference instant for deterministic tests (≈ 2026-05-09 06:13:20 UTC).
/// Chosen so that reviewing at `card.due` keeps the time-of-day fixed, making
/// `Card.elapsedDays(now:)` equal the previous `scheduledDays` exactly.
let refDate = Date(timeIntervalSinceReferenceDate: 800_000_000)

/// A date `days` after ``refDate``.
func dateAfter(days: Double) -> Date {
    refDate.addingTimeInterval(days * 86_400.0)
}

/// Asserts two doubles agree within `tolerance`.
func expectApprox(
    _ actual: Double,
    _ expected: Double,
    tolerance: Double = 1e-8,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    #expect(
        abs(actual - expected) <= tolerance,
        "\(actual) ≠ \(expected) (±\(tolerance))",
        sourceLocation: sourceLocation
    )
}

/// Asserts two dates are identical to the second.
func expectExactDue(
    _ actual: Date,
    _ expected: Date,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    #expect(
        actual.timeIntervalSinceReferenceDate == expected.timeIntervalSinceReferenceDate,
        "due mismatch: \(actual) ≠ \(expected)",
        sourceLocation: sourceLocation
    )
}
