//
//  ModelCredentialsRepositoryTests.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.05.28.
//

import Foundation
import Testing
@testable import KaifangCore

@Suite
struct ModelCredentialsRepositoryTests {
    // Tests are added in a future step once the repository methods are
    // implemented. The test double below stands in for the Keychain.
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
