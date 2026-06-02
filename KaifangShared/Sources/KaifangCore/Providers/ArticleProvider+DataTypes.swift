//
//  ArticleProvider+DataTypes.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.05.29.
//

import CoreData
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

        static func fromCoreData(_ entity: CDBaseArticle) throws -> Article {
            guard let id = entity.id,
                  let title = entity.title,
                  let plainText = entity.plainText,
                  let dateCreated = entity.dateCreated,
                  let dateModified = entity.dateModified else {
                throw ArticleProvider.Error.failedConversionToDomainModel
            }

            let tagsRelationship = entity.tags ?? NSSet()
            guard let tagEntities = tagsRelationship as? Set<CDTag> else {
                throw ArticleProvider.Error.failedConversionToDomainModel
            }
            let tags = try Set(tagEntities.map(Tag.fromCoreData))

            let authorsRelationship = entity.authors ?? NSSet()
            guard let authorEntities = authorsRelationship as? Set<CDAuthor> else {
                throw ArticleProvider.Error.failedConversionToDomainModel
            }
            let authors = try Set(authorEntities.map(Author.fromCoreData))

            return Article(
                id: id,
                plainText: plainText,
                title: title,
                datePublished: entity.datePublished,
                dateRead: entity.dateRead,
                tags: tags,
                authors: authors,
                dateCreated: dateCreated,
                dateModified: dateModified
            )
        }
    }
    
    struct Tag: Equatable, Sendable, Hashable {
        let id: UUID
        let name: String

        static func fromCoreData(_ entity: CDTag) throws -> Tag {
            guard let id = entity.id, let name = entity.name else {
                throw ArticleProvider.Error.failedConversionToDomainModel
            }
            return Tag(id: id, name: name)
        }
    }

    struct Author: Equatable, Sendable, Hashable {
        let id: UUID
        let name: String

        static func fromCoreData(_ entity: CDAuthor) throws -> Author {
            guard let id = entity.id, let name = entity.name else {
                throw ArticleProvider.Error.failedConversionToDomainModel
            }
            return Author(id: id, name: name)
        }
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
    
    enum Error: Swift.Error, LocalizedError, Sendable, Equatable {
        case notFound
        case tagNameConflict(name: String)
        case authorNameConflict(name: String)
        case failedConversionToDomainModel

        public var errorDescription: String? {
            switch self {
            case .notFound:
                return "The article was not found."
            case .tagNameConflict(let name):
                return "A tag with the name \"\(name)\" already exists."
            case .authorNameConflict(let name):
                return "An author with the name \"\(name)\" already exists."
            case .failedConversionToDomainModel:
                return "Unable to convert a Core Data entity to a domain model."
            }
        }
    }
}
