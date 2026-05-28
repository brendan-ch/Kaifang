//
//  AnthropicTranslationModelProvider.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.05.27.
//

import Foundation

/// Translates using the Anthropic API. Issues a single `POST /v1/messages`
/// request per translate call — the system prompt does the in-context work
/// when a context is supplied, so no client-side refiner loop is needed.
///
/// The API key is the caller's responsibility to store securely (Keychain).
public final class AnthropicTranslationModelProvider: TranslationModel.Provider {

    // MARK: Types
    
    private struct MessagesRequest: Encodable {
        let model: String
        let max_tokens: Int
        let system: String
        let messages: [Message]
        
        struct Message: Encodable {
            let role: String
            let content: String
        }
    }
    
    private struct MessagesResponse: Decodable {
        let content: [ContentBlock]
        let stop_reason: String?
        
        struct ContentBlock: Decodable {
            let type: String
            let text: String?
        }
    }
    
    private struct ErrorEnvelope: Decodable {
        let error: ErrorBody
        
        struct ErrorBody: Decodable {
            let type: String?
            let message: String?
        }
    }

    public enum Error: Swift.Error, Equatable, LocalizedError {
        case invalidAPIKey
        case forbidden(message: String?)
        case rateLimited
        case serverError(statusCode: Int)
        case malformedResponse
        case other(statusCode: Int, message: String?)

        public var errorDescription: String? {
            switch self {
            case .invalidAPIKey:
                return "The Anthropic API key is invalid or missing."
            case .forbidden(let message):
                return message.map { "Access denied: \($0)" }
                    ?? "Access to the Anthropic API was denied. You may be out of credits or this request was blocked."
            case .rateLimited:
                return "The Anthropic API is rate-limiting requests. Please try again shortly."
            case .serverError(let statusCode):
                return "The Anthropic API returned a server error (HTTP \(statusCode)). Please try again later."
            case .malformedResponse:
                return "The Anthropic API returned a response that could not be understood."
            case .other(let statusCode, let message):
                return message.map { "Anthropic API error (HTTP \(statusCode)): \($0)" }
                    ?? "Anthropic API error (HTTP \(statusCode))."
            }
        }
    }

    // MARK: Defaults

    public static let defaultModel = "claude-haiku-4-5"
    public static let defaultEndpoint = URL(string: "https://api.anthropic.com/v1/messages")!

    private static let maxTokens = 1024
    private static let apiVersion = "2023-06-01"

    // MARK: State

    private let apiKey: String
    private let session: URLSession
    private let model: String
    private let endpoint: URL

    // MARK: Init

    public convenience init(apiKey: String) {
        self.init(apiKey: apiKey, session: .shared)
    }

    init(
        apiKey: String,
        session: URLSession = .shared,
        model: String = AnthropicTranslationModelProvider.defaultModel,
        endpoint: URL = AnthropicTranslationModelProvider.defaultEndpoint
    ) {
        self.apiKey = apiKey
        self.session = session
        self.model = model
        self.endpoint = endpoint
    }

    // MARK: Translate

    public func translate(_ query: TranslationProvider.LookupArguments) async throws -> TranslationProvider.Translation {
        let request = try makeRequest(for: query)
        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw Error.malformedResponse
        }

        switch http.statusCode {
        case 200..<300:
            let translated = try decodeSuccess(data)
            return TranslationProvider.Translation(
                id: UUID(),
                originalText: query.originalText,
                originalTextLang: query.originalTextLang,
                originalTextContext: query.originalTextContext,
                translatedText: translated,
                translatedTextLang: query.translatedTextLang
            )
        case 401:
            throw Error.invalidAPIKey
        case 403:
            throw Error.forbidden(message: decodeErrorMessage(data))
        case 429:
            throw Error.rateLimited
        case 500..<600:
            throw Error.serverError(statusCode: http.statusCode)
        default:
            throw Error.other(statusCode: http.statusCode, message: decodeErrorMessage(data))
        }
    }

    // MARK: Request construction

    private func makeRequest(for query: TranslationProvider.LookupArguments) throws -> URLRequest {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(Self.apiVersion, forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = MessagesRequest(
            model: model,
            max_tokens: Self.maxTokens,
            system: systemPrompt(for: query),
            messages: [.init(role: "user", content: userMessage(for: query))]
        )
        request.httpBody = try JSONEncoder().encode(body)
        return request
    }

    private func systemPrompt(for query: TranslationProvider.LookupArguments) -> String {
        let source = languageLabel(query.originalTextLang, fallback: "the source language")
        let target = languageLabel(query.translatedTextLang, fallback: "the target language")

        if let context = query.originalTextContext, !context.isEmpty {
            return """
            You are a translator. The user will provide some text in \(source) and a \
            passage in \(source) that the text appears in. Translate the text into \
            \(target) as it is used in that passage. Return only the translation. Do \
            not include quotation marks, commentary, or explanation.
            """
        } else {
            return """
            You are a translator. Translate the user's input from \(source) into \
            \(target). Return only the translation. Do not include quotation marks, \
            commentary, or explanation.
            """
        }
    }

    private func userMessage(for query: TranslationProvider.LookupArguments) -> String {
        if let context = query.originalTextContext, !context.isEmpty {
            return """
            Text:
            \(query.originalText)

            Passage:
            \(context)
            """
        } else {
            return query.originalText
        }
    }

    private func languageLabel(_ language: Locale.Language, fallback: String) -> String {
        language.languageCode?.identifier ?? fallback
    }

    // MARK: Response decoding

    private func decodeSuccess(_ data: Data) throws -> String {
        guard let response = try? JSONDecoder().decode(MessagesResponse.self, from: data),
              let firstText = response.content.first(where: { $0.type == "text" })?.text
        else {
            throw Error.malformedResponse
        }
        return firstText
    }

    private func decodeErrorMessage(_ data: Data) -> String? {
        (try? JSONDecoder().decode(ErrorEnvelope.self, from: data))?.error.message
    }
}
