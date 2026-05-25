//
//  PersistenceController.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.05.25.
//

import CoreData

public final class PersistenceController {
    public let container: NSPersistentContainer
    
    public init(inMemory: Bool = false) {
        let modelURL = Bundle.module.url(forResource: "KaifangModel", withExtension: "momd")!
        let model = NSManagedObjectModel(contentsOf: modelURL)!
        container = NSPersistentContainer(name: "KaifangModel", managedObjectModel: model)
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error { fatalError("Core Data failed: \(error)") }
        }
    }
}
