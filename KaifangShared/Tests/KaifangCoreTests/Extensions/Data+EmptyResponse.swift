//
//  Data+EmptyResponse.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.05.27.
//

import Foundation

public extension Data {
    static func emptyResponse() throws -> Data {
        let responseBodyDict: [String: String] = [:]
        let data = try JSONEncoder().encode(responseBodyDict)
        return data
    }
}
