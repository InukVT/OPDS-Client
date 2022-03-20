//
//  PersistantStore.swift
//  OPDS-Client
//
//  Created by Bastian Inuk Christensen on 2022-03-20.
//

import Foundation
import CoreData
import os

class DataController : ObservableObject {
    let container = NSPersistentContainer(name: "Server")
    
    private let logger = Logger()
    
    init() {
        
        container.loadPersistentStores { [self] description, error in
            self.container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            
            if let error = error {
                logger.error("Core Data failed to load: \(error.localizedDescription)")
            }
        }
        
    }
}
