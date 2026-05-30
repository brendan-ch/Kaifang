//
//  SegmentationProviderTests.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.05.29.
//

import Testing
@testable import KaifangCore
import NaturalLanguage

// MARK: - Tests

struct SegmentationProviderTests {
    fileprivate let tokenizer: StubTokenizer
    let provider: SegmentationProvider

    init() {
        tokenizer = StubTokenizer()
        provider = SegmentationProvider(tokenizer: tokenizer)
    }

    @Test("Sentence segmentation tokenizes sentences and words")
    func sentenceSegmentationTokenizesSentencesAndWords() async throws {
        let text = "Hello world. Foo bar."
        let firstSentence = try #require(text.range(of: "Hello world."))
        let secondSentence = try #require(text.range(of: "Foo bar."))
        tokenizer.sentenceRanges = { _ in [firstSentence, secondSentence] }
        tokenizer.wordRanges = { sentence in
            switch sentence {
            case "Hello world.":
                return [
                    sentence.range(of: "Hello")!,
                    sentence.range(of: "world")!,
                ]
            case "Foo bar.":
                return [
                    sentence.range(of: "Foo")!,
                    sentence.range(of: "bar")!,
                ]
            default:
                return []
            }
        }

        let result = await provider.sentences(in: text)

        try #require(result.count == 2)
        #expect(result.map(\.tokenText) == ["Hello world.", "Foo bar."])
        #expect(result.map(\.sentenceIndexInArticle) == [0, 1])
        #expect(result[0].wordTokens.map(\.tokenText) == ["Hello", "world"])
        #expect(result[1].wordTokens.map(\.tokenText) == ["Foo", "bar"])
    }
}

// MARK: - Private stubs

private final class StubTokenizer: SegmentationProvider.Tokenizer, @unchecked Sendable {
    var sentenceRanges: (String) -> [Range<String.Index>] = { _ in [] }
    var wordRanges: (String) -> [Range<String.Index>] = { _ in [] }

    func tokens(unit: NLTokenUnit, in text: String) async -> [Range<String.Index>] {
        switch unit {
        case .sentence: return sentenceRanges(text)
        case .word: return wordRanges(text)
        default: return []
        }
    }
}
