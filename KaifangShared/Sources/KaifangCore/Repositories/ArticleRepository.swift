//
//  ArticleRepository.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.06.01.
//

import Foundation
import CoreData

public final class ArticleRepository {
    public typealias Tag = ArticleProvider.Tag
    public typealias Author = ArticleProvider.Author
    public typealias FilterArguments = ArticleProvider.FilterArguments
    public typealias SortCriteria = ArticleProvider.SortCriteria
    public typealias Article = ArticleProvider.Article
    public typealias SentenceToken = SegmentationProvider.SentenceToken
    
    private let container: NSPersistentContainer
    
    public init(container: NSPersistentContainer) {
        self.container = container
    }
    
    /// Get all the tags.
    public func getTags() async throws -> Set<Tag> {
        return []
    }
    
    /// Get all the authors.
    public func getAuthors() async throws -> Set<Author> {
        return []
    }
    
    public func list(
        filterBy arguments: FilterArguments,
        sortBy sortArguments: SortCriteria
    ) async throws -> [Article] {
        return []
    }
    
    public func find(_ id: UUID) async throws -> Article? {
        fatalError("not implemented")
    }
    
    public func getSentenceTokens(forArticleId id: UUID) async throws -> [SentenceToken] {
        return []
    }
    
    public func saveSentenceTokens(_ tokens: [SentenceToken], forArticleId id: UUID) async throws -> [SentenceToken] {
        return []
    }
    
    public func clearSentenceTokens(forArticleId id: UUID) async throws {
        
    }
    
    public func save(_ articles: [Article]) async throws -> [Article] {
        return []
    }
    
    public func save(_ article: Article) async throws -> Article {
        fatalError("not implemented")
    }
    
    public func saveTags(_ tags: Set<Tag>) async throws -> Set<Tag> {
        return []
    }
    
    public func saveAuthors(_ author: Set<Author>) async throws -> Set<Author> {
        return []
    }
    
    public func delete(id: UUID) async throws {
        
    }
    
    public func clear() async throws {
        // clear all articles
    }
}
