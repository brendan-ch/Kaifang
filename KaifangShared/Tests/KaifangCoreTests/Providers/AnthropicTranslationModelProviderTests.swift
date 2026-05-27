//
//  AnthropicTranslationModelProviderTests.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.05.27.
//

import Foundation
import Testing
@testable import KaifangCore

// MARK: - Tests

@Suite(.serialized)
struct AnthropicTranslationModelProviderTests {

    init() {
        // Static stub state persists across tests. Reset before each test.
        AnthropicSuccessStub.reset()
        AnthropicUnauthorizedStub.reset()
        AnthropicForbiddenStub.reset()
        AnthropicRateLimitStub.reset()
        AnthropicServerErrorStub.reset()
        AnthropicMalformedStub.reset()
        AnthropicNetworkErrorStub.reset()
    }

    // MARK: Headers

    @Test("API key is sent in x-api-key header")
    func apiKeyReachesXAPIKeyHeader() async throws {
        let provider = makeProvider(apiKey: "sk-test-123", stub: AnthropicSuccessStub.self)

        _ = try await provider.translate(makeQuery())

        let request = try #require(AnthropicSuccessStub.capturedRequests.last)
        #expect(request.value(forHTTPHeaderField: "x-api-key") == "sk-test-123")
    }

    @Test("Request includes anthropic-version header")
    func anthropicVersionHeaderIsSet() async throws {
        let provider = makeProvider(apiKey: "sk-test", stub: AnthropicSuccessStub.self)

        _ = try await provider.translate(makeQuery())

        let request = try #require(AnthropicSuccessStub.capturedRequests.last)
        #expect(request.value(forHTTPHeaderField: "anthropic-version") == "2023-06-01")
    }

    @Test("Request uses Content-Type: application/json")
    func contentTypeHeaderIsJSON() async throws {
        let provider = makeProvider(apiKey: "sk-test", stub: AnthropicSuccessStub.self)

        _ = try await provider.translate(makeQuery())

        let request = try #require(AnthropicSuccessStub.capturedRequests.last)
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }

    // MARK: Request body

    @Test("Request body shape is correct")
    func requestBodyShapeIsCorrect() async throws {
        let provider = makeProvider(apiKey: "sk-test", stub: AnthropicSuccessStub.self)

        _ = try await provider.translate(makeQuery())

        let request = try #require(AnthropicSuccessStub.capturedRequests.last)
        let body = try decodeCapturedBody(request)

        #expect(!body.model.isEmpty)
        #expect(body.max_tokens > 0)
        #expect(!body.system.isEmpty)
        #expect(body.messages.count == 1)
        #expect(body.messages.first?.role == "user")
    }

    // MARK: Prompt design

    @Test("System prompt differs when context is provided, and never references input length")
    func systemPromptDiffersWithContext() async throws {
        let provider = makeProvider(apiKey: "sk-test", stub: AnthropicSuccessStub.self)

        _ = try await provider.translate(makeQuery(context: nil))
        _ = try await provider.translate(makeQuery(context: "Say hello to the world."))

        #expect(AnthropicSuccessStub.capturedRequests.count == 2)

        let withoutContextBody = try decodeCapturedBody(AnthropicSuccessStub.capturedRequests[0])
        let withContextBody = try decodeCapturedBody(AnthropicSuccessStub.capturedRequests[1])

        #expect(withoutContextBody.system != withContextBody.system)

        for system in [withoutContextBody.system, withContextBody.system] {
            let lower = system.lowercased()
            #expect(!lower.contains("word"))
            #expect(!lower.contains("phrase"))
            #expect(!lower.contains("sentence"))
        }
    }

    // MARK: Response parsing

    @Test("Translated text is extracted from the response content block")
    func translatedTextIsExtractedFromContentBlock() async throws {
        AnthropicSuccessStub.responseText = "hola"
        let provider = makeProvider(apiKey: "sk-test", stub: AnthropicSuccessStub.self)

        let result = try await provider.translate(makeQuery())

        #expect(result.translatedText == "hola")
    }

    // MARK: Error handling

    @Test("Network errors propagate as URLError")
    func networkErrorPropagates() async throws {
        let provider = makeProvider(apiKey: "sk-test", stub: AnthropicNetworkErrorStub.self)

        await #expect(throws: URLError.self) {
            _ = try await provider.translate(makeQuery())
        }
    }

    @Test("401 throws invalidAPIKey")
    func unauthorizedThrowsInvalidAPIKey() async throws {
        let provider = makeProvider(apiKey: "sk-test", stub: AnthropicUnauthorizedStub.self)

        await #expect(throws: AnthropicTranslationModelProvider.Error.invalidAPIKey) {
            _ = try await provider.translate(makeQuery())
        }
    }

    @Test("403 throws forbidden and surfaces the server message")
    func forbiddenThrowsForbidden() async throws {
        let provider = makeProvider(apiKey: "sk-test", stub: AnthropicForbiddenStub.self)

        do {
            _ = try await provider.translate(makeQuery())
            Issue.record("Expected forbidden error to be thrown")
        } catch let error as AnthropicTranslationModelProvider.Error {
            guard case .forbidden(let message) = error else {
                Issue.record("Expected .forbidden, got \(error)")
                return
            }
            #expect(message == "Your credit balance is too low to access the Anthropic API.")
        }
    }

    @Test("429 throws rateLimited")
    func rateLimitedThrowsRateLimited() async throws {
        let provider = makeProvider(apiKey: "sk-test", stub: AnthropicRateLimitStub.self)

        await #expect(throws: AnthropicTranslationModelProvider.Error.rateLimited) {
            _ = try await provider.translate(makeQuery())
        }
    }

    @Test("500 throws serverError with the status code")
    func serverErrorThrowsServerError() async throws {
        let provider = makeProvider(apiKey: "sk-test", stub: AnthropicServerErrorStub.self)

        await #expect(throws: AnthropicTranslationModelProvider.Error.serverError(statusCode: 500)) {
            _ = try await provider.translate(makeQuery())
        }
    }

    @Test("Malformed 200 response throws malformedResponse")
    func malformedResponseThrowsMalformedResponse() async throws {
        let provider = makeProvider(apiKey: "sk-test", stub: AnthropicMalformedStub.self)

        await #expect(throws: AnthropicTranslationModelProvider.Error.malformedResponse) {
            _ = try await provider.translate(makeQuery())
        }
    }
}

// MARK: - Helpers

private func makeProvider<S: Stub>(
    apiKey: String,
    stub: S.Type
) -> AnthropicTranslationModelProvider {
    AnthropicTranslationModelProvider(
        apiKey: apiKey,
        session: URLSession.stubbed(with: stub)
    )
}

private func makeQuery(context: String? = nil) -> TranslationModel.Query {
    TranslationModel.Query(
        originalText: "hello",
        originalTextLang: Locale.Language(identifier: "en"),
        originalTextContext: context,
        translatedLang: Locale.Language(identifier: "es")
    )
}

private struct CapturedRequestBody: Decodable {
    let model: String
    let max_tokens: Int
    let system: String
    let messages: [Message]

    struct Message: Decodable {
        let role: String
        let content: String
    }
}

private func decodeCapturedBody(_ request: URLRequest) throws -> CapturedRequestBody {
    let data = try AnthropicSuccessStub.getDataFromHttpBody(for: request)
    return try JSONDecoder().decode(CapturedRequestBody.self, from: data)
}

// MARK: - Stubs

/// Returns 200 with a `content: [{type: "text", text: ...}]` payload.
/// Captures every received request for assertions.
private struct AnthropicSuccessStub: Stub {
    nonisolated(unsafe) static var capturedRequests: [URLRequest] = []
    nonisolated(unsafe) static var responseText: String = "TRANSLATED"

    static func reset() {
        capturedRequests = []
        responseText = "TRANSLATED"
    }

    static func stub(for request: URLRequest) throws -> (Data, URLResponse) {
        capturedRequests.append(request)

        let payload: [String: Any] = [
            "id": "msg_test",
            "type": "message",
            "role": "assistant",
            "content": [
                ["type": "text", "text": responseText]
            ],
            "stop_reason": "end_turn",
            "model": "claude-haiku-4-5"
        ]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let response = HTTPURLResponse(url: request.url!, statusCode: 200)!
        return (data, response)
    }
}

private struct AnthropicUnauthorizedStub: Stub {
    static func reset() {}

    static func stub(for request: URLRequest) throws -> (Data, URLResponse) {
        let payload: [String: Any] = [
            "type": "error",
            "error": [
                "type": "authentication_error",
                "message": "invalid x-api-key"
            ]
        ]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let response = HTTPURLResponse(url: request.url!, statusCode: 401)!
        return (data, response)
    }
}

private struct AnthropicForbiddenStub: Stub {
    static func reset() {}

    static func stub(for request: URLRequest) throws -> (Data, URLResponse) {
        let payload: [String: Any] = [
            "type": "error",
            "error": [
                "type": "permission_error",
                "message": "Your credit balance is too low to access the Anthropic API."
            ]
        ]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let response = HTTPURLResponse(url: request.url!, statusCode: 403)!
        return (data, response)
    }
}

private struct AnthropicRateLimitStub: Stub {
    static func reset() {}

    static func stub(for request: URLRequest) throws -> (Data, URLResponse) {
        let payload: [String: Any] = [
            "type": "error",
            "error": [
                "type": "rate_limit_error",
                "message": "Number of request tokens has exceeded your per-minute rate limit"
            ]
        ]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let response = HTTPURLResponse(url: request.url!, statusCode: 429)!
        return (data, response)
    }
}

private struct AnthropicServerErrorStub: Stub {
    static func reset() {}

    static func stub(for request: URLRequest) throws -> (Data, URLResponse) {
        let payload: [String: Any] = [
            "type": "error",
            "error": [
                "type": "api_error",
                "message": "Internal server error"
            ]
        ]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let response = HTTPURLResponse(url: request.url!, statusCode: 500)!
        return (data, response)
    }
}

private struct AnthropicMalformedStub: Stub {
    static func reset() {}

    static func stub(for request: URLRequest) throws -> (Data, URLResponse) {
        let data = "not json at all".data(using: .utf8)!
        let response = HTTPURLResponse(url: request.url!, statusCode: 200)!
        return (data, response)
    }
}

private struct AnthropicNetworkErrorStub: Stub {
    static func reset() {}

    static func stub(for request: URLRequest) throws -> (Data, URLResponse) {
        throw URLError(.notConnectedToInternet)
    }
}
