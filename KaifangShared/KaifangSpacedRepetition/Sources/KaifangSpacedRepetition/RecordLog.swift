//
//  RecordLog.swift
//  KaifangSpacedRepetition
//
//  Created by Brendan Chen on 2026.06.03.
//

/// The result of applying (or previewing) a single grade: the updated card and
/// the log entry recording the review that produced it.
public struct RecordLogItem: Sendable, Codable, Equatable {
    /// The card after the review.
    public let card: Card
    /// The log entry describing the review.
    public let log: ReviewLog

    public init(card: Card, log: ReviewLog) {
        self.card = card
        self.log = log
    }
}

/// The four possible outcomes of reviewing a card, keyed by grade.
///
/// Returned by ``FSRS/repeat(card:now:)`` so a UI can show the next due date
/// for every button before the learner picks one. Every grade is always
/// present, so force-unwrapping a key is safe.
public typealias RecordLog = [Rating: RecordLogItem]
