//
//  CDEntityWithIDAndDateMetadataTests.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.05.25.
//

import Foundation
import Testing
@testable import KaifangCore

struct CDEntityWithIDAndDateMetadataTests {
    @Test("Subclass of CDEntityWithIDAndDateMetadata is populated with date metadata when created")
    func subclassHasDateMetadataCorrectlySet() async throws {
        let context = try PersistenceController.getTestingContext()

        let article = CDBaseArticle(context: context)
        #expect(article.dateCreated != nil)
        #expect(article.dateCreated!.isCloseToNow())
        #expect(article.dateModified != nil)
        #expect(article.dateModified!.isCloseToNow())
    }
    
    @Test("Subclass of CDEntityWithIDAndDateMetadata has updated metadata when saved")
    func subclassHasDateMetadataUpdatedWhenSaved() async throws {
        let context = try PersistenceController.getTestingContext()
        
        let article = CDBaseArticle(context: context)
        try context.save()
        
        let staleDate = Date(timeIntervalSinceNow: -3600)
        article.dateModified = staleDate
        article.title = "New Title"
        
        try context.save()
        let afterSave = try #require(article.dateModified)
        
        #expect(afterSave != staleDate)
    }
    
    @Test("Subclass of CDEntityWithIDAndDateMetadata does not update date metadata if not a stale date")
    func subclassDoesNotUpdateDateMetadataIfNotStale() async throws {
        let context = try PersistenceController.getTestingContext()
        
        let article = CDBaseArticle(context: context)
        try context.save()
        
        let beforeSave = try #require(article.dateModified)
        article.title = "New Title"
        
        try context.save()
        
        let afterSave = try #require(article.dateModified)
        
        #expect(afterSave == beforeSave)
    }
}
