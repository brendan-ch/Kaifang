//
//  ModelCredentialsRepository.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.05.27.
//

import CoreData
import Foundation

public final class ModelCredentialsRepository {
    private static let selectedCredentialKey = "ModelCredentialsRepository.selectedCredentialID"

    private let container: NSPersistentContainer
    private let keychainProvider: KeychainProvider
    private let defaults: UserDefaults

    public init(
        container: NSPersistentContainer,
        keychainProvider: KeychainProvider? = nil,
        defaults: UserDefaults? = nil,
    ) {
        self.container = container
        self.keychainProvider = keychainProvider ?? AppleKeychainProvider()
        self.defaults = defaults ?? .standard
    }

    // MARK: Repository methods

    /// Get the model credentials selected by the user, or nil if no credentials are set.
    public func getCurrentlySelectedCredential() async throws -> ModelCredentials? {
        guard let idString = defaults.string(forKey: Self.selectedCredentialKey),
              let id = UUID(uuidString: idString) else {
            return nil
        }
        return try await find(id)
    }

    /// Set the model credentials selected by the user, or nil to unset.
    public func setCurrentlySelectedCredential(_ id: UUID?) async throws {
        guard let id else {
            defaults.removeObject(forKey: Self.selectedCredentialKey)
            return
        }

        let exists = try await container.performBackgroundTask { context in
            try Self.fetchEntity(id: id, in: context) != nil
        }
        guard exists else {
            throw Error.coreDataNotFound
        }
        defaults.set(id.uuidString, forKey: Self.selectedCredentialKey)
    }

    /// Find the model credentials for the given ID, returning nil if not present.
    public func find(_ id: UUID) async throws -> ModelCredentials? {
        let secureData = try loadSecureData(id: id)
        return try await container.performBackgroundTask { context in
            guard let entity = try Self.fetchEntity(id: id, in: context) else { return nil }
            return try ModelCredentials.fromCoreDataAndSecureData(entity, secureData: secureData)
        }
    }

    /// Given model credentials, save them to Core Data/Keychain or another storage scheme.
    /// Uses an upsert scheme with the metadata ID as the identifier.
    public func save(_ credentials: ModelCredentials) async throws -> ModelCredentials {
        let secureBlob = try credentials.encodeSecureMetadata()
        if let secureBlob {
            try keychainProvider.save(secureBlob, id: credentials.id.uuidString)
        } else {
            try keychainProvider.delete(id: credentials.id.uuidString)
        }

        return try await container.performBackgroundTask { context in
            let entity: CDTranslationModelCredential
            if let existing = try Self.fetchEntity(id: credentials.id, in: context) {
                entity = existing
            } else {
                entity = CDTranslationModelCredential(context: context)
                entity.id = credentials.id
            }
            entity.typeRaw = type(of: credentials.internalMetadata).coreDataRawType
            entity.metadataJson = try JSONEncoder().encode(credentials.internalMetadata)

            try context.save()
            return try ModelCredentials.fromCoreDataAndSecureData(entity, secureData: secureBlob)
        }
    }

    public func delete(_ id: UUID) async throws {
        try await container.performBackgroundTask { context in
            guard let entity = try Self.fetchEntity(id: id, in: context) else {
                throw Error.coreDataNotFound
            }
            context.delete(entity)
            try context.save()
        }
        try keychainProvider.delete(id: id.uuidString)
    }

    public func list() async throws -> [ModelCredentials] {
        let ids = try await container.performBackgroundTask { context in
            try Self.fetchAllEntities(in: context).compactMap(\.id)
        }

        var secureDataByID: [UUID: Data] = [:]
        for id in ids {
            if let data = try loadSecureData(id: id) {
                secureDataByID[id] = data
            }
        }

        return try await container.performBackgroundTask { context in
            try Self.fetchAllEntities(in: context).map { entity in
                let secureData = entity.id.flatMap { secureDataByID[$0] }
                return try ModelCredentials.fromCoreDataAndSecureData(entity, secureData: secureData)
            }
        }
    }

    public func clear() async throws {
        let ids = try await container.performBackgroundTask { context in
            let entities = try Self.fetchAllEntities(in: context)
            let ids = entities.compactMap(\.id)
            for entity in entities {
                context.delete(entity)
            }
            try context.save()
            return ids
        }

        for id in ids {
            try keychainProvider.delete(id: id.uuidString)
        }
        defaults.removeObject(forKey: Self.selectedCredentialKey)
    }

    // MARK: Helpers

    /// Loads the Keychain blob for the credential, treating an absent entry as `nil`
    /// rather than an error. Must be called outside Core Data closures because the
    /// `KeychainProvider` is not `Sendable`.
    private func loadSecureData(id: UUID) throws -> Data? {
        do {
            return try keychainProvider.load(id: id.uuidString)
        } catch KeychainError.notFound {
            return nil
        }
    }

    private static func fetchEntity(id: UUID, in context: NSManagedObjectContext) throws -> CDTranslationModelCredential? {
        let request = NSFetchRequest<CDTranslationModelCredential>(entityName: "CDTranslationModelCredential")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    private static func fetchAllEntities(in context: NSManagedObjectContext) throws -> [CDTranslationModelCredential] {
        let request = NSFetchRequest<CDTranslationModelCredential>(entityName: "CDTranslationModelCredential")
        return try context.fetch(request)
    }
}
