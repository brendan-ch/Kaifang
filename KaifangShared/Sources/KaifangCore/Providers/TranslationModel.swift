//
//  TranslationModel.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.05.26.
//

import Foundation

public enum TranslationModel {
    public struct Query: Codable {
        public let originalText: String
        public let originalTextLang: Locale.Language

        /// The context that the original text appears in.
        public let originalTextContext: String?

        public let translatedLang: Locale.Language
    }

    public struct Result {
        public let translatedTextLang: Locale.Language
        public let translatedText: String
        public let originalQuery: Query

        public let dateCreated: Date = Date()
    }

    public protocol Provider {
        func translate(_ query: Query) async throws -> Result
    }
}
