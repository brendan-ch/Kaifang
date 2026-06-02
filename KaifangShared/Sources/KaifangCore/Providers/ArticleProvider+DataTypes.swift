//
//  ArticleProvider+DataTypes.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.05.29.
//

import Foundation

public extension ArticleProvider {
    /// Maps to ``CDBaseArticle``.
    struct Article: Equatable, Sendable {
        let id: UUID
        
        let plainText: String
        let title: String
        let datePublished: Date?
        let dateRead: Date?
        
        let tags: Set<Tag>
        let authors: Set<Author>
        
        let dateCreated: Date
        let dateModified: Date
        
        init(
            id: UUID,
            plainText: String,
            title: String,
            datePublished: Date?,
            dateRead: Date?,
            tags: Set<Tag>,
            authors: Set<Author>,
            dateCreated: Date = Date(),
            dateModified: Date = Date()
        ) {
            self.id = id
            self.plainText = plainText
            self.title = title
            self.datePublished = datePublished
            self.dateRead = dateRead
            self.tags = tags
            self.authors = authors
            self.dateCreated = dateCreated
            self.dateModified = dateModified
        }
    }
    
    struct Tag: Equatable, Sendable, Hashable {
        let id: UUID
        let name: String
    }
    
    struct Author: Equatable, Sendable, Hashable {
        let id: UUID
        let name: String
    }
    
    struct FilterArguments {
        /// When passed, only the articles with all of the tags here will be displayed.
        let tags: Set<Tag>?
        
        /// When passed, filters by the title and contents of the articles.
        let titleAndContents: String?
        
        /// Whether to show only unread articles.
        let unreadOnly: Bool?
    }
    
    enum SortCriteria: Hashable, Sendable {
        case dateModified(SortOrder)
        case dateCreated(SortOrder)
        case title(SortOrder)
    }
    
    enum Error: Swift.Error, LocalizedError {
        case notFound
        
        public var errorDescription: String? {
            switch self {
            case .notFound:
                return "The article was not found."
            }
        }
    }
}
