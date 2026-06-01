//
//  ArticleRepositoryTests.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.06.01.
//

import Testing
import CoreData
@testable import KaifangCore

@Suite(.serialized)
struct ArticleRepositoryTests {
    // MARK: Type aliases
    typealias Tag = ArticleProvider.Tag
    typealias Author = ArticleProvider.Author
    typealias Article = ArticleProvider.Article
    
    // MARK: Setup
    private let container: NSPersistentContainer
    private let repository: ArticleRepository
    
    init() throws {
        container = try PersistenceController.getTestingContainer()
        repository = ArticleRepository(container: container)
    }
    
    // MARK: Data helpers
    func getSampleTags() -> Set<Tag> {
        [
            .init(id: UUID(), name: "Tag 3"),
            .init(id: UUID(), name: "Tag 2"),
            .init(id: UUID(), name: "Tag 1"),
        ]
    }
    
    func getSampleAuthors() -> Set<Author> {
        [
            .init(id: UUID(), name: "Author 3"),
            .init(id: UUID(), name: "Author 2"),
            .init(id: UUID(), name: "Author 1"),
        ]
    }
    
    func getSampleArticles() -> [Article] {
        let newsTag = Tag(id: UUID(), name: "News")
        let techTag = Tag(id: UUID(), name: "Tech")
        let cultureTag = Tag(id: UUID(), name: "Culture")

        let author1 = Author(id: UUID(), name: "Author 1")
        let author2 = Author(id: UUID(), name: "Author 2")
        let author3 = Author(id: UUID(), name: "Author 3")
        let author4 = Author(id: UUID(), name: "Author 4")

        return [
            // Shares `newsTag` with Article Bravo. Unread. Single author.
            .init(
                id: UUID(),
                plainText: "First sample article text.",
                title: "Article Alpha",
                datePublished: Date(timeIntervalSince1970: 1_700_000_000),
                dateRead: nil,
                tags: [newsTag],
                authors: [author1]
            ),
            // Bridges all three tags; read. Two authors, sharing `author1` with Alpha.
            .init(
                id: UUID(),
                plainText: "Second sample article text.",
                title: "Article Bravo",
                datePublished: Date(timeIntervalSince1970: 1_710_000_000),
                dateRead: Date(timeIntervalSince1970: 1_715_000_000),
                tags: [newsTag, techTag, cultureTag],
                authors: [author1, author2]
            ),
            // Shares `cultureTag` with Article Bravo. No publish date, unread. Co-authored.
            .init(
                id: UUID(),
                plainText: "Third sample article text.",
                title: "Article Charlie",
                datePublished: nil,
                dateRead: nil,
                tags: [cultureTag],
                authors: [author3, author4]
            ),
            // No tags. Read. `author1` reused again to exercise duplicate-author cases.
            .init(
                id: UUID(),
                plainText: "Fourth sample article text.",
                title: "Article Delta",
                datePublished: Date(timeIntervalSince1970: 1_720_000_000),
                dateRead: Date(timeIntervalSince1970: 1_725_000_000),
                tags: [],
                authors: [author1]
            ),
            // No tags, no authors. Unread.
            .init(
                id: UUID(),
                plainText: "Fifth sample article text.",
                title: "Article Echo",
                datePublished: Date(timeIntervalSince1970: 1_730_000_000),
                dateRead: nil,
                tags: [],
                authors: []
            ),
        ]
    }
    
    // MARK: Tests
    
    @Test("Getting all tags gets them in a set")
    func getTagsReturnsInAlphabeticalOrder() async throws {
        let expectedTags = getSampleTags()
        _ = try await repository.saveTags(expectedTags)
        
        let resultingTags = try await repository.getTags()
        #expect(resultingTags.count == 3)
        #expect(resultingTags.contains { $0.name == "Tag 2" })
        #expect(resultingTags.contains { $0.name == "Tag 1" })
        #expect(resultingTags.contains { $0.name == "Tag 3" })
    }
    
    @Test("Getting all authors gets them in a set")
    func getAuthorsReturnsInAlphabeticalOrder() async throws {
        let expectedAuthors = getSampleAuthors()
        _ = try await repository.saveAuthors(expectedAuthors)
        
        let resultingAuthors = try await repository.getAuthors()
        #expect(resultingAuthors.count == 3)
        #expect(resultingAuthors.contains { $0.name == "Author 2" })
        #expect(resultingAuthors.contains { $0.name == "Author 1" })
        #expect(resultingAuthors.contains { $0.name == "Author 3" })
    }
    
    @Test("Getting all tags returns empty array if no tags exist")
    func getTagsReturnsEmptyArrayIfNonexistent() async throws {
        let tags = try await repository.getTags()
        #expect(tags.isEmpty)
    }
    
    @Test("Getting all authors returns empty array if no authors exist")
    func getAuthorsReturnsEmptyArrayIfNonexistent() async throws {
        let authors = try await repository.getAuthors()
        #expect(authors.isEmpty)
    }
    
    @Test("Filtering filters by tags")
    func filterFiltersByTags() async throws {
        let articles = getSampleArticles()
        _ = try await repository.save(articles)
        
        let expectedArticlesWithNewsTag = articles.filter { $0.tags.contains { $0.name == "News" } }
        #require(expectedArticlesWithNewsTag.count > 0)
        
        let tags = try await repository.getTags()
        let tag = tags.first { $0.name == "News" }
        #require(tag != nil)
        
        let filterArgs = ArticleProvider.FilterArguments(
            tags: Set([tag!]),
            titleAndContents: nil,
            unreadOnly: nil
        )
        
        let resultingArticles = try await repository.filter(filterArgs)
        #expect(expectedArticlesWithNewsTag == resultingArticles)
    }
    
    @Test("Filtering title and contents filters by title")
    func filterByTitleAndContentsFiltersTitle() async throws {
        let filter = ArticleProvider.FilterArguments(
            tags: nil,
            titleAndContents: "Title",
            unreadOnly: nil
        )
    }
    
    @Test("Filtering title and contents filters contents")
    func filterByTitleAndContentsFiltersContents() async throws {
        
    }
    
    @Test("Filtering by unread only filters out read articles")
    func filterByUnreadOnlyFiltersOutReadArticles() async throws {
        
    }
    
    @Test("Filtering by no properties returns all articles")
    func filterByNoPropertiesReturnsAllArticles() async throws {
        
    }
    
    @Test("Sorting by article title orders them from A to Z")
    func sortByTitleOrdersFromAToZ() async throws {
        
    }
    
    @Test("Sorting by article title orders them from Z to A")
    func sortByTitleOrdersFromZToA() async throws {
        
    }
    
    @Test("Sorting by date modified orders them from latest to earliest")
    func sortByDateModifiedOrdersFromLatestToEarliest() async throws {
        
    }
    
    @Test("Sorting by date modified orders them from earliest to latest")
    func sortByDateModifiedOrdersFromEarliestToLatest() async throws {
        
    }
    
    @Test("Sorting by date created orders them from latest to earliest")
    func sortByDateCreatedOrdersFromLatestToEarliest() async throws {
        
    }
    
    @Test("Sorting by date created orders them from earliest to latest")
    func sortByDateCreatedOrdersFromEarliestToLatest() async throws {
        
    }
    
    @Test("Finding an article by UUID returns the article if found")
    func findReturnsArticle() async throws {
        
    }
    
    @Test("Finding an article by UUID returns nil if the article is not found")
    func findReturnsNilIfNotFound() async throws {
        
    }
    
    @Test("Getting the sentence tokens for an article returns an empty array if they don't exist")
    func getSentenceTokensReturnsNilIfNonexistent() async throws {
        
    }
    
    @Test("Getting the sentence tokens for an article returns the sentence tokens ordered by index")
    func getSentenceTokensReturnsOrderedSentenceTokensIfExists() async throws {
        
    }
    
    @Test("Saving the sentence tokens for an article updates existing tokens and saves new ones")
    func saveSentenceTokensUpdatesExistingTokensAndSavesNewOnes() async throws {
        // test with some uncreated tokens and some pre-existing tokens
    }
    
    @Test("Saving sentence tokens throws error if there is an index collision of a new token with an existing one")
    func saveSentenceTokensThrowsIfIndexCollisionOfNewWithExisting() async throws {
        // criteria for "new" is just that the ID is different
    }
    
    @Test("Clearing sentence tokens clears all of the sentence tokens associated with the article")
    func clearSentenceTokensClearsForOneArticleOnly() async throws {
        // test sentence tokens for multiple articles, and try clearing just one set
    }
    
    @Test("Saving an existing article updates its metadata")
    func saveUpdatesExistingArticle() async throws {
        
    }
    
    @Test("Saving a new article creates it")
    func saveCreatesNewArticle() async throws {
        
    }
    
    @Test("Saving a new article with tags creates any new tags")
    func saveWithTagsCreatesNewTags() async throws {
        // assume there can be a mix of existing + new tags by ID
    }
    
    @Test("Saving a new article with tags having conflicting names with existing tags throws")
    func saveWithTagsHavingConflictingNamesThrows() async throws {
        
    }
    
    @Test("Saving a new article with authors having conflicting names with existing authors throws")
    func saveWithAuthorsHavingConflictingNamesThrows() async throws {
        
    }

    @Test("Deleting an article deletes the article")
    func deleteDeletesTheArticle() async throws {
        
    }
    
    @Test("Deleting an article also deletes its sentence tokens")
    func deleteDeletesSentenceTokens() async throws {
        
    }
    
    @Test("Deleting an article also deletes associated tags if no more articles point to them")
    func deleteDeletesAssociatedTagsIfNoArticlesPointToThem() async throws {
        
    }
    
    // unlike tags, authors do not get automatically deleted
    
    @Test("Deleting an article throws if the article is not found")
    func deleteThrowsIfNotFound() async throws {
        
    }
}
