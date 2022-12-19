//
//  MSI.swift
//  Marlin
//
//  Created by Daniel Barela on 6/3/22.
//

import Foundation
import Alamofire
import OSLog
import CoreData
import Combine

public class MSI {
    
    let logger = Logger(subsystem: "mil.nga.msi.Marlin", category: "persistence")
    
    var cancellable = Set<AnyCancellable>()
    
    static let shared = MSI()
    let appState = AppState()
    lazy var configuration: URLSessionConfiguration = URLSessionConfiguration.af.default
    var manager = ServerTrustManager(evaluators: ["msi.gs.mil": DisabledTrustEvaluator()
                                                           , "msi.om.east.paas.nga.mil": DisabledTrustEvaluator()])
    lazy var session: Session = {
        
        configuration.httpMaximumConnectionsPerHost = 4
        configuration.timeoutIntervalForRequest = 120
        
        return Session(configuration: configuration, serverTrustManager: manager)
    }()
    
    let masterDataList: [any BatchImportable.Type] = [Asam.self, Modu.self, NavigationalWarning.self, Light.self, Port.self, RadioBeacon.self, DifferentialGPSStation.self, DFRS.self, DFRSArea.self, ElectronicPublication.self, NoticeToMariners.self]
    
    init() {
        NotificationCenter.default.publisher(for: .DataSourceUpdated)
            .receive(on: RunLoop.main)
            .compactMap {
                $0.object as? String
            }
            .sink { item in
                let dataSource = self.masterDataList.first { type in
                    item == type.key
                }
                
                dataSource?.postProcess()
            }
            .store(in: &cancellable)
    }
    
    func loadAllData() {
        NSLog("Load all data")

        var initialDataLoadList: [any BatchImportable.Type] = []
        // if we think we need to load the initial data
//        if !UserDefaults.standard.initialDataLoaded {
            initialDataLoadList = masterDataList.filter { importable in
                if let ds = importable as? any DataSource.Type {
                    return UserDefaults.standard.dataSourceEnabled(ds) && !isLoaded(type: importable) && !(importable.seedDataFiles ?? []).isEmpty
                }
                return false
            }
//        }

        if !initialDataLoadList.isEmpty {
            NSLog("Loading initial data from \(initialDataLoadList.count) data sources")
            PersistenceController.current.addViewContextObserver(self, selector: #selector(managedObjectContextObjectChangedObserver(notification:)), name: .NSManagedObjectContextObjectsDidChange)

            DispatchQueue.main.async {
                for importable in initialDataLoadList {
                    self.appState.loadingDataSource[importable.key] = true
                }
                let queue = DispatchQueue(label: "mil.nga.msi.Marlin.api", qos: .background)
                queue.async( execute:{
                    for importable in initialDataLoadList {
                        self.loadInitialData(type: importable.decodableRoot, dataType: importable)
                    }
                })
            }
        } else {
            UserDefaults.standard.initialDataLoaded = true

            let allLoadList: [any BatchImportable.Type] = masterDataList.filter { importable in
                let sync = importable.shouldSync()
                return sync
            }

            NSLog("Fetching new data from the API for \(allLoadList.count) data sources")
            for importable in allLoadList {
                NSLog("Fetching new data for \(importable.key)")
                self.loadData(type: importable.decodableRoot, dataType: importable)
            }
        }
    }
    
    actor Counter {
        var value = 0
        var total = 0
        
        func addToTotal(count: Int) -> Int {
            total += count
            return total
        }

        func increment() -> Int {
            value += 1
            return value
        }
        
        func increase() -> Int {
            return self.increment()
        }
    }
    
    @objc func managedObjectContextObjectChangedObserver(notification: Notification) {
        guard let userInfo = notification.userInfo else { return }

        if let inserts = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>, inserts.count > 0 {
            if let dataSourceItem = inserts.first as? (any DataSource) {
                var allLoaded = true
                for (dataSource, loading) in self.appState.loadingDataSource {
                    if loading && type(of: dataSourceItem).key != dataSource {
                        allLoaded = false
                    }
                }
                if allLoaded {
                    PersistenceController.current.removeViewContextObserver(self, name: .NSManagedObjectContextObjectsDidChange)
                }
                DispatchQueue.main.async {
                    self.appState.loadingDataSource[type(of: dataSourceItem).key] = false
                    
                    if allLoaded {
                        UserDefaults.standard.initialDataLoaded = true
                        self.loadAllData()
                    }
                }
            }
        }
    }
    
    var loadCounters: [String: Counter] = [:]
    
    func loadInitialData<T: Decodable, D: NSManagedObject & BatchImportable>(type: T.Type, dataType: D.Type) {
        DispatchQueue.main.async {
            self.appState.loadingDataSource[D.key] = true
            if let dataSource = dataType as? any DataSource.Type {
                NotificationCenter.default.post(name: .DataSourceLoading, object: DataSourceItem(dataSource: dataSource))
            }
        }
        let queue = DispatchQueue(label: "mil.nga.msi.Marlin.api", qos: .background)
        
        if let seedDataFiles = D.seedDataFiles {
            NSLog("Loading initial data for \(D.key)")
            for seedDataFile in seedDataFiles {
                if let localUrl = Bundle.main.url(forResource: seedDataFile, withExtension: "json") {
                    session.request(localUrl, method: .get, parameters: nil, encoding: URLEncoding.default, headers: nil, interceptor: nil, requestModifier: .none)
                        .responseDecodable(of: T.self, queue: queue) { response in
                            queue.async( execute:{
                                Task.detached {
                                    try await D.batchImport(value: response.value, initialLoad: true)
                                    DispatchQueue.main.async {
                                        self.appState.loadingDataSource[D.key] = false
                                        if let dataSource = dataType as? any DataSource.Type {
                                            NotificationCenter.default.post(name: .DataSourceLoaded, object: DataSourceItem(dataSource: dataSource))
                                            NotificationCenter.default.post(name: .DataSourceUpdated, object: dataSource.key)
                                        }
                                    }
                                }
                            })
                        }
                }
            }
            return
        }
    }
    
    func loadData<T: Decodable, D: NSManagedObject & BatchImportable>(type: T.Type, dataType: D.Type) {
        DispatchQueue.main.async {
            self.appState.loadingDataSource[D.key] = true
            if let dataSource = dataType as? any DataSource.Type {
                NotificationCenter.default.post(name: .DataSourceLoading, object: DataSourceItem(dataSource: dataSource))
            }
        }
        let queue = DispatchQueue(label: "mil.nga.msi.Marlin.api", qos: .background)

        let queryCounter = Counter()
        let requests = D.dataRequest()

        for request in requests {
            session.request(request)
                .validate()
                .responseDecodable(of: T.self, queue: queue) { response in
                    queue.async(execute:{
                        Task.detached {
                            let count = try await D.batchImport(value: response.value, initialLoad: false)
                            
                            if count != -1 {
                                let sum = await queryCounter.increment()
                                let totalCount = await queryCounter.addToTotal(count: count)
                                NSLog("Queried for \(sum) of \(requests.count) for \(dataType.key)")
                                if sum == requests.count {
                                    DispatchQueue.main.async {
                                        self.appState.loadingDataSource[D.key] = false
                                        UserDefaults.standard.updateLastSyncTimeSeconds(D.self)
                                        if let dataSource = dataType as? any DataSource.Type {
                                            NotificationCenter.default.post(name: .DataSourceLoaded, object: DataSourceItem(dataSource: dataSource))
                                            if totalCount != 0 {
                                                NotificationCenter.default.post(name: .DataSourceUpdated, object: dataSource.key)
                                                let center = UNUserNotificationCenter.current()
                                                let content = UNMutableNotificationContent()
                                                content.title = NSString.localizedUserNotificationString(forKey: "New \(dataSource.fullDataSourceName) Data", arguments: nil)
                                                content.body = NSString.localizedUserNotificationString(forKey: "\(totalCount) new \(dataSource.fullDataSourceName) records were added or updated.", arguments: nil)
                                                content.sound = UNNotificationSound.default
                                                content.categoryIdentifier = "mil.nga.msi"
                                                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2.0, repeats: false)
                                                let request = UNNotificationRequest.init(identifier: "new\(dataSource.key)Data", content: content, trigger: trigger)
                                                
                                                // Schedule the notification.
                                                center.add(request)
                                            }
                                        }
                                    }
                                }
                            } else {
                                // need to requery
                                print("Requerying")
                                if let requeryRequest = D.getRequeryRequest(initialRequest: request) {
                                    self.session.request(requeryRequest)
                                        .validate()
                                        .responseDecodable(of: T.self, queue: queue) { response in
                                            queue.async(execute:{
                                                Task.detached {
                                                    let count = try await D.batchImport(value: response.value, initialLoad: true)
                                                    let sum = await queryCounter.increment()
                                                    let totalCount = await queryCounter.addToTotal(count: count)
                                                    NSLog("Queried for \(sum) of \(requests.count) for \(dataType.key)")
                                                    if sum == requests.count {
                                                        DispatchQueue.main.async {
                                                            self.appState.loadingDataSource[D.key] = false
                                                            UserDefaults.standard.updateLastSyncTimeSeconds(D.self)
                                                            if let dataSource = dataType as? any DataSource.Type {
                                                                NotificationCenter.default.post(name: .DataSourceLoaded, object: DataSourceItem(dataSource: dataSource))
                                                                if totalCount != 0 {
                                                                    NotificationCenter.default.post(name: .DataSourceUpdated, object: dataSource.key)
                                                                    let center = UNUserNotificationCenter.current()
                                                                    let content = UNMutableNotificationContent()
                                                                    content.title = NSString.localizedUserNotificationString(forKey: "New \(dataSource.fullDataSourceName) Data", arguments: nil)
                                                                    content.body = NSString.localizedUserNotificationString(forKey: "\(totalCount) new \(dataSource.fullDataSourceName) records were added or updated.", arguments: nil)
                                                                    content.sound = UNNotificationSound.default
                                                                    content.categoryIdentifier = "mil.nga.msi"
                                                                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2.0, repeats: false)
                                                                    let request = UNNotificationRequest.init(identifier: "new\(dataSource.key)Data", content: content, trigger: trigger)
                                                                    
                                                                    // Schedule the notification.
                                                                    center.add(request)
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            })
                                        }
                                }
                            }
                        }
                    })
                }
        }
    }
    
    func isLoaded<D: BatchImportable>(type: D.Type) -> Bool {
        let count = try? PersistenceController.current.countOfObjects(D.self)
        return (count ?? 0) > 0
    }
}

