//
//  State.swift
//  KaifangSpacedRepetition
//
//  Created by Brendan Chen on 2026.06.03.
//

/// Where a card sits in the FSRS state machine.
///
/// A card starts `.new`, moves through `.learning` (short same-session steps)
/// into `.review` (day-scale intervals), and drops to `.relearning` when it is
/// forgotten. Raw values match the FSRS specification.
public enum State: Int, Sendable, Codable, CaseIterable, CustomStringConvertible {
    /// Never reviewed.
    case new = 0
    /// Being learned for the first time, on sub-day steps.
    case learning = 1
    /// On the long-term review schedule.
    case review = 2
    /// Forgotten from `.review` and being re-learned on short steps.
    case relearning = 3

    public var description: String {
        switch self {
        case .new: "New"
        case .learning: "Learning"
        case .review: "Review"
        case .relearning: "Relearning"
        }
    }
}
