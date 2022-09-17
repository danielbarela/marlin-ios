//
//  DFRSArea+CoreDataClass.swift
//  Marlin
//
//  Created by Daniel Barela on 9/17/22.
//

import Foundation
import CoreData

extension DFRSArea: BatchImportable {
    static var seedDataFiles: [String]? = ["dfrsAreas"]
    static var key: String = "dfrsAreas"
    static var decodableRoot: Decodable.Type = DFRSAreaPropertyContainer.self
    
    static func batchImport(value: Decodable?) async throws {
        guard let value = value as? DFRSAreaPropertyContainer else {
            return
        }
        let count = value.areas.count
        NSLog("Received \(count) DFRS Area records.")
        try await Self.batchImport(from: value.areas, taskContext: PersistenceController.shared.newTaskContext())
    }
    
    static func dataRequest() -> [MSIRouter] {
        return [MSIRouter.readDFRSAreas]
    }
    
    static func shouldSync() -> Bool {
        // sync once every week
        return UserDefaults.standard.dataSourceEnabled(DFRSArea.self) && (Date().timeIntervalSince1970 - (60 * 60 * 24 * 7)) > UserDefaults.standard.lastSyncTimeSeconds(DFRSArea.self)
    }
}

class DFRSArea: NSManagedObject {
    static func newBatchInsertRequest(with propertyList: [DFRSAreaProperties]) -> NSBatchInsertRequest {
        var index = 0
        let total = propertyList.count
        
        // Provide one dictionary at a time when the closure is called.
        let batchInsertRequest = NSBatchInsertRequest(entity: DFRSArea.entity(), dictionaryHandler: { dictionary in
            guard index < total else { return true }
            dictionary.addEntries(from: propertyList[index].dictionaryValue.filter({
                return $0.value != nil
            }) as [AnyHashable : Any])
            index += 1
            return false
        })
        return batchInsertRequest
    }
    
    static func batchImport(from propertiesList: [DFRSAreaProperties], taskContext: NSManagedObjectContext) async throws {
        guard !propertiesList.isEmpty else { return }
        
        // Add name and author to identify source of persistent history changes.
        taskContext.name = "importContext"
        taskContext.transactionAuthor = "importDFRSArea"
        
        /// - Tag: performAndWait
        try await taskContext.perform {
            // Execute the batch insert.
            /// - Tag: batchInsertRequest
            let batchInsertRequest = DFRSArea.newBatchInsertRequest(with: propertiesList)
            if let fetchResult = try? taskContext.execute(batchInsertRequest),
               let batchInsertResult = fetchResult as? NSBatchInsertResult,
               let success = batchInsertResult.result as? Bool, success {
                return
            }
            throw MSIError.batchInsertError
        }
    }
}
