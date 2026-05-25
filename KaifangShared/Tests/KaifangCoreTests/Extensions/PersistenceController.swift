//
//  PersistenceController.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.05.25.
//

import KaifangCore
import CoreData

extension PersistenceController {
    static func getTestingContext() -> NSManagedObjectContext {
        let persistenceController = PersistenceController(inMemory: true)
        let context = persistenceController.container.viewContext
        return context
    }
}
