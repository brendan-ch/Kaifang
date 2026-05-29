//
//  ModelCredentialsRepositoryTests.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.05.28.
//

import Foundation
import Testing
import CoreData
@testable import KaifangCore

@Suite(.serialized)
final class ModelCredentialsRepositoryTests {
    let container: NSPersistentContainer
    let repository: ModelCredentialsRepository
    let defaults: UserDefaults
    let keychainProvider: ModelCredentialsRepository.KeychainProvider
    let suiteName: String

    init() async throws {
        container = try PersistenceController.getTestingContainer()
        keychainProvider = InMemoryKeychainProvider()
        let suiteName = "test.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
        self.suiteName = suiteName
        repository = ModelCredentialsRepository(
            container: container,
            keychainProvider: keychainProvider,
            defaults: defaults
        )
    }

    deinit {
        defaults.removePersistentDomain(forName: suiteName)
    }

    // MARK: Data helpers

    private static let defaultModel = "claude-haiku-3.5"

    private func makeAnthropic(
        id: UUID = UUID(),
        model: String = ModelCredentialsRepositoryTests.defaultModel,
        apiKey: String = "test-api-key"
    ) -> ModelCredentialsRepository.ModelCredentials {
        .init(
            id: id,
            internalMetadata: ModelCredentialsRepository.AnthropicInternalMetadata(model: model),
            secureData: ModelCredentialsRepository.AnthropicSecureData(apiKey: apiKey)
        )
    }

    /// An Anthropic credential whose secret has been stripped (Core Data metadata only).
    private func makeAnthropicWithoutSecret(
        id: UUID = UUID(),
        model: String = ModelCredentialsRepositoryTests.defaultModel
    ) -> ModelCredentialsRepository.ModelCredentials {
        .init(
            id: id,
            internalMetadata: ModelCredentialsRepository.AnthropicInternalMetadata(model: model),
            secureData: nil
        )
    }

    private func makeApple(id: UUID = UUID()) -> ModelCredentialsRepository.ModelCredentials {
        .init(
            id: id,
            internalMetadata: ModelCredentialsRepository.AppleInternalMetadata(),
            secureData: nil
        )
    }

    // MARK: Assertion helpers

    private func expectAnthropic(
        _ credential: ModelCredentialsRepository.ModelCredentials?,
        id: UUID,
        model: String,
        apiKey: String?
    ) {
        #expect(credential?.id == id)
        let metadata = credential?.internalMetadata as? ModelCredentialsRepository.AnthropicInternalMetadata
        #expect(metadata?.model == model)
        let secure = credential?.secureData as? ModelCredentialsRepository.AnthropicSecureData
        #expect(secure?.apiKey == apiKey)
    }

    /// Fetches the Core Data row directly (independently of the repository) to assert persistence.
    private func fetchEntity(id: UUID) throws -> CDTranslationModelCredential? {
        let request = NSFetchRequest<CDTranslationModelCredential>(entityName: "CDTranslationModelCredential")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try container.viewContext.fetch(request).first
    }

    private func countEntities() throws -> Int {
        let request = NSFetchRequest<CDTranslationModelCredential>(entityName: "CDTranslationModelCredential")
        return try container.viewContext.count(for: request)
    }

    // MARK: getCurrentlySelectedCredential / setCurrentlySelectedCredential

    @Test("Getting current model credentials retrieves the correct credentials")
    func getCurrentModelCredentialsGetsCorrectlyAfterSetting() async throws {
        let credential = makeAnthropic(apiKey: "key-1")
        _ = try await repository.save(credential)
        try await repository.setCurrentlySelectedCredential(credential.id)

        let current = try await repository.getCurrentlySelectedCredential()
        expectAnthropic(current, id: credential.id, model: Self.defaultModel, apiKey: "key-1")
    }

    @Test("Getting current model credentials retrieves correct credentials even with missing secure data")
    func getCurrentModelCredentialsRetrievesEvenWithNoSecureData() async throws {
        let credential = makeAnthropic(apiKey: "key-1")
        _ = try await repository.save(credential)
        try await repository.setCurrentlySelectedCredential(credential.id)
        try keychainProvider.delete(id: credential.id.uuidString)

        let current = try await repository.getCurrentlySelectedCredential()
        expectAnthropic(current, id: credential.id, model: Self.defaultModel, apiKey: nil)
    }

    @Test("Getting current model credentials returns nil if no Core Data credentials match the stored ID")
    func getCurrentModelCredentialsReturnsNilIfNoCredentialsForStoredKey() async throws {
        let credential = makeAnthropic()
        _ = try await repository.save(credential)
        try await repository.setCurrentlySelectedCredential(credential.id)
        try await repository.delete(credential.id)

        let current = try await repository.getCurrentlySelectedCredential()
        #expect(current == nil)
    }

    @Test("Getting current model credentials returns nil if stored ID set to nil")
    func getCurrentModelCredentialsReturnsNilIfNoStoredKey() async throws {
        let credential = makeAnthropic()
        _ = try await repository.save(credential)
        try await repository.setCurrentlySelectedCredential(credential.id)
        try await repository.setCurrentlySelectedCredential(nil)

        let current = try await repository.getCurrentlySelectedCredential()
        #expect(current == nil)
    }

    @Test("Setting current model credential ID sets correctly if credential exists")
    func setCurrentModelCredentialsSetsCorrectlyIfExists() async throws {
        let credential = makeAnthropic(apiKey: "key-1")
        _ = try await repository.save(credential)
        try await repository.setCurrentlySelectedCredential(credential.id)

        let current = try await repository.getCurrentlySelectedCredential()
        expectAnthropic(current, id: credential.id, model: Self.defaultModel, apiKey: "key-1")
    }

    @Test("Setting current model credential ID throws if no credential exists")
    func setCurrentModelCredentialsThrowsIfNoCredentialExists() async throws {
        await #expect(throws: ModelCredentialsRepository.Error.coreDataNotFound) {
            try await self.repository.setCurrentlySelectedCredential(UUID())
        }
    }

    @Test("Setting the current model credential ID sets correctly even with no secure data stored")
    func setCurrentModelCredentialsSetsCorrectlyWithNoSecureData() async throws {
        let credential = makeApple()
        _ = try await repository.save(credential)

        try await repository.setCurrentlySelectedCredential(credential.id)

        let current = try await repository.getCurrentlySelectedCredential()
        #expect(current?.id == credential.id)
        #expect((current?.internalMetadata as? ModelCredentialsRepository.AppleInternalMetadata) != nil)
        #expect(current?.secureData == nil)
    }

    // MARK: find

    @Test("Finding a credential by ID retrieves the correct credential")
    func findReturnsCorrectCredentialById() async throws {
        let credential = makeAnthropic(apiKey: "key-1")
        _ = try await repository.save(credential)

        let found = try await repository.find(credential.id)
        expectAnthropic(found, id: credential.id, model: Self.defaultModel, apiKey: "key-1")
    }

    @Test("Finding a credential by ID returns nil if the Core Data portion is not present")
    func findReturnsNilIfNoCoreDataCredential() async throws {
        let found = try await repository.find(UUID())
        #expect(found == nil)
    }

    @Test("Finding a credential by ID still returns the Core Data portion if the secure data portion is not present")
    func findReturnsCoreDataEvenIfNoSecureData() async throws {
        let credential = makeAnthropic(apiKey: "key-1")
        _ = try await repository.save(credential)
        try keychainProvider.delete(id: credential.id.uuidString)

        let found = try await repository.find(credential.id)
        expectAnthropic(found, id: credential.id, model: Self.defaultModel, apiKey: nil)
    }

    // MARK: save

    @Test("Saving a credential persists it to Core Data and secure storage")
    func savePersistsToCoreDataAndSecureStorage() async throws {
        let credential = makeAnthropic(model: "claude-sonnet-4.5", apiKey: "key-1")
        _ = try await repository.save(credential)

        let entity = try fetchEntity(id: credential.id)
        #expect(entity?.typeRaw == ModelCredentialsRepository.AnthropicInternalMetadata.coreDataRawType)
        let metadataJson = try #require(entity?.metadataJson)
        let decodedMetadata = try JSONDecoder().decode(
            ModelCredentialsRepository.AnthropicInternalMetadata.self,
            from: metadataJson
        )
        #expect(decodedMetadata.model == "claude-sonnet-4.5")

        let blob = try keychainProvider.load(id: credential.id.uuidString)
        let decodedSecure = try JSONDecoder().decode(
            ModelCredentialsRepository.AnthropicSecureData.self,
            from: blob
        )
        #expect(decodedSecure.apiKey == "key-1")
    }

    @Test("Saving a credential persists it to Core Data even if secure data is missing")
    func savePersistsToCoreDataWithoutSecureStorage() async throws {
        let credential = makeApple()
        _ = try await repository.save(credential)

        let entity = try fetchEntity(id: credential.id)
        #expect(entity?.typeRaw == ModelCredentialsRepository.AppleInternalMetadata.coreDataRawType)

        #expect(throws: ModelCredentialsRepository.KeychainError.notFound) {
            try self.keychainProvider.load(id: credential.id.uuidString)
        }
    }

    @Test("Saving a credential updates Core Data portion if it already exists")
    func saveUpdatesCoreDataPortionIfAlreadyExists() async throws {
        let id = UUID()
        _ = try await repository.save(makeAnthropic(id: id, model: "claude-haiku-3.5", apiKey: "key-1"))
        _ = try await repository.save(makeAnthropic(id: id, model: "claude-sonnet-4.5", apiKey: "key-1"))

        let found = try await repository.find(id)
        expectAnthropic(found, id: id, model: "claude-sonnet-4.5", apiKey: "key-1")
        #expect(try countEntities() == 1)
    }

    @Test("Saving a credential recreates secure data portion if it already exists")
    func saveRecreatesSecureDataIfAlreadyExists() async throws {
        let id = UUID()
        _ = try await repository.save(makeAnthropic(id: id, apiKey: "key-old"))
        _ = try await repository.save(makeAnthropic(id: id, apiKey: "key-new"))

        let blob = try keychainProvider.load(id: id.uuidString)
        let decoded = try JSONDecoder().decode(
            ModelCredentialsRepository.AnthropicSecureData.self,
            from: blob
        )
        #expect(decoded.apiKey == "key-new")
    }

    @Test("Saving an existing credential with nil secure data removes the secure data if it exists")
    func saveWithNilSecureDataRemovesExistingSecureData() async throws {
        let id = UUID()
        _ = try await repository.save(makeAnthropic(id: id, apiKey: "key-1"))
        // The secret exists before the second save.
        _ = try keychainProvider.load(id: id.uuidString)

        _ = try await repository.save(makeAnthropicWithoutSecret(id: id))

        #expect(throws: ModelCredentialsRepository.KeychainError.notFound) {
            try self.keychainProvider.load(id: id.uuidString)
        }
        let found = try await repository.find(id)
        expectAnthropic(found, id: id, model: Self.defaultModel, apiKey: nil)
    }

    // MARK: delete

    @Test("Deleting a credential deletes it from Core Data and secure storage")
    func deleteDeletesFromCoreDataAndSecureStorage() async throws {
        let credential = makeAnthropic(apiKey: "key-1")
        _ = try await repository.save(credential)

        try await repository.delete(credential.id)

        let found = try await repository.find(credential.id)
        #expect(found == nil)
        #expect(throws: ModelCredentialsRepository.KeychainError.notFound) {
            try self.keychainProvider.load(id: credential.id.uuidString)
        }
    }

    @Test("Deleting a credential throws an error if the Core Data portion doesn't exist")
    func deleteThrowsIfCoreDataDoesNotExist() async throws {
        await #expect(throws: ModelCredentialsRepository.Error.coreDataNotFound) {
            try await self.repository.delete(UUID())
        }
    }

    @Test("Deleting a credential deletes from Core Data even if the secure data portion is missing")
    func deleteStillDeletesCoreDataIfNoSecureStorageFound() async throws {
        let credential = makeAnthropic(apiKey: "key-1")
        _ = try await repository.save(credential)
        try keychainProvider.delete(id: credential.id.uuidString)

        try await repository.delete(credential.id)

        let found = try await repository.find(credential.id)
        #expect(found == nil)
    }

    // MARK: list

    @Test("Listing credentials returns a list of valid credentials")
    func listReturnsListOfSavedCredentials() async throws {
        let id0 = UUID(), id1 = UUID(), id2 = UUID()
        _ = try await repository.save(makeAnthropic(id: id0, apiKey: "key-0"))
        _ = try await repository.save(makeAnthropic(id: id1, apiKey: "key-1"))
        _ = try await repository.save(makeAnthropic(id: id2, apiKey: "key-2"))

        let listed = try await repository.list()
        #expect(listed.count == 3)
        expectAnthropic(listed.first { $0.id == id0 }, id: id0, model: Self.defaultModel, apiKey: "key-0")
        expectAnthropic(listed.first { $0.id == id1 }, id: id1, model: Self.defaultModel, apiKey: "key-1")
        expectAnthropic(listed.first { $0.id == id2 }, id: id2, model: Self.defaultModel, apiKey: "key-2")
    }

    @Test("Listing credentials includes credentials with Core Data component but not secure data")
    func listIncludesCredentialsWithoutSecureData() async throws {
        let appleId = UUID(), anthropicId = UUID()
        _ = try await repository.save(makeApple(id: appleId))
        _ = try await repository.save(makeAnthropic(id: anthropicId, apiKey: "key-1"))

        let listed = try await repository.list()
        #expect(listed.count == 2)

        let apple = listed.first { $0.id == appleId }
        #expect(apple?.id == appleId)
        #expect((apple?.internalMetadata as? ModelCredentialsRepository.AppleInternalMetadata) != nil)
        #expect(apple?.secureData == nil)

        expectAnthropic(listed.first { $0.id == anthropicId }, id: anthropicId, model: Self.defaultModel, apiKey: "key-1")
    }

    // MARK: clear

    @Test("Clearing credentials clears all Core Data credentials and secure data")
    func clearClearsAllCredentials() async throws {
        let id0 = UUID(), id1 = UUID()
        _ = try await repository.save(makeAnthropic(id: id0, apiKey: "key-0"))
        _ = try await repository.save(makeAnthropic(id: id1, apiKey: "key-1"))

        try await repository.clear()

        let listed = try await repository.list()
        #expect(listed.isEmpty)
        #expect(throws: ModelCredentialsRepository.KeychainError.notFound) {
            try self.keychainProvider.load(id: id0.uuidString)
        }
        #expect(throws: ModelCredentialsRepository.KeychainError.notFound) {
            try self.keychainProvider.load(id: id1.uuidString)
        }
    }

    @Test("Clearing credentials succeeds even if some secure data is missing")
    func clearClearsEvenIfSecureDataIsMissing() async throws {
        let anthropicId = UUID(), appleId = UUID()
        _ = try await repository.save(makeAnthropic(id: anthropicId, apiKey: "key-1"))
        _ = try await repository.save(makeApple(id: appleId))
        // Drop the only secret that actually exists.
        try keychainProvider.delete(id: anthropicId.uuidString)

        try await repository.clear()

        let listed = try await repository.list()
        #expect(listed.isEmpty)
    }

    @Test("Clearing credentials does not affect other data types in Core Data")
    func clearOnlyClearsCredentials() async throws {
        let articleId = try await container.performBackgroundTask { context in
            let article = CDBaseArticle(context: context)
            try context.save()
            return article.id
        }
        _ = try await repository.save(makeAnthropic(apiKey: "key-1"))

        try await repository.clear()

        let listed = try await repository.list()
        #expect(listed.isEmpty)

        let request = NSFetchRequest<CDBaseArticle>(entityName: "CDBaseArticle")
        request.predicate = NSPredicate(format: "id == %@", try #require(articleId) as CVarArg)
        let articles = try container.viewContext.fetch(request)
        #expect(articles.count == 1)
    }
}

// MARK: - Test doubles

/// In-memory stand-in for the real Keychain, mirroring the observable semantics
/// of `AppleKeychainProvider`: `save` upserts, `load` throws `.notFound` when a
/// blob is absent, and `delete` is idempotent. The optional error hooks let
/// tests exercise failure paths.
///
/// This is a `final class` rather than an actor (unlike the Apple* provider
/// doubles) because `KeychainProvider`'s methods are synchronous and
/// non-`mutating`, so capturing state requires reference semantics.
private final class InMemoryKeychainProvider: ModelCredentialsRepository.KeychainProvider {
    private(set) var storage: [String: Data] = [:]

    var loadError: Error?
    var saveError: Error?
    var deleteError: Error?

    func load(id: String) throws -> Data {
        if let loadError { throw loadError }
        guard let data = storage[id] else {
            throw ModelCredentialsRepository.KeychainError.notFound
        }
        return data
    }

    func save(_ data: Data, id: String) throws {
        if let saveError { throw saveError }
        storage[id] = data
    }

    func delete(id: String) throws {
        if let deleteError { throw deleteError }
        storage[id] = nil
    }
}
