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
        
        let author: String
        let plainText: String
        let title: String
        let datePublished: Date?
        let dateRead: Date?
        
        let tags: Set<Tag>
    }
    
    struct Tag: Equatable, Sendable, Hashable {
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
    
    enum SortCriteria: Hashable {
        case dateModified(latestFirst: Bool)
        case dateCreated(latestFirst: Bool)
        case title(aToZ: Bool)
    }
}
