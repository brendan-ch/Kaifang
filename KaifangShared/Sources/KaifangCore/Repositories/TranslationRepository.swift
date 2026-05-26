//
//  TranslationRepository.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.05.25.
//

import CoreData

/// Central class for retrieving and saving translations.
public class TranslationRepository {
    private let container: NSPersistentContainer
    
    public init(container: NSPersistentContainer) {
        self.container = container
    }
    
    public func lookup(_ lookup: LookupArguments) async throws -> Translation? {
        return nil
    }
    
    public func find(id: UUID) async throws -> Translation? {
        return nil
    }
    
    public func save(_ translation: Translation) async throws {
        
    }
    
    public func delete(id: UUID) async throws {
        
    }
    
    public func clear() async throws {
        
    }
}
