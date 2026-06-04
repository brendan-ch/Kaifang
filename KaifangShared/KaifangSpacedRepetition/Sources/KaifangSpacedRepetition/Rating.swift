//
//  Rating.swift
//  KaifangSpacedRepetition
//
//  Created by Brendan Chen on 2026.06.03.
//

/// The grade a learner assigns when reviewing a card.
///
/// The raw values match the FSRS specification (Again = 1 … Easy = 4). The
/// algorithm indexes the weight array and branches on these values, so the
/// numbering is load-bearing — do not renumber. FSRS reserves `0` for a
/// "manual" grade used by bulk operations; this package models manual
/// rescheduling through ``FSRS/forget(card:now:resetCount:)`` instead of a
/// rating, so `0` is intentionally absent here.
public enum Rating: Int, Sendable, Codable, CaseIterable, Comparable, CustomStringConvertible {
    /// The learner failed to recall the card.
    case again = 1
    /// Recalled, but only with serious effort.
    case hard = 2
    /// Recalled with the expected amount of effort.
    case good = 3
    /// Recalled instantly.
    case easy = 4

    public static func < (lhs: Rating, rhs: Rating) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public var description: String {
        switch self {
        case .again: "Again"
        case .hard: "Hard"
        case .good: "Good"
        case .easy: "Easy"
        }
    }
}
