//
//  Date.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.05.25.
//

import Foundation

extension Date {
    func isCloseToNow(maxDeltaSeconds: Double = 0.1) -> Bool {
        let actualDeltaSeconds = abs(self.timeIntervalSinceNow)
        return actualDeltaSeconds < maxDeltaSeconds
    }
}
