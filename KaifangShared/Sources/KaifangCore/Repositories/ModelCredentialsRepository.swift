//
//  ModelCredentialsRepository.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.05.27.
//

import CoreData
import Foundation

public final class ModelCredentialsRepository {
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
    public func getCurrentlySelectedCredential() throws -> ModelCredentials? {
        fatalError("not implemented")
    }
    
    /// Set the model credentials selected by the user, or nil to unset.
    public func setCurrentlySelectedCredential(_ id: UUID?) throws {
        fatalError("not implemented")
    }
    
    /// Find the model credentials for the given ID, returning nil if not present.
    public func find(_ id: UUID) async throws -> ModelCredentials? {
        return nil
    }

    /// Given model credentials, save them to Core Data/Keychain or another storage scheme.
    /// Uses an upsert scheme with the metadata ID as the identifier.
    public func save(_ credentials: ModelCredentials) async throws -> ModelCredentials {
        fatalError("not implemented")
    }

    public func delete(_ id: UUID) async throws {
    }

    public func list() async throws -> [ModelCredentials] {
        return []
    }
    
    public func clear() async throws {
        
    }
}
