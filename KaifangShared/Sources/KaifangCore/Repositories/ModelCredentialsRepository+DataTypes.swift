//
//  ModelCredentialsRepository+DataTypes.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.05.27.
//

import CoreData
import Foundation

public extension ModelCredentialsRepository {
    // MARK: Protocols
    
    /// A model's metadata that is coded to/decoded from JSON in Core Data.
    protocol ModelInternalMetadata: Sendable, Codable {
        /// The corresponding type property used to mark the Core Data entity.
        static var coreDataRawType: String { get }
    }
    
    
    /// Model credential data stored as a blob in Keychain.
    protocol ModelSecureData: Codable, Sendable {
    }
    
    // MARK: Data types
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

        public func encodeSecureMetadata() throws -> Data? {
            guard let secureData = secureData else { return nil }
            return try JSONEncoder().encode(secureData)
        }

        public static func fromCoreDataAndSecureData(
            _ entity: CDTranslationModelCredential,
            secureData: Data?
        ) throws -> ModelCredentials {
            guard let id = entity.id else {
                throw Error.failedConversionToDomainModel
            }
            guard let typeRaw = entity.typeRaw else {
                throw Error.failedConversionToDomainModel
            }

            let decodedMetadata = try decodeInternalMetadata(entity, typeRaw: typeRaw)
            let decodedSecureData = try decodeSecureMetadata(from: secureData, typeRaw: typeRaw)

            return ModelCredentials(
                id: id,
                internalMetadata: decodedMetadata,
                secureData: decodedSecureData
            )
        }

        private static func decodeInternalMetadata(
            _ entity: CDTranslationModelCredential,
            typeRaw: String
        ) throws -> any ModelInternalMetadata {
            let decoder = JSONDecoder()

            if let metadataJson = entity.metadataJson {
                switch typeRaw {
                case AppleInternalMetadata.coreDataRawType:
                    return try decoder.decode(AppleInternalMetadata.self, from: metadataJson)
                case AnthropicInternalMetadata.coreDataRawType:
                    return try decoder.decode(AnthropicInternalMetadata.self, from: metadataJson)
                default:
                    throw Error.failedConversionToDomainModel
                }
            } else {
                switch typeRaw {
                case AppleInternalMetadata.coreDataRawType:
                    return AppleInternalMetadata()
                case AnthropicInternalMetadata.coreDataRawType:
                    return AnthropicInternalMetadata()
                default:
                    throw Error.failedConversionToDomainModel
                }
            }
        }
        
        private static func decodeSecureMetadata(from data: Data?, typeRaw: String) throws -> (any ModelSecureData)? {
            guard let data = data else { return nil }
            
            let decoder = JSONDecoder()
            switch typeRaw {
                case AppleInternalMetadata.coreDataRawType:
                // not required for the Apple translation provider
                return nil
            case AnthropicInternalMetadata.coreDataRawType:
                return try decoder.decode(AnthropicSecureData.self, from: data)
            default:
                throw Error.failedConversionToDomainModel
            }
        }
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
