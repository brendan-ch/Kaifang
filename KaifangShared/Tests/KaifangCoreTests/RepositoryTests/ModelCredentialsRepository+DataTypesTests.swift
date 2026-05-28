//
//  ModelCredentialsRepositoryTests.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.05.27.
//

import CoreData
import Foundation
import Testing
@testable import KaifangCore

@Suite
struct ModelCredentialsTests {
    // MARK: Setup
    private let context: NSManagedObjectContext

    init() async throws {
        context = PersistenceController.getTestingContext()
    }

    // MARK: Data helpers
    private func makeAnthropicCredentials(
        id: UUID = UUID(),
        model: String = "claude-sonnet-4.5",
        apiKey: String = "test-api-key"
    ) -> ModelCredentialsRepository.ModelCredentials {
        ModelCredentialsRepository.ModelCredentials(
            id: id,
            internalMetadata: ModelCredentialsRepository.AnthropicInternalMetadata(model: model),
            secureData: ModelCredentialsRepository.AnthropicSecureData(apiKey: apiKey)
        )
    }

    // MARK: toCoreData tests
    @Test("ModelCredentials converts correctly to a Core Data entity")
    func modelCredentialsConvertsToCoreData() async throws {
        let credentials = makeAnthropicCredentials(model: "claude-haiku-4-5")
        let entity = try credentials.toCoreData(context: context)

        #expect(entity.id == credentials.id)
        #expect(entity.typeRaw == ModelCredentialsRepository.AnthropicInternalMetadata.coreDataRawType)

        let metadataJson = try #require(entity.metadataJson)
        let decodedMetadata = try JSONDecoder().decode(
            ModelCredentialsRepository.AnthropicInternalMetadata.self,
            from: metadataJson
        )
        #expect(decodedMetadata.model == "claude-haiku-4-5")
    }

    @Test("ModelCredentials rethrows JSON encoding errors when converting to Core Data")
    func modelCredentialsToCoreDataRethrowsJsonError() async throws {
        let credentials = ModelCredentialsRepository.ModelCredentials(
            id: UUID(),
            internalMetadata: ThrowingInternalMetadata(),
            secureData: nil
        )

        #expect(throws: ThrowingInternalMetadata.IntentionalError.self) {
            _ = try credentials.toCoreData(context: context)
        }
    }

    // MARK: fromCoreDataAndSecureData tests
    @Test("fromCoreDataAndSecureData converts from Core Data and secure data with existing metadata in both")
    func fromCoreDataAndSecureDataConvertsFromCoreDataAndSecureData() async throws {
        let id = UUID()
        let metadata = ModelCredentialsRepository.AnthropicInternalMetadata(model: "claude-sonnet-4.5")
        let secureData = ModelCredentialsRepository.AnthropicSecureData(apiKey: "test-api-key")

        let entity = CDTranslationModelCredential(context: context)
        entity.id = id
        entity.typeRaw = ModelCredentialsRepository.AnthropicInternalMetadata.coreDataRawType
        entity.metadataJson = try JSONEncoder().encode(metadata)

        let secureDataBlob = try JSONEncoder().encode(secureData)

        let credentials = try ModelCredentialsRepository.ModelCredentials.fromCoreDataAndSecureData(
            entity,
            secureData: secureDataBlob
        )

        #expect(credentials.id == id)
        let decodedMetadata = try #require(
            credentials.internalMetadata as? ModelCredentialsRepository.AnthropicInternalMetadata
        )
        #expect(decodedMetadata.model == "claude-sonnet-4.5")
        let decodedSecureData = try #require(
            credentials.secureData as? ModelCredentialsRepository.AnthropicSecureData
        )
        #expect(decodedSecureData.apiKey == "test-api-key")
    }

    @Test("fromCoreDataAndSecureData converts from Core Data and empty secure data")
    func fromCoreDataAndSecureDataDecodesWithoutSecureData() async throws {
        let id = UUID()
        let metadata = ModelCredentialsRepository.AnthropicInternalMetadata(model: "claude-sonnet-4.5")

        let entity = CDTranslationModelCredential(context: context)
        entity.id = id
        entity.typeRaw = ModelCredentialsRepository.AnthropicInternalMetadata.coreDataRawType
        entity.metadataJson = try JSONEncoder().encode(metadata)

        let credentials = try ModelCredentialsRepository.ModelCredentials.fromCoreDataAndSecureData(
            entity,
            secureData: nil
        )

        #expect(credentials.id == id)
        let decodedMetadata = try #require(
            credentials.internalMetadata as? ModelCredentialsRepository.AnthropicInternalMetadata
        )
        #expect(decodedMetadata.model == "claude-sonnet-4.5")
        #expect(credentials.secureData == nil)
    }

    @Test("fromCoreDataAndSecureData automatically creates blank internal metadata if no metadata exists from Core Data")
    func modelCredentialsCreatesBlankDataIfNoMetadataFromCoreData() async throws {
        let id = UUID()

        let entity = CDTranslationModelCredential(context: context)
        entity.id = id
        entity.typeRaw = ModelCredentialsRepository.AnthropicInternalMetadata.coreDataRawType
        entity.metadataJson = nil

        let credentials = try ModelCredentialsRepository.ModelCredentials.fromCoreDataAndSecureData(
            entity,
            secureData: nil
        )

        #expect(credentials.id == id)
        let decodedMetadata = try #require(
            credentials.internalMetadata as? ModelCredentialsRepository.AnthropicInternalMetadata
        )
        #expect(decodedMetadata.model == ModelCredentialsRepository.AnthropicInternalMetadata.defaultModel)
    }

    @Test("fromCoreDataAndSecureData rethrows JSON decoding errors when converting from Core Data")
    func fromCoreDataAndSecureDataRethrowsJsonDecodingErrorsForCoreData() async throws {
        let entity = CDTranslationModelCredential(context: context)
        entity.id = UUID()
        entity.typeRaw = ModelCredentialsRepository.AnthropicInternalMetadata.coreDataRawType
        entity.metadataJson = Data("not valid json".utf8)

        #expect(throws: DecodingError.self) {
            _ = try ModelCredentialsRepository.ModelCredentials.fromCoreDataAndSecureData(
                entity,
                secureData: nil
            )
        }
    }

    @Test("fromCoreDataAndSecureData rethrows JSON decoding errors when converting from secure data")
    func fromCoreDataAndSecureDataRethrowsJsonDecodingErrorsForSecureData() async throws {
        let metadata = ModelCredentialsRepository.AnthropicInternalMetadata()

        let entity = CDTranslationModelCredential(context: context)
        entity.id = UUID()
        entity.typeRaw = ModelCredentialsRepository.AnthropicInternalMetadata.coreDataRawType
        entity.metadataJson = try JSONEncoder().encode(metadata)

        #expect(throws: DecodingError.self) {
            _ = try ModelCredentialsRepository.ModelCredentials.fromCoreDataAndSecureData(
                entity,
                secureData: Data("not valid json".utf8)
            )
        }
    }
}

// MARK: - Test doubles

private struct ThrowingInternalMetadata: ModelCredentialsRepository.ModelInternalMetadata {
    static let coreDataRawType: String = "throwing"

    enum IntentionalError: Swift.Error { case intentional }

    init() {}

    init(from decoder: Decoder) throws {
        throw IntentionalError.intentional
    }

    func encode(to encoder: Encoder) throws {
        throw IntentionalError.intentional
    }
}
