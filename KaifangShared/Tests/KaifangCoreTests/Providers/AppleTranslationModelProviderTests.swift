//
//  AppleTranslationModelProviderTests.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.05.27.
//

import Foundation
import Testing
@testable import KaifangCore

// MARK: - Tests

@Suite(.enabled(if: os26OrLater))
struct AppleTranslationModelProviderTests {
    @available(iOS 26.0, macOS 26.0, *)
    @Test("Translation model translates the original text if the refiner is unavailable")
    func translationModelTranslatesOriginalTextIfRefinerUnavailable() async throws {
        let translator = StubSystemTranslator(response: "TRANSLATED(hello)")
        let refiner = StubTranslationRefiner(isAvailable: false, response: "<should-not-be-used>")

        let provider = AppleTranslationModelProvider(translator: translator, refiner: refiner)

        let query = TranslationProvider.LookupArguments(
            originalText: "hello",
            originalTextLang: Locale.Language(identifier: "en"),
            originalTextContext: "Say hello to the world",
            translatedTextLang: Locale.Language(identifier: "es")
        )

        let result = try await provider.translate(query)

        #expect(result.translatedText == "TRANSLATED(hello)")

        let translatedTexts = await translator.receivedTexts
        #expect(translatedTexts == ["hello"])

        let refinerCalls = await refiner.receivedCalls
        #expect(refinerCalls.isEmpty)
    }

    @available(iOS 26.0, macOS 26.0, *)
    @Test("Translation model uses the refiner if it's available")
    func translationModelUsesRefinerIfAvailable() async throws {
        let translator = StubSystemTranslator(response: "TRANSLATED-CONTEXT")
        let refiner = StubTranslationRefiner(isAvailable: true, response: "EXTRACTED")

        let provider = AppleTranslationModelProvider(translator: translator, refiner: refiner)

        let query = TranslationProvider.LookupArguments(
            originalText: "hello",
            originalTextLang: Locale.Language(identifier: "en"),
            originalTextContext: "Say hello to the world",
            translatedTextLang: Locale.Language(identifier: "es")
        )

        let result = try await provider.translate(query)

        #expect(result.translatedText == "EXTRACTED")

        let translatedTexts = await translator.receivedTexts
        #expect(translatedTexts == ["Say hello to the world"])

        let refinerCalls = await refiner.receivedCalls
        #expect(refinerCalls.count == 1)
        #expect(refinerCalls.first?.originalText == "hello")
        #expect(refinerCalls.first?.translatedContext == "TRANSLATED-CONTEXT")
        #expect(refinerCalls.first?.originalContext == "Say hello to the world")
    }
}

// MARK: - Test doubles

@available(iOS 26.0, macOS 26.0, *)
private actor StubSystemTranslator: AppleTranslationModelProvider.SystemTranslator {
    private(set) var receivedTexts: [String] = []
    private let response: String

    init(response: String) {
        self.response = response
    }

    func translate(
        _ text: String,
        from source: Locale.Language,
        to target: Locale.Language
    ) async throws -> String {
        receivedTexts.append(text)
        return response
    }
}

@available(iOS 26.0, macOS 26.0, *)
private actor StubTranslationRefiner: AppleTranslationModelProvider.TranslationRefiner {
    struct Call: Sendable {
        let originalText: String
        let translatedContext: String
        let originalContext: String
        let targetLang: Locale.Language
    }

    nonisolated let isAvailable: Bool
    private(set) var receivedCalls: [Call] = []
    private let response: String

    init(isAvailable: Bool, response: String) {
        self.isAvailable = isAvailable
        self.response = response
    }

    func extractTranslation(
        of originalText: String,
        translatedContext: String,
        originalContext: String,
        targetLang: Locale.Language
    ) async throws -> String {
        receivedCalls.append(Call(
            originalText: originalText,
            translatedContext: translatedContext,
            originalContext: originalContext,
            targetLang: targetLang
        ))
        return response
    }
}

private var os26OrLater: Bool {
    if #available(iOS 26.0, macOS 26.0, *) { true } else { false }
}
