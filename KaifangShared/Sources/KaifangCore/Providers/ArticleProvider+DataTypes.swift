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
        
        // stub implementation, add other properties later
    }
    
    struct FilterArguments {
        /// When passed, only the articles with all of the tags here will be displayed.
        let tags: Set<String>?
        
        /// When passed, filters by the title and contents of the articles.
        let titleAndContents: String?
        
        /// Whether to show only unread articles.
        let unreadOnly: Bool?
    }
}
