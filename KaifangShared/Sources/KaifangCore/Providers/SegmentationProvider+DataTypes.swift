//
//  SegmentationProvider+DataTypes.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.05.29.
//

import Foundation

public extension SegmentationProvider {
    /// Maps to ``CDArticleWordToken``.
    struct WordToken: Equatable, Sendable {
        let id: UUID
        let tokenText: String
        let sentenceTextPositionStart: Int32
        let wordIndexInSentence: Int32
    }
    
    /// Maps to ``CDArticleSentenceToken``.
    struct SentenceToken: Equatable, Sendable {
        let id: UUID
        let articleTextPositionStart: Int32
        let sentenceIndexInArticle: Int32
        let tokenText: String
    }
}
