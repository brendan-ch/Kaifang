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
    // MARK: Setup
    private let container: NSPersistentContainer
    private let repository: ArticleRepository
    
    init() throws {
        container = try PersistenceController.getTestingContainer()
        repository = ArticleRepository(container: container)
    }
    
    // MARK: Tests
    
    @Test("Getting all tags gets them by alphabetical order")
    func getTagsReturnsInAlphabeticalOrder() async throws {
        
    }
    
    @Test("Getting all tags returns empty array if no tags exist")
    func getTagsReturnsEmptyArrayIfNonexistent() async throws {
        
    }
    
    @Test("Filtering filters by tags")
    func filterFiltersByTags() async throws {
    }
    
    @Test("Filtering title and contents filters by title")
    func filterByTitleAndContentsFiltersTitle() async throws {
        
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
    
    @Test("Deleting an article deletes the article")
    func deleteDeletesTheArticle() async throws {
        
    }
    
    @Test("Deleting an article also deletes its sentence tokens")
    func deleteDeletesSentenceTokens() async throws {
        
    }
    
    @Test("Deleting an article also deletes associated tags if no more articles point to them")
    func deleteDeletesAssociatedTagsIfNoArticlesPointToThem() async throws {
        
    }
    
    @Test("Deleting an article throws if the article is not found")
    func deleteThrowsIfNotFound() async throws {
        
    }
}
