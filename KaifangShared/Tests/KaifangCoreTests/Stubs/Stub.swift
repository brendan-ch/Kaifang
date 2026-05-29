//
//  Stub.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.05.27.
//

import Foundation

public protocol Stub {
    static func stub(for request: URLRequest) throws -> (Data, URLResponse)

    static func readDataFromStream(_ stream: InputStream) throws -> Data

    static func getDataFromHttpBody(for request: URLRequest) throws -> Data
}

public extension Stub {
    static func readDataFromStream(_ stream: InputStream) throws -> Data {
        stream.open()
        defer { stream.close() }

        var data = Data()
        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }

        while stream.hasBytesAvailable {
            let bytesRead = stream.read(buffer, maxLength: bufferSize)
            if bytesRead < 0 {
                throw stream.streamError ?? URLError(.unknown)
            } else if bytesRead == 0 {
                break
            } else {
                data.append(buffer, count: bytesRead)
            }
        }

        return data
    }

    static func getDataFromHttpBody(for request: URLRequest) throws -> Data {
        let bodyData: Data

        // Try httpBody first, then fall back to httpBodyStream
        if let httpBody = request.httpBody {
            bodyData = httpBody
        } else if let httpBodyStream = request.httpBodyStream {
            bodyData = try Self.readDataFromStream(httpBodyStream)
        } else {
            throw URLError(.badURL)
        }

        return bodyData
    }
}
