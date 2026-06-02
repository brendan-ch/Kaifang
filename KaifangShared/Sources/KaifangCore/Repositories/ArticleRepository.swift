//
//  ArticleRepository.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.06.01.
//

import CoreData
import Foundation

public final class ArticleRepository {
    public typealias Tag = ArticleProvider.Tag
    public typealias Author = ArticleProvider.Author
    public typealias FilterArguments = ArticleProvider.FilterArguments
    public typealias SortCriteria = ArticleProvider.SortCriteria
    public typealias Article = ArticleProvider.Article
    public typealias SentenceToken = SegmentationProvider.SentenceToken
    public typealias WordToken = SegmentationProvider.WordToken

    private let container: NSPersistentContainer

    public init(container: NSPersistentContainer) {
        self.container = container
    }

    // MARK: Tags

    public func getTags() async throws -> Set<Tag> {
        try await container.performBackgroundTask { context in
            let request = NSFetchRequest<CDTag>(entityName: "CDTag")
            let entities = try context.fetch(request)
            return try Set(entities.map(Tag.fromCoreData))
        }
    }

    public func saveTags(_ tags: Set<Tag>) async throws -> Set<Tag> {
        try await container.performBackgroundTask { context in
            for tag in tags {
                let entity: CDTag
                if let existing = try Self.fetchTagEntity(id: tag.id, in: context) {
                    entity = existing
                } else {
                    entity = CDTag(context: context)
                    entity.id = tag.id
                }
                entity.name = tag.name
            }
            try context.save()
            return tags
        }
    }

    // MARK: Authors

    public func getAuthors() async throws -> Set<Author> {
        try await container.performBackgroundTask { context in
            let request = NSFetchRequest<CDAuthor>(entityName: "CDAuthor")
            let entities = try context.fetch(request)
            return try Set(entities.map(Author.fromCoreData))
        }
    }

    public func saveAuthors(_ authors: Set<Author>) async throws -> Set<Author> {
        try await container.performBackgroundTask { context in
            for author in authors {
                let entity: CDAuthor
                if let existing = try Self.fetchAuthorEntity(id: author.id, in: context) {
                    entity = existing
                } else {
                    entity = CDAuthor(context: context)
                    entity.id = author.id
                }
                entity.name = author.name
            }
            try context.save()
            return authors
        }
    }

    // MARK: Listing / finding

    public func list(
        filterBy arguments: FilterArguments,
        sortBy sortArguments: SortCriteria
    ) async throws -> [Article] {
        try await container.performBackgroundTask { context in
            let request = NSFetchRequest<CDBaseArticle>(entityName: "CDBaseArticle")
            request.predicate = Self.buildPredicate(from: arguments)
            request.sortDescriptors = Self.buildSortDescriptors(from: sortArguments)
            let entities = try context.fetch(request)
            return try entities.map(Article.fromCoreData)
        }
    }

    public func find(_ id: UUID) async throws -> Article? {
        try await container.performBackgroundTask { context in
            guard let entity = try Self.fetchArticleEntity(id: id, in: context) else {
                return nil
            }
            return try Article.fromCoreData(entity)
        }
    }

    // MARK: Sentence tokens

    public func getSentenceTokens(forArticleId id: UUID) async throws -> [SentenceToken] {
        try await container.performBackgroundTask { context in
            guard let article = try Self.fetchArticleEntity(id: id, in: context) else {
                throw ArticleProvider.Error.notFound
            }
            return try Self.sortedSentenceTokens(of: article)
        }
    }

    public func saveSentenceTokens(_ tokens: [SentenceToken], forArticleId id: UUID) async throws -> [SentenceToken] {
        try await container.performBackgroundTask { context in
            guard let article = try Self.fetchArticleEntity(id: id, in: context) else {
                throw ArticleProvider.Error.notFound
            }

            let existing = (article.sentenceTokens as? Set<CDArticleSentenceToken>) ?? []
            let existingById: [UUID: CDArticleSentenceToken] = Dictionary(uniqueKeysWithValues: existing.compactMap { entity in
                entity.id.map { ($0, entity) }
            })
            // Track every index that's claimed within this save (both persisted and freshly
            // created this batch) so two NEW tokens that collide on each other are caught the
            // same way new-vs-existing collisions are.
            var claimedIndexes = Set(existing.map(\.sentenceIndexInArticle))

            for token in tokens {
                if let existingEntity = existingById[token.id] {
                    Self.updateSentenceTokenEntity(existingEntity, from: token, in: context)
                } else {
                    if claimedIndexes.contains(token.sentenceIndexInArticle) {
                        throw SegmentationProvider.Error.tokenAlreadyExistsAtIndex(index: token.sentenceIndexInArticle)
                    }
                    claimedIndexes.insert(token.sentenceIndexInArticle)
                    Self.createSentenceTokenEntity(from: token, on: article, in: context)
                }
            }

            try context.save()
            return try Self.sortedSentenceTokens(of: article)
        }
    }

    public func clearSentenceTokens(forArticleId id: UUID) async throws {
        try await container.performBackgroundTask { context in
            guard let article = try Self.fetchArticleEntity(id: id, in: context) else {
                throw ArticleProvider.Error.notFound
            }
            let sentenceEntities = (article.sentenceTokens as? Set<CDArticleSentenceToken>) ?? []
            for entity in sentenceEntities {
                context.delete(entity)
            }
            try context.save()
        }
    }

    // MARK: Saving articles

    public func save(_ articles: [Article]) async throws -> [Article] {
        try await container.performBackgroundTask { context in
            var entities: [CDBaseArticle] = []
            entities.reserveCapacity(articles.count)
            for article in articles {
                entities.append(try Self.upsertArticle(article, in: context))
            }
            try context.save()
            return try entities.map(Article.fromCoreData)
        }
    }

    public func save(_ article: Article) async throws -> Article {
        try await container.performBackgroundTask { context in
            let entity = try Self.upsertArticle(article, in: context)
            try context.save()
            return try Article.fromCoreData(entity)
        }
    }

    // MARK: Deletion

    public func delete(id: UUID) async throws {
        try await container.performBackgroundTask { context in
            guard let entity = try Self.fetchArticleEntity(id: id, in: context) else {
                throw ArticleProvider.Error.notFound
            }

            let associatedTags = (entity.tags as? Set<CDTag>) ?? []

            context.delete(entity)
            context.processPendingChanges()

            for tag in associatedTags {
                let remainingArticles = (tag.articles as? Set<CDBaseArticle>) ?? []
                if remainingArticles.isEmpty {
                    context.delete(tag)
                }
            }

            try context.save()
        }
    }

    public func clear() async throws {
        try await container.performBackgroundTask { context in
            let request = NSFetchRequest<CDBaseArticle>(entityName: "CDBaseArticle")
            for entity in try context.fetch(request) {
                context.delete(entity)
            }
            try context.save()
        }
    }

    // MARK: Predicate / sort helpers

    private static func buildPredicate(from arguments: FilterArguments) -> NSPredicate? {
        var predicates: [NSPredicate] = []

        if let tags = arguments.tags, !tags.isEmpty {
            // Articles must contain ALL of the requested tags.
            for tag in tags {
                predicates.append(NSPredicate(format: "ANY tags.id == %@", tag.id as CVarArg))
            }
        }

        if let keyword = arguments.titleAndContents, !keyword.isEmpty {
            predicates.append(NSPredicate(
                format: "title CONTAINS[c] %@ OR plainText CONTAINS[c] %@",
                keyword,
                keyword
            ))
        }

        if arguments.unreadOnly == true {
            predicates.append(NSPredicate(format: "dateRead == nil"))
        }

        if predicates.isEmpty {
            return nil
        }
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    private static func buildSortDescriptors(from criteria: SortCriteria) -> [NSSortDescriptor] {
        switch criteria {
        case .title(let order):
            return [NSSortDescriptor(
                key: "title",
                ascending: order == .forward,
                selector: #selector(NSString.localizedCompare(_:))
            )]
        case .dateCreated(let order):
            return [NSSortDescriptor(key: "dateCreated", ascending: order == .forward)]
        case .dateModified(let order):
            return [NSSortDescriptor(key: "dateModified", ascending: order == .forward)]
        }
    }

    // MARK: Article entity helpers

    private static func upsertArticle(_ article: Article, in context: NSManagedObjectContext) throws -> CDBaseArticle {
        let entity: CDBaseArticle
        if let existing = try fetchArticleEntity(id: article.id, in: context) {
            entity = existing
        } else {
            entity = CDBaseArticle(context: context)
            entity.id = article.id
        }

        entity.title = article.title
        entity.plainText = article.plainText
        entity.datePublished = article.datePublished
        entity.dateRead = article.dateRead
        // CDEntityWithIDAndDateMetadata's awakeFromInsert sets both timestamps to Date() and
        // willSave bumps dateModified unless it's already close to now. Override both directly
        // so caller-supplied values survive the roundtrip — and on update, the caller's
        // dateCreated wins over the previously persisted value.
        entity.dateCreated = article.dateCreated
        entity.dateModified = article.dateModified

        var resolvedTags: Set<CDTag> = []
        for tag in article.tags {
            resolvedTags.insert(try resolveTagEntity(tag, in: context))
        }
        entity.tags = NSSet(set: resolvedTags)

        var resolvedAuthors: Set<CDAuthor> = []
        for author in article.authors {
            resolvedAuthors.insert(try resolveAuthorEntity(author, in: context))
        }
        entity.authors = NSSet(set: resolvedAuthors)

        return entity
    }

    private static func resolveTagEntity(_ tag: Tag, in context: NSManagedObjectContext) throws -> CDTag {
        if let existing = try fetchTagEntity(id: tag.id, in: context) {
            return existing
        }
        if try fetchTagEntity(name: tag.name, in: context) != nil {
            throw ArticleProvider.Error.tagNameConflict(name: tag.name)
        }
        let entity = CDTag(context: context)
        entity.id = tag.id
        entity.name = tag.name
        return entity
    }

    private static func resolveAuthorEntity(_ author: Author, in context: NSManagedObjectContext) throws -> CDAuthor {
        if let existing = try fetchAuthorEntity(id: author.id, in: context) {
            return existing
        }
        if try fetchAuthorEntity(name: author.name, in: context) != nil {
            throw ArticleProvider.Error.authorNameConflict(name: author.name)
        }
        let entity = CDAuthor(context: context)
        entity.id = author.id
        entity.name = author.name
        return entity
    }

    // MARK: Sentence token helpers

    private static func sortedSentenceTokens(of article: CDBaseArticle) throws -> [SentenceToken] {
        let entities = (article.sentenceTokens as? Set<CDArticleSentenceToken>) ?? []
        return try entities
            .map(SentenceToken.fromCoreData)
            .sorted { $0.sentenceIndexInArticle < $1.sentenceIndexInArticle }
    }

    private static func updateSentenceTokenEntity(
        _ entity: CDArticleSentenceToken,
        from token: SentenceToken,
        in context: NSManagedObjectContext
    ) {
        entity.tokenText = token.tokenText
        entity.articleTextPositionStart = token.articleTextPositionStart
        entity.sentenceIndexInArticle = token.sentenceIndexInArticle

        let oldWords = (entity.words as? Set<CDArticleWordToken>) ?? []
        for word in oldWords {
            context.delete(word)
        }

        var newWords: Set<CDArticleWordToken> = []
        for word in token.wordTokens {
            newWords.insert(makeWordTokenEntity(from: word, in: context))
        }
        entity.words = NSSet(set: newWords)
    }

    private static func createSentenceTokenEntity(
        from token: SentenceToken,
        on article: CDBaseArticle,
        in context: NSManagedObjectContext
    ) {
        let entity = CDArticleSentenceToken(context: context)
        entity.id = token.id
        entity.tokenText = token.tokenText
        entity.articleTextPositionStart = token.articleTextPositionStart
        entity.sentenceIndexInArticle = token.sentenceIndexInArticle
        entity.article = article

        var newWords: Set<CDArticleWordToken> = []
        for word in token.wordTokens {
            newWords.insert(makeWordTokenEntity(from: word, in: context))
        }
        entity.words = NSSet(set: newWords)
    }

    private static func makeWordTokenEntity(
        from token: WordToken,
        in context: NSManagedObjectContext
    ) -> CDArticleWordToken {
        let entity = CDArticleWordToken(context: context)
        entity.id = token.id
        entity.tokenText = token.tokenText
        entity.sentenceTextPositionStart = token.sentenceTextPositionStart
        entity.wordIndexInSentence = token.wordIndexInSentence
        return entity
    }

    // MARK: Fetch helpers

    private static func fetchArticleEntity(id: UUID, in context: NSManagedObjectContext) throws -> CDBaseArticle? {
        let request = NSFetchRequest<CDBaseArticle>(entityName: "CDBaseArticle")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    private static func fetchTagEntity(id: UUID, in context: NSManagedObjectContext) throws -> CDTag? {
        let request = NSFetchRequest<CDTag>(entityName: "CDTag")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    // Case-insensitive ==[c] is intentional: "News" and "news" should be treated as the same
    // tag/author for conflict-detection purposes.
    private static func fetchTagEntity(name: String, in context: NSManagedObjectContext) throws -> CDTag? {
        let request = NSFetchRequest<CDTag>(entityName: "CDTag")
        request.predicate = NSPredicate(format: "name ==[c] %@", name)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    private static func fetchAuthorEntity(id: UUID, in context: NSManagedObjectContext) throws -> CDAuthor? {
        let request = NSFetchRequest<CDAuthor>(entityName: "CDAuthor")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    private static func fetchAuthorEntity(name: String, in context: NSManagedObjectContext) throws -> CDAuthor? {
        let request = NSFetchRequest<CDAuthor>(entityName: "CDAuthor")
        request.predicate = NSPredicate(format: "name ==[c] %@", name)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
}
