//
//  ArticleRepository.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.06.01.
//

import Foundation
import CoreData

public final class ArticleRepository {
    public typealias FilterArguments = ArticleProvider.FilterArguments
    public typealias Article = ArticleProvider.Article
    
    private let container: NSPersistentContainer
    
    public init(container: NSPersistentContainer) {
        self.container = container
    }
    
    public func filter(_ arguments: FilterArguments) async throws -> [Article] {
        return []
    }
    
    public func find(_ id: UUID) async throws -> Article {
        fatalError("not implemented")
    }
    
    public func save(_ article: Article) async throws -> Article {
        fatalError("not implemented")
    }
    
    public func clear() async throws {
        // clear all articles
    }
}
