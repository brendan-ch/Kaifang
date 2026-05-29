//
//  PersistenceController.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.05.25.
//

import KaifangCore
import CoreData

extension PersistenceController {
    static func getTestingContainer() throws -> NSPersistentContainer {
        try PersistenceController(inMemory: true).container
    }

    static func getTestingContext() throws -> NSManagedObjectContext {
        let persistenceController = try PersistenceController(inMemory: true)
        let context = persistenceController.container.viewContext
        return context
    }
}
