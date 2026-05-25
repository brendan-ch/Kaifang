//
//  CDEntityWithDateMetadataTests.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.05.25.
//

import Testing
@testable import KaifangCore

struct CDEntityWithDateMetadataTests {
    @Test("Subclass of CDEntityWithDateMetadata is populated with date metadata")
    func subclassHasDateMetadata() async throws {
        let context = PersistenceController.getTestingContext()

        let article = CDBaseArticle(context: context)
        #expect(article.dateCreated != nil)
    }
}
