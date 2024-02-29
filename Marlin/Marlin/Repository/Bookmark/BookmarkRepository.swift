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
    @discardableResult
    func removeBookmark(itemKey: String, dataSource: String) -> Bool
    func getDataSourceItem(itemKey: String, dataSource: String) -> (any Bookmarkable)?
}

class BookmarkCoreDataRepository: BookmarkRepository, ObservableObject {
    private lazy var context: NSManagedObjectContext = {
        PersistenceController.current.newTaskContext()
    }()

    let asamRepository: AsamRepository?
    let dgpsRepository: DGPSStationRepository?
    let lightRepository: LightRepository?
    let moduRepository: ModuRepository?
    let portRepository: PortRepository?
    let radioBeaconRepository: RadioBeaconRepository?
    let noticeToMarinersRepository: NoticeToMarinersRepository?
    let publicationRepository: PublicationRepository?
    let navigationalWarningRepository: NavigationalWarningRepository?

    init(
        asamRepository: AsamRepository? = nil,
        dgpsRepository: DGPSStationRepository? = nil,
        lightRepository: LightRepository? = nil,
        moduRepository: ModuRepository? = nil,
        portRepository: PortRepository? = nil,
        radioBeaconRepository: RadioBeaconRepository? = nil,
        noticeToMarinersRepository: NoticeToMarinersRepository? = nil,
        publicationRepository: PublicationRepository? = nil,
        navigationalWarningRepository: NavigationalWarningRepository? = nil
    ) {
        self.asamRepository = asamRepository
        self.dgpsRepository = dgpsRepository
        self.lightRepository = lightRepository
        self.moduRepository = moduRepository
        self.portRepository = portRepository
        self.radioBeaconRepository = radioBeaconRepository
        self.noticeToMarinersRepository = noticeToMarinersRepository
        self.publicationRepository = publicationRepository
        self.navigationalWarningRepository = navigationalWarningRepository
    }

    func getBookmark(itemKey: String, dataSource: String) -> BookmarkModel? {
        return context.performAndWait {
            if let bookmark = try? context.fetchFirst(
                Bookmark.self,
                predicate: NSPredicate(format: "id == %@ AND dataSource == %@", itemKey, dataSource)) {
                return BookmarkModel(bookmark: bookmark)
            }
            return nil
        }
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
        return context.performAndWait {
            let request = Bookmark.fetchRequest()
            request.predicate = NSPredicate(format: "id = %@ AND dataSource = %@", itemKey, dataSource)
            for bookmark in context.fetch(request: request) ?? [] {
                context.delete(bookmark)
            }
            do {
                try context.save()
                return true
            } catch {
                print("Error removing bookmark")
            }
            return false
        }
    }

    func getDataSourceItem(itemKey: String, dataSource: String) -> (any Bookmarkable)? {
        let split = itemKey.split(separator: "--")
        switch dataSource {
        case DataSources.asam.key:
            return asamRepository?.getAsam(reference: itemKey)
        case DataSources.modu.key:
            return moduRepository?.getModu(name: itemKey)
        case DataSources.port.key:
            return portRepository?.getPort(portNumber: Int64(itemKey))
        case DataSources.navWarning.key:
            if split.count == 3 {
                return navigationalWarningRepository?.getNavigationalWarning(
                    msgYear: Int(split[0]) ?? 0,
                    msgNumber: Int(split[1]) ?? 0,
                    navArea: "\(split[2])"
                )
            }
        case DataSources.noticeToMariners.key:
            return noticeToMarinersRepository?.getNoticesToMariners(noticeNumber: Int(itemKey))?.first
        case DataSources.dgps.key:
            if split.count == 2 {
                return dgpsRepository?.getDGPSStation(
                    featureNumber: Int(split[0]) ?? -1,
                    volumeNumber: "\(split[1])"
                )
            }
        case DataSources.light.key:
            if split.count == 3 {
                return lightRepository?.getCharacteristic(
                    featureNumber: "\(split[0])",
                    volumeNumber: "\(split[1])",
                    characteristicNumber: 1
                )
            }
        case DataSources.radioBeacon.key:
            if split.count == 2 {
                return radioBeaconRepository?.getRadioBeacon(
                    featureNumber: Int(split[0]) ?? -1,
                    volumeNumber: "\(split[1])"
                )
            }
        case DataSources.epub.key:
            return publicationRepository?.getPublication(s3Key: itemKey)
        case GeoPackageFeatureItem.key:
            return GeoPackageFeatureItem.getItem(context: context, itemKey: itemKey)
        default:
            print("default")
        }
        return nil
    }
}
