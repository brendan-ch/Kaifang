//
//  CDFlashcard.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.05.25.
//

import CoreData

@objc(CDFlashcard)
public class CDFlashcard: NSManagedObject {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        self.id = UUID()
        self.dueDate = Date()
    }
}
