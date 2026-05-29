//
//  TranslationProviderTests.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.05.28.
//

import CoreData
import Foundation
import Testing
@testable import KaifangCore

// MARK: - Tests

@Suite
struct TranslationProviderTests {
    let container: NSPersistentContainer
    let repository: TranslationRepository
    private let modelProvider: StubModelProvider
    let provider: TranslationProvider

    init() {
        container = PersistenceController.getTestingContainer()
        repository = TranslationRepository(container: container)
        modelProvider = StubModelProvider(response: Self.modelTranslation)
        provider = TranslationProvider(repository: repository, modelProvider: modelProvider)
    }

    // MARK: Fixtures

    private static let sampleLookup = TranslationProvider.LookupArguments(
        originalText: "Hello",
        originalTextLang: .init(identifier: "en-Latn-US"),
        originalTextContext: nil,
        translatedTextLang: .init(identifier: "zh-Hans-CN")
    )

    /// The model's answer for `sampleLookup` — original fields match the query,
    /// as a real provider's would. Maximal language identifiers keep the
    /// `repository.save` round-trip lossless for equality assertions.
    private static let modelTranslation = TranslationProvider.Translation(
        id: UUID(),
        originalText: "Hello",
        originalTextLang: .init(identifier: "en-Latn-US"),
        originalTextContext: nil,
        translatedText: "你好 (from model)",
        translatedTextLang: .init(identifier: "zh-Hans-CN")
    )

    // MARK: Tests

    @Test("Translation tries getting from repository first")
    func translateTriesRepositoryFirst() async throws {
        let cached = try await repository.save(TranslationProvider.Translation(
            id: UUID(),
            originalText: "Hello",
            originalTextLang: .init(identifier: "en-Latn-US"),
            originalTextContext: nil,
            translatedText: "你好 (cached)",
            translatedTextLang: .init(identifier: "zh-Hans-CN")
        ))

        let result = try await provider.translate(Self.sampleLookup)

        #expect(result == cached)

        let received = await modelProvider.receivedQueries
        #expect(received.isEmpty)
    }

    @Test("Translation tries model provider if no translation in repository")
    func translateTriesModelProviderIfNoTranslationInRepository() async throws {
        let result = try await provider.translate(Self.sampleLookup)

        let received = await modelProvider.receivedQueries
        #expect(received == [Self.sampleLookup])
        #expect(result == Self.modelTranslation)
    }

    @Test("Translation saves in repository after getting from model provider")
    func translateSavesIntoRepository() async throws {
        let result = try await provider.translate(Self.sampleLookup)

        let persisted = try await repository.find(id: result.id)
        #expect(persisted == result)

        let looked = try await repository.lookup(Self.sampleLookup)
        #expect(looked == result)
    }
}

// MARK: - Stub model provider

private actor StubModelProvider: TranslationModel.Provider {
    private(set) var receivedQueries: [TranslationProvider.LookupArguments] = []
    private let response: TranslationProvider.Translation

    init(response: TranslationProvider.Translation) {
        self.response = response
    }

    func translate(_ query: TranslationProvider.LookupArguments) async throws -> TranslationProvider.Translation {
        receivedQueries.append(query)
        return response
    }
}
