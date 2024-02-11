//
//  BookmarkRepository.swift
//  Marlin
//
//  Created by Daniel Barela on 9/19/23.
//

import Foundation
import CoreData

class BookmarkRepositoryManager: BookmarkRepository, ObservableObject {
    private var repository: BookmarkRepository
    init(repository: BookmarkRepository) {
        self.repository = repository
    }
    
    func getBookmark(itemKey: String, dataSource: String) -> BookmarkModel? {
        repository.getBookmark(itemKey: itemKey, dataSource: dataSource)
    }

    func createBookmark(notes: String?, itemKey: String, dataSource: String) async {
        await repository.createBookmark(notes: notes, itemKey: itemKey, dataSource: dataSource)
    }

    func removeBookmark(itemKey: String, dataSource: String) -> Bool {
        repository.removeBookmark(itemKey: itemKey, dataSource: dataSource)
    }
    func getDataSourceItem(itemKey: String, dataSource: String) -> (any Bookmarkable)? {
        repository.getDataSourceItem(itemKey: itemKey, dataSource: dataSource)
    }
}

protocol BookmarkRepository {
    @discardableResult
    func getBookmark(itemKey: String, dataSource: String) -> BookmarkModel?

    func createBookmark(notes: String?, itemKey: String, dataSource: String) async
    func removeBookmark(itemKey: String, dataSource: String) -> Bool
    func getDataSourceItem(itemKey: String, dataSource: String) -> (any Bookmarkable)?
}

class BookmarkCoreDataRepository: BookmarkRepository, ObservableObject {
    private var context: NSManagedObjectContext
    
    required init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func getBookmark(itemKey: String, dataSource: String) -> BookmarkModel? {
        if let bookmark = try? context.fetchFirst(
            Bookmark.self,
            predicate: NSPredicate(format: "id == %@ AND dataSource == %@", itemKey, dataSource)) {
            return BookmarkModel(bookmark: bookmark)
        }
        return nil
    }

    func createBookmark(notes: String?, itemKey: String, dataSource: String) async {
        await context.perform {
            let bookmark = Bookmark(context: self.context)
            bookmark.notes = notes
            bookmark.dataSource = dataSource
            bookmark.id = itemKey
            bookmark.timestamp = Date()
            do {
                try self.context.save()
            } catch {
                print("Error saving bookmark \(error)")
            }
        }
    }

    func removeBookmark(itemKey: String, dataSource: String) -> Bool {
        let viewContext = PersistenceController.current.viewContext
        return viewContext.performAndWait {
            let request = Bookmark.fetchRequest()
            request.predicate = NSPredicate(format: "id = %@ AND dataSource = %@", itemKey, dataSource)
            for bookmark in viewContext.fetch(request: request) ?? [] {
                viewContext.delete(bookmark)
            }
            do {
                try viewContext.save()
                return true
//                self.isBookmarked = false
            } catch {
                print("Error removing bookmark")
            }
            return false
        }
    }

    func getDataSourceItem(itemKey: String, dataSource: String) -> (any Bookmarkable)? {
        switch dataSource {
        case DataSources.asam.key:
            return MSI.shared.asamRepository?.getAsam(reference: itemKey)
        case DataSources.modu.key:
            return MSI.shared.moduRepository?.getModu(name: itemKey)
        case DataSources.port.key:
            return MSI.shared.portRepository?.getPort(portNumber: Int64(itemKey))
        case NavigationalWarning.key:
                return NavigationalWarning.getItem(context: context, itemKey: itemKey)
        case NoticeToMariners.key:
                return NoticeToMariners.getItem(context: context, itemKey: itemKey)
        case DataSources.dgps.key:
            let split = itemKey.split(separator: "--")
            if split.count == 2 {
                return MSI.shared.differentialGPSStationRepository?.getDifferentialGPSStation(
                    featureNumber: Int(split[0]) ?? -1,
                    volumeNumber: "\(split[1])"
                )
            }
        case DataSources.light.key:
            let split = itemKey.split(separator: "--")
            if split.count == 3 {
                return MSI.shared.lightRepository?.getCharacteristic(
                    featureNumber: "\(split[0])",
                    volumeNumber: "\(split[1])",
                    characteristicNumber: 1
                )
            }
        case DataSources.radioBeacon.key:
            let split = itemKey.split(separator: "--")
            if split.count == 2 {
                return MSI.shared.radioBeaconRepository?.getRadioBeacon(
                    featureNumber: Int(split[0]) ?? -1,
                    volumeNumber: "\(split[1])"
                )
            }
        case ElectronicPublication.key:
                return ElectronicPublication.getItem(context: context, itemKey: itemKey)
        case GeoPackageFeatureItem.key:
                return GeoPackageFeatureItem.getItem(context: context, itemKey: itemKey)
        default:
            print("default")
        }
        return nil
    }
}
