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
    
    
}
