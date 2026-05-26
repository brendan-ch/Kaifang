//
//  CDEntityWithDateMetadata.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.05.25.
//

import CoreData

@objc(CDEntityWithDateMetadata)
public class CDEntityWithDateMetadata: NSManagedObject {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        self.dateCreated = Date()
        self.dateModified = Date()
    }
    
    public override func willSave() {
        super.willSave()
        guard self.hasChanges else { return }
        guard let dateModified = self.dateModified else {
            self.dateCreated = Date()
            return
        }
        
        if !dateModified.isCloseToNow() {
            self.dateModified = Date()
        }
    }
}
