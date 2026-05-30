//
//  SegmentationProvider.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.05.29.
//

import NaturalLanguage

/// Provide word- and sentence-level segmentations using ``NLTokenizer``.
public final class SegmentationProvider {

    /// Seam over ``NLTokenizer``. Lets tests drive the orchestration in
    /// ``sentences(in:)`` with canned token ranges instead of invoking the
    /// real tokenizer.
    public protocol Tokenizer: Sendable {
        func tokens(unit: NLTokenUnit, in text: String) async -> [Range<String.Index>]
    }

    private let tokenizer: any Tokenizer

    public init() {
        self.tokenizer = NLTokenizerWrapper()
    }

    public init(tokenizer: any Tokenizer) {
        self.tokenizer = tokenizer
    }

    public func sentences(in text: String) async -> [SentenceToken] {
        let ranges = await tokenizer.tokens(unit: .sentence, in: text)
        var sentenceTokens: [SentenceToken] = []

        for i in 0..<ranges.count {
            let range = ranges[i]
            let tokenText = String(text[range])
            let words = await words(in: tokenText)

            sentenceTokens.append(
                SentenceToken(
                    id: UUID(),
                    articleTextPositionStart: Int32(range.lowerBound.utf16Offset(in: text)),
                    sentenceIndexInArticle: Int32(i),
                    tokenText: tokenText,
                    wordTokens: words
                )
            )
        }

        return sentenceTokens
    }

    private func words(in sentence: String) async -> [WordToken] {
        let ranges = await tokenizer.tokens(unit: .word, in: sentence)
        var wordTokens: [WordToken] = []

        for i in 0..<ranges.count {
            let range = ranges[i]
            wordTokens.append(
                WordToken(
                    id: UUID(),
                    tokenText: String(sentence[range]),
                    sentenceTextPositionStart: Int32(range.lowerBound.utf16Offset(in: sentence)),
                    wordIndexInSentence: Int32(i)
                )
            )
        }

        return wordTokens
    }

    private struct NLTokenizerWrapper: Tokenizer {
        func tokens(unit: NLTokenUnit, in text: String) async -> [Range<String.Index>] {
            let tokenizer = NLTokenizer(unit: unit)
            tokenizer.string = text
            return tokenizer.tokens(for: text.startIndex..<text.endIndex)
        }
    }
}
