//
//  FlashcardProvider.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.06.02.
//

public final class FlashcardProvider {
    private let repository: FlashcardRepository
    
    init(repository: FlashcardRepository) {
        self.repository = repository
    }
}
