//
//  ModelCredentialsRepository+KeychainProvider.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.05.28.
//

import Foundation
import Security

public extension ModelCredentialsRepository {
    enum KeychainError: LocalizedError {
        case notFound
        case unexpectedData
        case unexpectedStatus(OSStatus)

        public var errorDescription: String? {
            switch self {
            case .notFound:
                "The requested credentials were not found in the Keychain."
            case .unexpectedData:
                "The Keychain returned data in an unexpected format."
            case .unexpectedStatus(let status):
                "The Keychain operation failed with status \(status)."
            }
        }
    }

    protocol KeychainProvider {
        func load(id: String) throws -> Data
        func save(_ data: Data, id: String) throws
        func delete(id: String) throws
    }

    /// Stores arbitrary `Data` blobs in the Keychain as generic password items.
    ///
    /// Items are written with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` and
    /// `kSecAttrSynchronizable = false`, so they never sync to iCloud Keychain and
    /// are excluded from device backups — the data stays on this device only.
    struct AppleKeychainProvider: KeychainProvider {
        public static let defaultService = "dev.bchen.kaifang.modelcredentials"

        private let service: String

        public init(service: String = AppleKeychainProvider.defaultService) {
            self.service = service
        }

        public func load(id: String) throws -> Data {
            var query = baseQuery(id: id)
            query[kSecReturnData as String] = true
            query[kSecMatchLimit as String] = kSecMatchLimitOne

            var item: CFTypeRef?
            let status = SecItemCopyMatching(query as CFDictionary, &item)

            switch status {
            case errSecSuccess:
                guard let data = item as? Data else {
                    throw KeychainError.unexpectedData
                }
                return data
            case errSecItemNotFound:
                throw KeychainError.notFound
            default:
                throw KeychainError.unexpectedStatus(status)
            }
        }

        public func save(_ data: Data, id: String) throws {
            // Upsert: update an existing item first; only add when none exists.
            // Update-then-add avoids a window where the item is briefly absent.
            let updateStatus = SecItemUpdate(
                baseQuery(id: id) as CFDictionary,
                [kSecValueData as String: data] as CFDictionary
            )

            switch updateStatus {
            case errSecSuccess:
                return
            case errSecItemNotFound:
                var addQuery = baseQuery(id: id)
                addQuery[kSecValueData as String] = data
                addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly

                let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
                guard addStatus == errSecSuccess else {
                    throw KeychainError.unexpectedStatus(addStatus)
                }
            default:
                throw KeychainError.unexpectedStatus(updateStatus)
            }
        }

        public func delete(id: String) throws {
            let status = SecItemDelete(baseQuery(id: id) as CFDictionary)
            guard status == errSecSuccess || status == errSecItemNotFound else {
                throw KeychainError.unexpectedStatus(status)
            }
        }

        /// Attributes shared by every operation. `synchronizable = false` keeps
        /// items out of iCloud Keychain, and the data-protection keychain gives
        /// macOS the same `ThisDeviceOnly` semantics as iOS.
        private func baseQuery(id: String) -> [String: Any] {
            [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: id,
                kSecAttrSynchronizable as String: false,
                kSecUseDataProtectionKeychain as String: true,
            ]
        }
    }
}
