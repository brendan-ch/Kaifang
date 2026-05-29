//
//  CommonResponseStub.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.05.27.
//

import Foundation

public struct EmptyRequest: Codable, Equatable, Sendable {}
public struct EmptyResponse: Codable, Equatable, Sendable {}

/// A stub protocol accounting for common behaviors and checks that a stub may use.
public protocol CommonResponseStub<RequestBodyType, ResponseBodyType>: Stub {
    associatedtype RequestBodyType where RequestBodyType: Codable & Equatable
    associatedtype ResponseBodyType where ResponseBodyType: Codable

    static var expectedPathComponents: [String] { get }
    static var expectedRequestMethod: String { get }
    static var expectedResponseBody: ResponseBodyType? { get }
    static var expectedRequestBody: RequestBodyType? { get }
    static var expectedUserToken: String? { get }
    static var expectedStatusCode: Int { get }
}

public extension CommonResponseStub {
    @MainActor
    static func stub(for request: URLRequest) throws -> (Data, URLResponse) {
        let emptyResponseData = try Data.emptyResponse()

        if request.url!.pathComponents != expectedPathComponents {
            let response = HTTPURLResponse(url: request.url!, statusCode: 404)!
            return (emptyResponseData, response)
        }

        if request.httpMethod != expectedRequestMethod {
            let response = HTTPURLResponse(url: request.url!, statusCode: 404)!
            return (emptyResponseData, response)
        }

        if let expectedUserToken = expectedUserToken {
            let bearerValue = request.value(forHTTPHeaderField: "Authorization")
            if bearerValue != "Bearer \(expectedUserToken)" {
                let response = HTTPURLResponse(url: request.url!, statusCode: 401)!
                return (emptyResponseData, response)
            }
        }

        if let expectedBody = expectedRequestBody {
            guard let httpBody = try? getDataFromHttpBody(for: request),
                  let decodedHttpBody = try? JSONDecoder().decode(RequestBodyType.self, from: httpBody)
            else {
                let response = HTTPURLResponse(url: request.url!, statusCode: 400)!
                return (emptyResponseData, response)
            }

            if decodedHttpBody != expectedBody {
                let response = HTTPURLResponse(url: request.url!, statusCode: 400)!
                return (emptyResponseData, response)
            }
        }

        // Match server behavior
        let jsonEncoder = JSONEncoder()
        jsonEncoder.dateEncodingStrategy = .iso8601

        let successfulResponseData = try jsonEncoder.encode(expectedResponseBody)
        let response = HTTPURLResponse(url: request.url!, statusCode: expectedStatusCode)!
        return (successfulResponseData, response)
    }
}
