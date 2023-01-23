//
//  ModuSummaryTests.swift
//  MarlinTests
//
//  Created by Daniel Barela on 1/19/23.
//

import XCTest
import Combine
import SwiftUI

@testable import Marlin

final class ModuSummaryTests: XCTestCase {
    var cancellable = Set<AnyCancellable>()
    var persistentStore: PersistentStore = PersistenceController.shared
    let persistentStoreLoadedPub = NotificationCenter.default.publisher(for: .PersistentStoreLoaded)
        .receive(on: RunLoop.main)
    
    override func setUp(completion: @escaping (Error?) -> Void) {
        for item in DataSourceList().allTabs {
            UserDefaults.standard.initialDataLoaded = false
            UserDefaults.standard.clearLastSyncTimeSeconds(item.dataSource as! any BatchImportable.Type)
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
        let modu = Modu(context: persistentStore.viewContext)
        
        modu.name = "ABAN II"
        modu.date = Date(timeIntervalSince1970: 0)
        modu.rigStatus = "Active"
        modu.specialStatus = "Wide Berth Requested"
        modu.distance = 5
        modu.latitude = 1.0
        modu.longitude = 2.0
        modu.position = "16°20'30.6\"N \n81°55'27\"E"
        modu.navArea = "HYDROPAC"
        modu.region = 6
        modu.subregion = 63
        
        let summary = modu.summaryView(showMoreDetails: false)
        
        let controller = UIHostingController(rootView: summary)
        let window = TestHelpers.getKeyWindowVisible()
        window.rootViewController = controller
        tester().waitForView(withAccessibilityLabel: "Rig Status: Active")
        tester().waitForView(withAccessibilityLabel: "Special Status: Wide Berth Requested")
        tester().waitForView(withAccessibilityLabel: "ABAN II")
        tester().waitForView(withAccessibilityLabel: modu.dateString)
        
        expectation(forNotification: .SnackbarNotification,
                    object: nil) { notification in
            let model = try? XCTUnwrap(notification.object as? SnackbarNotification)
            XCTAssertEqual(model?.snackbarModel?.message, "Location 1° 00' 00\" N, 2° 00' 00\" E copied to clipboard")
            XCTAssertEqual(UIPasteboard.general.string, "1° 00' 00\" N, 2° 00' 00\" E")
            return true
        }
        tester().tapView(withAccessibilityLabel: "Location")
        
        expectation(forNotification: .MapRequestFocus,
                    object: nil) { notification in
            return true
        }
        
        expectation(forNotification: .MapItemsTapped, object: nil) { notification in
            
            let tapNotification = try! XCTUnwrap(notification.object as? MapItemsTappedNotification)
            let modu = tapNotification.items as! [Modu]
            XCTAssertEqual(modu.count, 1)
            XCTAssertEqual(modu[0].name, "ABAN II")
            return true
        }
        tester().tapView(withAccessibilityLabel: "focus")
        
        waitForExpectations(timeout: 10, handler: nil)
        
        tester().waitForView(withAccessibilityLabel: "share")
        tester().tapView(withAccessibilityLabel: "share")
        
        tester().waitForTappableView(withAccessibilityLabel: "Close")
        tester().tapView(withAccessibilityLabel: "Close")
    }
    
    func testShowMoreDetails() {
        let modu = Modu(context: persistentStore.viewContext)
        
        modu.name = "ABAN II"
        modu.date = Date(timeIntervalSince1970: 0)
        modu.rigStatus = "Active"
        modu.specialStatus = "Wide Berth Requested"
        modu.distance = 5
        modu.latitude = 1.0
        modu.longitude = 2.0
        modu.position = "16°20'30.6\"N \n81°55'27\"E"
        modu.navArea = "HYDROPAC"
        modu.region = 6
        modu.subregion = 63
        
        let summary = modu.summaryView(showMoreDetails: true)
        
        let controller = UIHostingController(rootView: summary)
        let window = TestHelpers.getKeyWindowVisible()
        window.rootViewController = controller
        tester().waitForView(withAccessibilityLabel: "Rig Status: Active")
        
        expectation(forNotification: .ViewDataSource,
                    object: nil) { notification in
            
            let modu = try! XCTUnwrap(notification.object as? Modu)
            XCTAssertEqual(modu.name, "ABAN II")
            return true
        }
        tester().tapView(withAccessibilityLabel: "More Details")
        
        waitForExpectations(timeout: 10, handler: nil)
        tester().waitForAbsenceOfView(withAccessibilityLabel: "scope")
    }
}