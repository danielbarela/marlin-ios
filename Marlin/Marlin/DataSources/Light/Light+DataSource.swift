//
//  Light+DataSource.swift
//  Marlin
//
//  Created by Daniel Barela on 9/17/22.
//

import Foundation
import UIKit
import CoreData

extension Light: DataSource {
    static var isMappable: Bool = true
    static var dataSourceName: String = NSLocalizedString("Lights", comment: "Lights data source display name")
    static var fullDataSourceName: String = NSLocalizedString("Lights", comment: "Lights data source display name")
    static var key: String = "light"
    static var imageName: String? = nil
    static var systemImageName: String? = "lightbulb.fill"
    static var color: UIColor = UIColor(argbValue: 0xFFFFC500)
    static var imageScale = UserDefaults.standard.imageScale(key) ?? 0.66
}

extension Light: BatchImportable {
    static var seedDataFiles: [String]? = ["lights"]//["light110","light111","light112","light113","light114","light115","light116"]
    static var decodableRoot: Decodable.Type = LightsPropertyContainer.self
    
    static func batchImport(value: Decodable?) async throws {
        guard let value = value as? LightsPropertyContainer else {
            return
        }
        let count = value.ngalol.count
        NSLog("Received \(count) \(Self.key) records.")
        try await Light.batchImport(from: value.ngalol, taskContext: PersistenceController.shared.newTaskContext())
    }
    
    static func dataRequest() -> [MSIRouter] {
        var requests: [MSIRouter] = []
        
        for lightVolume in Light.lightVolumes {
            let newestLight = try? PersistenceController.shared.container.viewContext.fetchFirst(Light.self, sortBy: [NSSortDescriptor(keyPath: \Light.noticeNumber, ascending: false)], predicate: NSPredicate(format: "volumeNumber = %@", lightVolume.volumeNumber))
            
            let noticeWeek = Int(newestLight?.noticeWeek ?? "0") ?? 0
            
            print("Query for lights in volume \(lightVolume) after year:\(newestLight?.noticeYear ?? "") week:\(noticeWeek)")
            
            requests.append(MSIRouter.readLights(volume: lightVolume.volumeQuery, noticeYear: newestLight?.noticeYear, noticeWeek: String(format: "%02d", noticeWeek + 1)))
        }
        
        return requests
    }
    
    static func shouldSync() -> Bool {
        // sync once every week
        return UserDefaults.standard.dataSourceEnabled(Light.self) && (Date().timeIntervalSince1970 - (60 * 60 * 24 * 7)) > UserDefaults.standard.lastSyncTimeSeconds(Light.self)
    }
    
    static func newBatchInsertRequest(with propertyList: [LightsProperties]) -> NSBatchInsertRequest {
        var index = 0
        let total = propertyList.count
        NSLog("Creating batch insert request of lights for \(total) lights")
        
        struct PreviousLocation {
            var previousRegionHeading: String?
            var previousSubregionHeading: String?
            var previousLocalHeading: String?
        }
        
        var previousHeadingPerVolume: [String : PreviousLocation] = [:]
        // Provide one dictionary at a time when the closure is called.
        let batchInsertRequest = NSBatchInsertRequest(entity: Light.entity(), dictionaryHandler: { dictionary in
            guard index < total else { return true }
            let propertyDictionary = propertyList[index].dictionaryValue
            let volumeNumber = propertyDictionary["volumeNumber"] as? String ?? ""
            var previousLocation = previousHeadingPerVolume[volumeNumber]
            
            let region = propertyDictionary["regionHeading"] as? String ?? previousLocation?.previousRegionHeading
            let subregion = propertyDictionary["subregionHeading"] as? String ?? previousLocation?.previousSubregionHeading
            let local = propertyDictionary["localHeading"] as? String ?? previousLocation?.previousLocalHeading
            
            var correctedLocationDictionary: [String:String?] = [
                "regionHeading": propertyDictionary["regionHeading"] as? String ?? previousLocation?.previousRegionHeading,
                "subregionHeading": propertyDictionary["subregionHeading"] as? String ?? previousLocation?.previousSubregionHeading,
                "localHeading": propertyDictionary["localHeading"] as? String ?? previousLocation?.previousLocalHeading
            ]
            if let rh = correctedLocationDictionary["regionHeading"] as? String {
                correctedLocationDictionary["sectionHeader"] = "\(propertyDictionary["geopoliticalHeading"] as? String ?? ""): \(rh)"
            } else {
                correctedLocationDictionary["sectionHeader"] = "\(propertyDictionary["geopoliticalHeading"] as? String ?? "")"
            }
            
            if previousLocation?.previousRegionHeading != region {
                previousLocation?.previousRegionHeading = region
                previousLocation?.previousSubregionHeading = nil
                previousLocation?.previousLocalHeading = nil
            } else if previousLocation?.previousSubregionHeading != subregion {
                previousLocation?.previousSubregionHeading = subregion
                previousLocation?.previousLocalHeading = nil
            } else if previousLocation?.previousLocalHeading != local {
                previousLocation?.previousLocalHeading = local
            }
            previousHeadingPerVolume[volumeNumber] = previousLocation ?? PreviousLocation(previousRegionHeading: region, previousSubregionHeading: subregion, previousLocalHeading: local)
            
            dictionary.addEntries(from: propertyDictionary.filter({
                return $0.value != nil
            }) as [AnyHashable : Any])
            dictionary.addEntries(from: correctedLocationDictionary.filter({
                return $0.value != nil
            }) as [AnyHashable : Any])
            index += 1
            return false
        })
        return batchInsertRequest
    }
    
    static func batchImport(from propertiesList: [LightsProperties], taskContext: NSManagedObjectContext) async throws {
        guard !propertiesList.isEmpty else { return }
        
        // Add name and author to identify source of persistent history changes.
        taskContext.name = "importContext"
        taskContext.transactionAuthor = "importLight"
        
        /// - Tag: performAndWait
        try await taskContext.perform {
            // Execute the batch insert.
            /// - Tag: batchInsertRequest
            let batchInsertRequest = Light.newBatchInsertRequest(with: propertiesList)
            batchInsertRequest.resultType = .count
            do {
                let fetchResult = try taskContext.execute(batchInsertRequest)
                if let batchInsertResult = fetchResult as? NSBatchInsertResult {
                    if let count = batchInsertResult.result as? Int, count > 0 {
                        NSLog("Inserted \(count) Light records")
                        NotificationCenter.default.post(name: .DataSourceUpdated, object: DataSourceItem(dataSource: Light.self))
                    } else {
                        NSLog("No new Light records")
                    }
                    // if there were already lights in the db for this volume and this was an update and we got back a light we have to go redo the query due to regions not being populated on all returned objects
                    return
                }
            } catch {
                print("error was \(error)")
            }
            throw MSIError.batchInsertError
        }
    }
}