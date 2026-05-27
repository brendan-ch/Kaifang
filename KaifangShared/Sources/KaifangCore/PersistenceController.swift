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

        let storeDirectory = NSPersistentContainer.defaultDirectoryURL()

        // Cloud-synced store: holds everything assigned to the "Cloud" configuration.
        // note: relaunch needed if containerIdentifier is changed
        // also need a separate path to delete iCloud data if toggled off
        let cloudDescription: NSPersistentStoreDescription
        if inMemory {
            cloudDescription = NSPersistentStoreDescription(url: URL(fileURLWithPath: "/dev/null/Cloud"))
            cloudDescription.type = NSInMemoryStoreType
        } else {
            cloudDescription = NSPersistentStoreDescription(
                url: storeDirectory.appendingPathComponent("KaifangModel.sqlite")
            )
        }
        
        cloudDescription.configuration = "Cloud"
        cloudDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTokenKey)
        cloudDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        if let containerIdentifier {
            cloudDescription.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: containerIdentifier
            )
        }

        // Local-only store: holds device-specific data (e.g. translation model providers)
        // that should never sync via CloudKit.
        let localDescription: NSPersistentStoreDescription
        if inMemory {
            localDescription = NSPersistentStoreDescription(
                url: URL(fileURLWithPath: "/dev/null/Local")
            )
            localDescription.type = NSInMemoryStoreType
        } else {
            localDescription = NSPersistentStoreDescription(url: storeDirectory.appendingPathComponent("KaifangModel-Local.sqlite"))
        }
        localDescription.configuration = "Local"

        container.persistentStoreDescriptions = [cloudDescription, localDescription]

        container.loadPersistentStores { _, error in
            if let error { fatalError("Core Data failed: \(error)") }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
