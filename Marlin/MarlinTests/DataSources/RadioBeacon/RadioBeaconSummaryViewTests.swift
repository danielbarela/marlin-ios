//
//  RadioBeaconSummaryViewTests.swift
//  MarlinTests
//
//  Created by Daniel Barela on 1/19/23.
//

import XCTest
import Combine
import SwiftUI

@testable import Marlin

final class RadioBeaconSummaryViewTests: XCTestCase {
    var cancellable = Set<AnyCancellable>()
    var persistentStore: PersistentStore = PersistenceController.shared
    let persistentStoreLoadedPub = NotificationCenter.default.publisher(for: .PersistentStoreLoaded)
        .receive(on: RunLoop.main)
    
    override func setUp(completion: @escaping (Error?) -> Void) {
        for item in DataSourceList().allTabs {
            UserDefaults.standard.initialDataLoaded = false
            UserDefaults.standard.clearLastSyncTimeSeconds(item.dataSource.definition)
        }
        UserDefaults.standard.lastLoadDate = Date(timeIntervalSince1970: 0)
        
        UserDefaults.standard.setValue(Date(), forKey: "forceReloadDate")
        persistentStoreLoadedPub
            .removeDuplicates()
            .sink { output in
                completion(nil)
            }
            .store(in: &cancellable)
        persistentStore.reset()
    }
    
    override func tearDown() {
    }
    
    func testLoading() {
        
        var newItem: RadioBeacon?
        persistentStore.viewContext.performAndWait {
            let rb = RadioBeacon(context: persistentStore.viewContext)
            
            rb.volumeNumber = "PUB 110"
            rb.aidType = "Radiobeacons"
            rb.geopoliticalHeading = "GREENLAND"
            rb.regionHeading = nil
            rb.precedingNote = nil
            rb.featureNumber = 10
            rb.name = "Ittoqqortoormit, Scoresbysund"
            rb.position = "70°29'11.99\"N \n21°58'20\"W"
            rb.characteristic = "SC\n(• • •  - • - • ).\n"
            rb.range = 200
            rb.sequenceText = nil
            rb.frequency = "343\nNON, A2A."
            rb.stationRemark = "Aeromarine."
            rb.postNote = nil
            rb.noticeNumber = 199706
            rb.removeFromList = "N"
            rb.deleteFlag = "N"
            rb.noticeWeek = "06"
            rb.noticeYear = "1997"
            rb.latitude = 1.0
            rb.longitude = 2.0
            rb.sectionHeader = "section"
            
            try? persistentStore.viewContext.save()
            newItem = rb
        }
        
        guard let rb = newItem else {
            XCTFail()
            return
        }
        
        let repository = RadioBeaconRepositoryManager(repository: RadioBeaconCoreDataRepository(context: persistentStore.viewContext))
        let bookmarkRepository = BookmarkRepositoryManager(repository: BookmarkCoreDataRepository(context: persistentStore.viewContext))

        let summary = rb.summary
            .setShowMoreDetails(false)
            .environment(\.managedObjectContext, persistentStore.viewContext)
            .environmentObject(repository)
            .environmentObject(bookmarkRepository)
        
        let controller = UIHostingController(rootView: summary)
        let window = TestHelpers.getKeyWindowVisible()
        window.rootViewController = controller
        tester().waitForView(withAccessibilityLabel: "\(rb.featureNumber) \(rb.volumeNumber!)")
        tester().waitForView(withAccessibilityLabel: rb.name)
        tester().waitForAbsenceOfView(withAccessibilityLabel: "section")
        tester().waitForView(withAccessibilityLabel: rb.morseLetter)
        tester().waitForView(withAccessibilityLabel: rb.expandedCharacteristicWithoutCode)
        tester().waitForView(withAccessibilityLabel: rb.stationRemark)
        
        expectation(forNotification: .SnackbarNotification,
                    object: nil) { notification in
            let model = try? XCTUnwrap(notification.object as? SnackbarNotification)
            XCTAssertEqual(model?.snackbarModel?.message, "Location \(UserDefaults.standard.coordinateDisplay.format(coordinate: rb.coordinate)) copied to clipboard")
            XCTAssertEqual(UIPasteboard.general.string, "\(UserDefaults.standard.coordinateDisplay.format(coordinate: rb.coordinate))")
            return true
        }
        tester().tapView(withAccessibilityLabel: "Location")
        
        expectation(forNotification: .TabRequestFocus,
                    object: nil) { notification in
            return true
        }
        
        expectation(forNotification: .MapItemsTapped, object: nil) { notification in
            
            let tapNotification = try! XCTUnwrap(notification.object as? MapItemsTappedNotification)
            let rb = tapNotification.items as! [RadioBeaconModel]
            XCTAssertEqual(rb.count, 1)
            XCTAssertEqual(rb[0].name, "Ittoqqortoormit, Scoresbysund")
            return true
        }
        tester().tapView(withAccessibilityLabel: "focus")
        
        waitForExpectations(timeout: 10, handler: nil)
        
        tester().waitForView(withAccessibilityLabel: "share")
        tester().tapView(withAccessibilityLabel: "share")
        
        tester().waitForTappableView(withAccessibilityLabel: "dismiss popup")
        tester().tapView(withAccessibilityLabel: "dismiss popup")
        
        BookmarkHelper().verifyBookmarkButton(viewContext: persistentStore.viewContext, bookmarkable: rb)
    }
    
    func testShowMoreDetails() {
        let rb = RadioBeacon(context: persistentStore.viewContext)
        
        rb.volumeNumber = "PUB 110"
        rb.aidType = "Radiobeacons"
        rb.geopoliticalHeading = "GREENLAND"
        rb.regionHeading = nil
        rb.precedingNote = nil
        rb.featureNumber = 10
        rb.name = "Ittoqqortoormit, Scoresbysund"
        rb.position = "70°29'11.99\"N \n21°58'20\"W"
        rb.characteristic = "SC\n(• • •  - • - • ).\n"
        rb.range = 200
        rb.sequenceText = nil
        rb.frequency = "343\nNON, A2A."
        rb.stationRemark = "Aeromarine."
        rb.postNote = nil
        rb.noticeNumber = 199706
        rb.removeFromList = "N"
        rb.deleteFlag = "N"
        rb.noticeWeek = "06"
        rb.noticeYear = "1997"
        rb.latitude = 1.0
        rb.longitude = 2.0
        rb.sectionHeader = "section"
        
        let repository = RadioBeaconRepositoryManager(repository: RadioBeaconCoreDataRepository(context: persistentStore.viewContext))
        let bookmarkRepository = BookmarkRepositoryManager(repository: BookmarkCoreDataRepository(context: persistentStore.viewContext))
        
        let summary = rb.summary
            .setShowMoreDetails(true)
            .environment(\.managedObjectContext, persistentStore.viewContext)
            .environmentObject(repository)
            .environmentObject(bookmarkRepository)
        
        let controller = UIHostingController(rootView: summary)
        let window = TestHelpers.getKeyWindowVisible()
        window.rootViewController = controller
        tester().waitForView(withAccessibilityLabel: "\(rb.featureNumber) \(rb.volumeNumber!)")
        tester().waitForView(withAccessibilityLabel: "section")

        expectation(forNotification: .ViewDataSource,
                    object: nil) { notification in
            let vds = try! XCTUnwrap(notification.object as? ViewDataSource)
            let rb = try! XCTUnwrap(vds.dataSource as? RadioBeaconModel)
            XCTAssertEqual(rb.name, "Ittoqqortoormit, Scoresbysund")
            return true
        }
        tester().tapView(withAccessibilityLabel: "More Details")
        
        waitForExpectations(timeout: 10, handler: nil)
        tester().waitForAbsenceOfView(withAccessibilityLabel: "scope")
    }
    
    func testShowSectionHeader() {
        let rb = RadioBeacon(context: persistentStore.viewContext)
        
        rb.volumeNumber = "PUB 110"
        rb.aidType = "Radiobeacons"
        rb.geopoliticalHeading = "GREENLAND"
        rb.regionHeading = nil
        rb.precedingNote = nil
        rb.featureNumber = 10
        rb.name = "Ittoqqortoormit, Scoresbysund"
        rb.position = "70°29'11.99\"N \n21°58'20\"W"
        rb.characteristic = "SC\n(• • •  - • - • ).\n"
        rb.range = 200
        rb.sequenceText = nil
        rb.frequency = "343\nNON, A2A."
        rb.stationRemark = "Aeromarine."
        rb.postNote = nil
        rb.noticeNumber = 199706
        rb.removeFromList = "N"
        rb.deleteFlag = "N"
        rb.noticeWeek = "06"
        rb.noticeYear = "1997"
        rb.latitude = 1.0
        rb.longitude = 2.0
        rb.sectionHeader = "section"
        
        let repository = RadioBeaconRepositoryManager(repository: RadioBeaconCoreDataRepository(context: persistentStore.viewContext))
        let bookmarkRepository = BookmarkRepositoryManager(repository: BookmarkCoreDataRepository(context: persistentStore.viewContext))
        
        let summary = rb.summary
            .setShowSectionHeader(true)
            .environment(\.managedObjectContext, persistentStore.viewContext)
            .environmentObject(repository)
            .environmentObject(bookmarkRepository)
        
        let controller = UIHostingController(rootView: summary)
        let window = TestHelpers.getKeyWindowVisible()
        window.rootViewController = controller
        tester().waitForView(withAccessibilityLabel: "\(rb.featureNumber) \(rb.volumeNumber!)")
        tester().waitForView(withAccessibilityLabel: "section")
        tester().waitForAbsenceOfView(withAccessibilityLabel: "More Details")
        
        tester().waitForAbsenceOfView(withAccessibilityLabel: "scope")
    }
}
