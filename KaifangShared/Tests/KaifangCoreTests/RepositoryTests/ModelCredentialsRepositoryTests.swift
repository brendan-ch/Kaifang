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

@Suite
struct ModelCredentialsRepositoryTests {
    let container: NSPersistentContainer
    let repository: ModelCredentialsRepository
    let defaults: UserDefaults
    let keychainProvider: ModelCredentialsRepository.KeychainProvider
    
    init() async throws {
        container = PersistenceController.getTestingContainer()
        keychainProvider = InMemoryKeychainProvider()
        defaults = UserDefaults(suiteName: "test.\(UUID().uuidString)")!
        repository = ModelCredentialsRepository(
            container: container,
            keychainProvider: keychainProvider,
            defaults: defaults
        )
    }
    
    @Test("Getting current model credentials retrieves the correct credentials")
    func getCurrentModelCredentialsGetsCorrectlyAfterSetting() async throws {
        
    }
    
    @Test("Getting current model credentials retrieves correct credentials even with missing secure data")
    func getCurrentModelCredentialsRetrievesEvenWithNoSecureData() async throws {
        
    }
    
    @Test("Getting current model credentials returns nil if no Core Data credentials match the stored ID")
    func getCurrentModelCredentialsReturnsNilIfNoCredentialsForStoredKey() async throws {
        
    }
    
    @Test("Getting current model credentials returns nil if stored ID set to nil")
    func getCurrentModelCredentialsReturnsNilIfNoStoredKey() async throws {
        
    }
    
    @Test("Setting current model credential ID sets correctly if credential exists")
    func setCurrentModelCredentialsSetsCorrectlyIfExists() async throws {
        
    }
    
    @Test("Setting current model credential ID throws if no credential exists")
    func setCurrentModelCredentialsThrowsIfNoCredentialExists() async throws {
        
    }
    
    @Test("Finding a credential by ID retrieves the correct credential")
    func findReturnsCorrectCredentialById() async throws {
        
    }
    
    @Test("Finding a credential by ID returns nil if the Core Data portion is not present")
    func findReturnsNilIfNoCoreDataCredential() async throws {
        
    }
    
    @Test("Finding a credential by ID still returns the Core Data portion if the secure data portion is not present")
    func findReturnsCoreDataEvenIfNoSecureData() async throws {
        
    }
    
    @Test("Saving a credential persists it to Core Data and secure storage")
    func savePersistsToCoreDataAndSecureStorage() async throws {
        
    }
    
    @Test("Saving a credential persists it to Core Data even if secure data is missing")
    func savePersistsToCoreDataWithoutSecureStorage() async throws {
        
    }
    
    @Test("Saving a credential updates Core Data portion if it already exists")
    func saveUpdatesCoreDataPortionIfAlreadyExists() async throws {
        
    }
    
    @Test("Saving a credential recreates secure data portion if it already exists")
    func saveRecreatesSecureDataIfAlreadyExists() async throws {
        
    }
    
    @Test("Deleting a credential deletes it from Core Data and secure storage")
    func deleteDeletesFromCoreDataAndSecureStorage() async throws {
        
    }
    
    @Test("Deleting a credential throws an error if the Core Data portion doesn't exist")
    func deleteThrowsIfCoreDataDoesNotExist() async throws {
        
    }
    
    @Test("Deleting a credential deletes from Core Data even if the secure data portion is missing")
    func deleteStillDeletesCoreDataIfNoSecureStorageFound() async throws {
        
    }
    
    @Test("Listing credentials returns a list of valid credentials")
    func listReturnsListOfSavedCredentials() async throws {
        
    }
    
    @Test("Listing credentials includes credentials with Core Data component but not secure data")
    func listIncludesCredentialsWithoutSecureData() async throws {
        
    }
    
    @Test("Clearing credentials clears all Core Data credentials and secure data")
    func clearClearsAllCredentials() async throws {
        
    }
    
    @Test("Clearing credentials succeeds even if some secure data is missing")
    func clearClearsEvenIfSecureDataIsMissing() async throws {
        
    }
    
    @Test("Clearing credentials does not affect other data types in Core Data")
    func clearOnlyClearsCredentials() async throws {
        
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
