//
//  HTTPURLResponse+Init.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.05.27.
//

import Foundation

public extension HTTPURLResponse {
    convenience init?(url: URL, statusCode: Int) {
        self.init(
            url: url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )
    }
}
