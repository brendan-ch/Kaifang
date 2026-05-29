//
//  PronunciationProviderTests.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.05.28.
//

import Foundation
import Testing
@testable import KaifangCore

// MARK: - Tests

@Suite
struct PronunciationProviderTests {
    /// A small CC-CEDICT excerpt covering comments, simplified/traditional
    /// divergence, and a heteronym (重).
    private static let corpus = """
    # CC-CEDICT
    #! version=1
    中國 中国 [Zhong1 guo2] /China/Middle Kingdom/
    重 重 [chong2] /to repeat/repetition/
    重 重 [zhong4] /heavy/serious/to attach importance to/
    你好 你好 [ni3 hao3] /hello/hi/
    漢字 汉字 [Han4 zi4] /Chinese character/CL:個|个[ge4]/
    """

    private func makeProvider(
        _ text: String = corpus
    ) -> (PronunciationProvider, StubDictionarySource) {
        let source = StubDictionarySource(text: text)
        return (PronunciationProvider(source: source), source)
    }

    @Test("Returns numbered pinyin for a simplified headword")
    func returnsPinyinForSimplifiedHeadword() async throws {
        let (provider, _) = makeProvider()

        let result = try await provider.pronunciations(for: "中国")

        #expect(result == [
            PronunciationProvider.Pronunciation(
                simplified: "中国",
                traditional: "中國",
                system: .numberedPinyin,
                value: "Zhong1 guo2"
            ),
        ])
    }

    @Test("Returns numbered pinyin when looked up by traditional headword")
    func returnsPinyinForTraditionalHeadword() async throws {
        let (provider, _) = makeProvider()

        let result = try await provider.pronunciations(for: "漢字")

        #expect(result == [
            PronunciationProvider.Pronunciation(
                simplified: "汉字",
                traditional: "漢字",
                system: .numberedPinyin,
                value: "Han4 zi4"
            ),
        ])
    }

    @Test("Returns every pronunciation for a heteronym")
    func returnsMultiplePronunciationsForHeteronym() async throws {
        let (provider, _) = makeProvider()

        let result = try await provider.pronunciations(for: "重")

        #expect(result.map(\.value) == ["chong2", "zhong4"])
    }

    @Test("Returns an empty array for an unknown word")
    func returnsEmptyForUnknownWord() async throws {
        let (provider, _) = makeProvider()

        let result = try await provider.pronunciations(for: "蛋糕")

        #expect(result.isEmpty)
    }

    @Test("Skips comment and metadata lines")
    func skipsCommentLines() async throws {
        let (provider, _) = makeProvider()

        // The leading "# CC-CEDICT" / "#! version=1" lines must not become entries.
        #expect(try await provider.pronunciations(for: "#").isEmpty)
        #expect(try await provider.pronunciations(for: "CC-CEDICT").isEmpty)
        // ...and a valid lookup still resolves, proving the comments were tolerated.
        #expect(try await provider.pronunciations(for: "你好").map(\.value) == ["ni3 hao3"])
    }

    @Test("Parses the dictionary source only once across lookups")
    func parsesSourceOnlyOnce() async throws {
        let (provider, source) = makeProvider()

        _ = try await provider.pronunciations(for: "中国")
        _ = try await provider.pronunciations(for: "你好")
        _ = try await provider.pronunciations(for: "重")

        #expect(await source.loadCount == 1)
    }

    @Test("Defaults to numbered pinyin")
    func defaultsToNumberedPinyin() async throws {
        let (provider, _) = makeProvider()

        let result = try await provider.pronunciations(for: "中国")

        #expect(result.allSatisfy { $0.system == .numberedPinyin })
    }

    @Test(
        "Throws for systems that aren't implemented yet",
        arguments: [PronunciationProvider.System.toneMarkPinyin, .zhuyin]
    )
    func throwsForUnsupportedSystem(system: PronunciationProvider.System) async throws {
        let (provider, _) = makeProvider()

        await #expect(throws: PronunciationProvider.Error.self) {
            _ = try await provider.pronunciations(for: "中国", system: system)
        }
    }

    @Test("Loads the bundled CC-CEDICT dictionary and resolves a common word")
    func loadsBundledDictionary() async throws {
        // Exercises the production BundledCEDICTSource against the real resource,
        // verifying it is bundled and parseable at runtime.
        let provider = PronunciationProvider()

        let result = try await provider.pronunciations(for: "中国")

        #expect(result.contains { $0.value == "Zhong1 guo2" })
    }
}

// MARK: - Test doubles

private actor StubDictionarySource: PronunciationProvider.DictionarySource {
    private(set) var loadCount = 0
    private let text: String

    init(text: String) {
        self.text = text
    }

    func loadText() async throws -> String {
        loadCount += 1
        return text
    }
}
