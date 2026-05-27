//
//  ModelCredentialsRepository+DataTypes.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.05.27.
//

import CoreData
import Foundation

public extension ModelCredentialsRepository {
    enum Error: LocalizedError, Equatable {
        case coreDataNotFound
        case keychainNotFound
        case failedConversionToDomainModel
    }
    
    /// Model credentials assembled from Core Data and Keychain.
    struct ModelCredentials: Sendable {
        public let id: UUID
        public let internalMetadata: any ModelInternalMetadata
        public let secureData: (any ModelSecureData)?
        
        /// Save the credential to both Core Data and Keychain.
        public func save(context: NSManagedObjectContext, keychainProvider: KeychainProvider) throws {
        }
        
        static public func find(_ id: UUID, context: NSManagedObjectContext, keychainProvider: KeychainProvider) throws -> Self? {
            return nil
        }
        
        public func toCoreData(context: NSManagedObjectContext) throws -> CDTranslationModelCredential {
            let credential = CDTranslationModelCredential(context: context)
            
            credential.typeRaw = type(of: internalMetadata).coreDataRawType
            credential.id = id
            credential.metadataJson = try JSONEncoder().encode(internalMetadata)
            
            return credential
        }
        
        public func fromCoreData(_ coreData: CDTranslationModelCredential) throws -> Self {
            guard let id = coreData.id else {
                throw Error.failedConversionToDomainModel
            }
            
            let decoder = JSONDecoder()
            let decodedMetadata: any ModelInternalMetadata
            
            if let metadataJson = coreData.metadataJson {
                switch coreData.typeRaw {
                case AppleInternalMetadata.coreDataRawType:
                    decodedMetadata = try decoder.decode(AppleInternalMetadata.self, from: metadataJson)
                case AnthropicInternalMetadata.coreDataRawType:
                    decodedMetadata = try decoder.decode(AnthropicInternalMetadata.self, from: metadataJson)
                default:
                    throw Error.failedConversionToDomainModel
                }
            } else {
                switch coreData.typeRaw {
                case AppleInternalMetadata.coreDataRawType:
                    decodedMetadata = AppleInternalMetadata()
                case AnthropicInternalMetadata.coreDataRawType:
                    decodedMetadata = AnthropicInternalMetadata()
                default:
                    throw Error.failedConversionToDomainModel
                }
            }
            
            // TODO: return secure data
            
            return ModelCredentials(
                id: id,
                internalMetadata: decodedMetadata,
                secureData: nil
            )
        }
    }
    
    protocol KeychainProvider {
        // TODO: keychain-related methods
    }
    
    /// A model's metadata that is coded to/decoded from JSON in Core Data.
    protocol ModelInternalMetadata: Sendable, Codable {
        /// The corresponding type property used to mark the Core Data entity.
        static var coreDataRawType: String { get }
    }
    
    
    /// Model credential data stored as a blob in Keychain.
    protocol ModelSecureData: Codable, Sendable {
    }
    
    struct AppleInternalMetadata: ModelInternalMetadata {
        public static let coreDataRawType: String = "apple"
    }
    
    struct AnthropicInternalMetadata: ModelInternalMetadata {
        public static let coreDataRawType: String = "anthropic"
        public static let defaultModel: String = "claude-haiku-3.5"
        
        public let model: String
        
        init(model: String = Self.defaultModel) {
            self.model = model
        }
    }
    
    struct AnthropicSecureData: ModelSecureData {
        public let apiKey: String
    }
}
