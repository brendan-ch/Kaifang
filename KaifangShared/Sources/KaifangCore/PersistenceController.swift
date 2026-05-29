//
//  PersistenceController.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.05.25.
//

import CoreData

public final class PersistenceController {
    public let container: NSPersistentContainer

    private static let modelName = "KaifangModel"

    public init(inMemory: Bool = false, containerIdentifier: String? = nil) throws(Error) {
        guard let modelURL = Bundle.module.url(forResource: Self.modelName, withExtension: "momd") else {
            throw .modelNotFound(name: Self.modelName)
        }
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            throw .modelLoadFailed(url: modelURL)
        }
        container = NSPersistentCloudKitContainer(name: Self.modelName, managedObjectModel: model)

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
        cloudDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
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

        // `loadPersistentStores` invokes the handler once per store, synchronously
        // for the store types used here. Capture the first failure and surface it
        // to the caller instead of crashing — migration mismatches, a corrupt
        // store, or missing CloudKit entitlements all land here.
        var storeLoadFailure: (store: String, underlying: Swift.Error)?
        container.loadPersistentStores { description, error in
            if let error, storeLoadFailure == nil {
                let store = description.configuration
                    ?? description.url?.lastPathComponent
                    ?? "unknown"
                storeLoadFailure = (store, error)
            }
        }
        if let storeLoadFailure {
            throw .storeLoadFailed(store: storeLoadFailure.store, underlying: storeLoadFailure.underlying)
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    public enum Error: LocalizedError {
        case modelNotFound(name: String)
        case modelLoadFailed(url: URL)
        case storeLoadFailed(store: String, underlying: Swift.Error)

        public var errorDescription: String? {
            switch self {
            case .modelNotFound(let name):
                "Couldn't locate the Core Data model \"\(name)\" in the package bundle."
            case .modelLoadFailed(let url):
                "Couldn't load the Core Data model at \(url.path)."
            case .storeLoadFailed(let store, let underlying):
                "Couldn't load the \"\(store)\" persistent store: \(underlying.localizedDescription)"
            }
        }
    }
}
