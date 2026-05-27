//
//  ModelCredentialsRepository.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.05.27.
//

import CoreData
import Foundation

public final class ModelCredentialsRepository {
    // MARK: Repository methods

    /// Get the model credentials selected by the user, or nil if no credentials are set.
    public func getCurrentlySetModelCredentials() throws -> ModelCredentials? {
        fatalError("not implemented")
    }

    /// Given model credentials, save them to Core Data/Keychain or another storage scheme.
    /// Uses an upsert scheme with the metadata ID as the identifier.
    public func saveModelCredentials(_ credentials: ModelCredentials) throws {
        fatalError("not implemented")
    }

    public func deleteModelCredentials(_ id: String) throws {
        fatalError("not implemented")
    }

    public func listAllModelCredentials() throws -> [ModelCredentials] {
        fatalError("not implemented")
    }
}
