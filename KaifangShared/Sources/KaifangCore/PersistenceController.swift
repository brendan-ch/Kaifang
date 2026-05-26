//
//  PersistenceController.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.05.25.
//

import CoreData

public final class PersistenceController {
    public let container: NSPersistentContainer
    
    public init(inMemory: Bool = false, containerIdentifier: String? = nil) {
        let modelURL = Bundle.module.url(forResource: "KaifangModel", withExtension: "momd")!
        let model = NSManagedObjectModel(contentsOf: modelURL)!
        container = NSPersistentCloudKitContainer(name: "KaifangModel", managedObjectModel: model)
        
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("No persistent store description")
        }
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTokenKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        // note: relaunch needed if this setting is changed
        // also need a separate path to delete iCloud data if toggled off
        if let containerIdentifier = containerIdentifier {
            description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: containerIdentifier
            )
        } else {
            description.cloudKitContainerOptions = nil
        }
        
        if inMemory {
            description.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { _, error in
            if let error { fatalError("Core Data failed: \(error)") }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
