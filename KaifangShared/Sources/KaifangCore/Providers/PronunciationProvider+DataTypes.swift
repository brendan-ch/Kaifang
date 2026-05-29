//
//  PronunciationProvider+DataTypes.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.05.28.
//

import Foundation

public extension PronunciationProvider {
    /// A notation a caller may request a pronunciation in. Only
    /// ``System/numberedPinyin`` is currently produced; the others are
    /// reserved for a future converter.
    enum System: Equatable, Sendable {
        case numberedPinyin
        case toneMarkPinyin
        case zhuyin
    }

    /// A single pronunciation of a word, tied to the headword forms it was
    /// found under.
    struct Pronunciation: Equatable, Sendable {
        let simplified: String
        let traditional: String
        let system: System

        /// The pronunciation rendered in `system`. For ``System/numberedPinyin``
        /// this is CC-CEDICT's raw value, e.g. `"Zhong1 guo2"`.
        let value: String
    }

    enum Error: Swift.Error, LocalizedError {
        case resourceUnavailable
        case unsupportedSystem(System)

        public var errorDescription: String? {
            switch self {
            case .resourceUnavailable:
                return "The CC-CEDICT dictionary resource could not be found in the bundle."
            case .unsupportedSystem(let system):
                return "The \(system) pronunciation system is not yet supported."
            }
        }
    }
}
