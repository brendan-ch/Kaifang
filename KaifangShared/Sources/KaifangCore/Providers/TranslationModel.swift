//
//  TranslationModel.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.05.26.
//

import Foundation

public enum TranslationModel {
    public protocol Provider {
        func translate(_ query: TranslationProvider.LookupArguments) async throws -> TranslationProvider.Translation
    }
}
