//
//  TranslationProvider.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.05.27.
//

import Foundation

public final class TranslationProvider {
    private let repository: TranslationRepository
    private let modelProvider: any TranslationModel.Provider

    public init(
        repository: TranslationRepository,
        modelProvider: any TranslationModel.Provider
    ) {
        self.repository = repository
        self.modelProvider = modelProvider
    }

    /// Resolves the concrete `TranslationModel.Provider` for a given set of
    /// credentials. Eventually called by a higher-level coordinator after it
    /// fetches credentials from `ModelCredentialsRepository`.
    public convenience init(
        repository: TranslationRepository,
        credentials: ModelCredentialsRepository.ModelCredentials
    ) throws {
        self.init(
            repository: repository,
            modelProvider: try Self.makeModelProvider(for: credentials)
        )
    }

    static func makeModelProvider(
        for credentials: ModelCredentialsRepository.ModelCredentials
    ) throws -> any TranslationModel.Provider {
        switch credentials.internalMetadata {
        case is ModelCredentialsRepository.AppleInternalMetadata:
            if #available(iOS 26.0, macOS 26.0, *) {
                return AppleTranslationModelProvider()
            } else {
                throw BuildError.appleTranslationUnavailable
            }
        case is ModelCredentialsRepository.AnthropicInternalMetadata:
            guard let secureData = credentials.secureData
                    as? ModelCredentialsRepository.AnthropicSecureData else {
                throw BuildError.missingAnthropicAPIKey
            }
            return AnthropicTranslationModelProvider(apiKey: secureData.apiKey)
        default:
            throw BuildError.unsupportedCredentials(
                metadataType: String(describing: type(of: credentials.internalMetadata))
            )
        }
    }

    public enum BuildError: Swift.Error, LocalizedError {
        case appleTranslationUnavailable
        case missingAnthropicAPIKey
        case unsupportedCredentials(metadataType: String)

        public var errorDescription: String? {
            switch self {
            case .appleTranslationUnavailable:
                return "Apple Translation requires iOS 26 / macOS 26 or later."
            case .missingAnthropicAPIKey:
                return "Anthropic credentials are missing an API key."
            case .unsupportedCredentials(let metadataType):
                return "No translation provider is available for credentials of type \(metadataType)."
            }
        }
    }
}
