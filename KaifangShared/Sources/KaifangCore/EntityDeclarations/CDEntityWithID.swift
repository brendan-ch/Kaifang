//
//  CDEntityWithID.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.05.26.
//

import CoreData

@objc(CDEntityWithID)
public class CDEntityWithID: NSManagedObject {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        self.id = UUID()
    }

}
