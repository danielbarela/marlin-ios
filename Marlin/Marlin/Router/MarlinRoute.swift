//
//  MarlinRoute.swift
//  Marlin
//
//  Created by Daniel Barela on 6/30/23.
//

import Foundation
import SwiftUI
import CoreData

class MarlinRouter: ObservableObject {
    @Published var path: NavigationPath = NavigationPath()
}

enum MarlinRoute: Hashable {
    case exportGeoPackage(useMapRegion: Bool)
    case exportGeoPackageDataSource(dataSource: DataSourceDefinitions?, filters: [DataSourceFilterParameter]? = nil)
    case lightSettings
    case mapLayers
    case coordinateDisplaySettings
    case mapSettings
    case about
    case submitReport
    case disclaimer
    case acknowledgements
    case createRoute
    case editRoute(routeURI: URL?)
    case dataSourceDetail(dataSourceKey: String, itemKey: String)
    case dataSourceRouteDetail(dataSourceKey: String, itemKey: String, waypointURI: URL)
}

enum NoticeToMarinersRoute: Hashable {
    case notices
    case chartQuery
    case fullView(Int)
}

enum AsamRoute: Hashable {
    case detail(String)
}

enum ModuRoute: Hashable {
    case detail(String)
}

enum PortRoute: Hashable {
    case detail(Int64)
}

enum LightRoute: Hashable {
    case detail(String, String)
}

enum RadioBeaconRoute: Hashable {
    case detail(featureNumber: Int, volumeNumber: String)
}

enum DifferentialGPSStationRoute: Hashable {
    case detail(featureNumber: Int, volumeNumber: String)
}

enum NavigationalWarningRoute: Hashable {
    case detail(msgYear: Int, msgNumber: Int, navArea: String)
    case areaList(navArea: String)
}

enum ElectronicPublicationRoute: Hashable {
    case completeVolumes(typeId: Int)
    case nestedFolder(typeId: Int)
    case publicationList(key: String, pubs: [ElectronicPublicationModel])
    case completeAndChapters(typeId: Int, title: String, chapterTitle: String)
    case publications(typeId: Int)
}

enum DataSourceRoute: Hashable {
    case detail(dataSourceKey: String, itemKey: String)
}

extension View {
    func marlinRoutes() -> some View {
        modifier(MarlinRouteModifier())
    }
}

struct MarlinRouteModifier: ViewModifier {
    @EnvironmentObject var dataSourceList: DataSourceList
    
    func createExportDataSources() -> [DataSourceDefinitions] {
        var dataSources: [DataSourceDefinitions] = []
        
        for dataSource in dataSourceList.mappedDataSources {
            if let def = DataSourceDefinitions.from(dataSource.dataSource) {
                dataSources.append(def)
            }
        }
        return dataSources
    }
    
    // this is being refactored, ignore this error for now
    // swiftlint:disable cyclomatic_complexity function_body_length
    func body(content: Content) -> some View {
        content
            .navigationDestination(for: MarlinRoute.self) { item in
                switch item {
                case .exportGeoPackageDataSource(let dataSource, let filters):
                    GeoPackageExportView(
                        dataSources: dataSource != nil ? [dataSource!] : [],
                        filters: filters,
                        useMapRegion: false)
                case .exportGeoPackage(let useMapRegion):
                    GeoPackageExportView(dataSources: createExportDataSources(), useMapRegion: useMapRegion)
                case .lightSettings:
                    LightSettingsView()
                case .mapSettings:
                    MapSettings()
                case .mapLayers:
                    MapLayersView()
                case .coordinateDisplaySettings:
                    CoordinateDisplaySettings()
                case .about:
                    AboutView()
                case .submitReport:
                    SubmitReportView()
                case .disclaimer:
                    ScrollView {
                        DisclaimerView()
                    }
                case .acknowledgements:
                    AcknowledgementsView()
                case .createRoute:
                    CreateRouteView()
                case .editRoute(let routeURI):
                    CreateRouteView(routeURI: routeURI)
                case .dataSourceDetail(let dataSourceKey, let itemKey):
                    switch dataSourceKey {
                    case DataSources.asam.key:
                        AsamDetailView(reference: itemKey)
                    case DataSources.modu.key:
                        ModuDetailView(name: itemKey)
                    case DataSources.port.key:
                        PortDetailView(portNumber: Int64(itemKey))
                    case DataSources.navWarning.key:
                        let split = itemKey.split(separator: "--")
                        if split.count == 3 {
                            NavigationalWarningDetailView(
                                msgYear: Int(split[0]) ?? -1,
                                msgNumber: Int(split[1]) ?? -1,
                                navArea: "\(split[2])"
                            )
                        }
                    case DataSources.noticeToMariners.key:
                        if let noticeNumber = Int(itemKey) {
                            NoticeToMarinersFullNoticeView(noticeNumber: noticeNumber)
                        }
                    case DataSources.dgps.key:
                        let split = itemKey.split(separator: "--")
                        if split.count == 2 {
                            DifferentialGPSStationDetailView(featureNumber: Int(split[0]), volumeNumber: "\(split[1])")
                        }
                    case DataSources.light.key:
                        let split = itemKey.split(separator: "--")
                        if split.count == 3 {
                            LightDetailView(featureNumber: "\(split[0])", volumeNumber: "\(split[1])")
                        }
                    case DataSources.radioBeacon.key:
                        let split = itemKey.split(separator: "--")
                        if split.count == 2 {
                            RadioBeaconDetailView(featureNumber: Int(split[0]), volumeNumber: "\(split[1])")
                        }
                    case DataSources.epub.key:
                        Text("epub detail view")
//                        if let epub = ElectronicPublication.getItem(
//                            context: PersistenceController.current.viewContext,
//                            itemKey: itemKey) as? ElectronicPublication {
//                            ElectronicPublicationDetailView(electronicPublication: epub)
//                        }
                    case DataSources.geoPackage.key:
                        if let gpFeature = GeoPackageFeatureItem.getItem(
                            context: PersistenceController.current.viewContext,
                            itemKey: itemKey) as? GeoPackageFeatureItem {
                            GeoPackageFeatureItemDetailView(featureItem: gpFeature)
                        }
                    case DataSources.route.key:
                        CreateRouteView(routeURI: URL(string: itemKey))
                    default:
                        Text("no default")
                    }
                case .dataSourceRouteDetail(let dataSourceKey, let itemKey, let waypointURI):
                    switch dataSourceKey {
                    case DataSources.asam.key:
                        AsamDetailView(reference: itemKey, waypointURI: waypointURI)
                    case DataSources.modu.key:
                        ModuDetailView(name: itemKey, waypointURI: waypointURI)
                    case DataSources.light.key:
                        let split = itemKey.split(separator: "--")
                        if split.count == 3 {
                            LightDetailView(
                                featureNumber: "\(split[0])",
                                volumeNumber: "\(split[1])",
                                waypointURI: waypointURI)
                        }
                    case DataSources.port.key:
                        PortDetailView(portNumber: Int64(itemKey), waypointURI: waypointURI)
                    case DataSources.dgps.key:
                        let split = itemKey.split(separator: "--")
                        if split.count == 2 {
                            DifferentialGPSStationDetailView(
                                featureNumber: Int(split[0]),
                                volumeNumber: "\(split[1])",
                                waypointURI: waypointURI)
                        }
                    case DataSources.radioBeacon.key:
                        let split = itemKey.split(separator: "--")
                        if split.count == 2 {
                            RadioBeaconDetailView(
                                featureNumber: Int(split[0]),
                                volumeNumber: "\(split[1])",
                                waypointURI: waypointURI)
                        }
                    default:
                        Text("no default")
                    }
                }
            }
            .navigationDestination(for: AsamRoute.self) { item in
                switch item {
                case .detail(let reference):
                    // disable this rule in order to execute a statement prior to returning a view
                    // swiftlint:disable redundant_discardable_let
                    let _ = NotificationCenter.default.post(
                        name: .DismissBottomSheet,
                        object: nil,
                        userInfo: nil
                    )
                    // swiftlint:enable redundant_discardable_let

                    AsamDetailView(reference: reference)
                }
            }
            .navigationDestination(for: ModuRoute.self) { item in
                switch item {
                case .detail(let name):
                    // disable this rule in order to execute a statement prior to returning a view
                    // swiftlint:disable redundant_discardable_let
                    let _ = NotificationCenter.default.post(
                        name: .DismissBottomSheet,
                        object: nil,
                        userInfo: nil
                    )
                    // swiftlint:enable redundant_discardable_let

                    ModuDetailView(name: name)
                }
            }
            .navigationDestination(for: PortRoute.self) { item in
                switch item {
                case .detail(let portNumber):
                    // disable this rule in order to execute a statement prior to returning a view
                    // swiftlint:disable redundant_discardable_let
                    let _ = NotificationCenter.default.post(
                        name: .DismissBottomSheet,
                        object: nil,
                        userInfo: nil
                    )
                    // swiftlint:enable redundant_discardable_let

                    PortDetailView(portNumber: portNumber)
                }
            }
            .navigationDestination(for: LightRoute.self) { item in
                switch item {
                case .detail(let volumeNumber, let featureNumber):
                    // disable this rule in order to execute a statement prior to returning a view
                    // swiftlint:disable redundant_discardable_let
                    let _ = NotificationCenter.default.post(
                        name: .DismissBottomSheet,
                        object: nil,
                        userInfo: nil
                    )
                    // swiftlint:enable redundant_discardable_let

                    LightDetailView(featureNumber: featureNumber, volumeNumber: volumeNumber)
                }
            }
            .navigationDestination(for: RadioBeaconRoute.self) { item in
                switch item {
                case .detail(let featureNumber, let volumeNumber):
                    // disable this rule in order to execute a statement prior to returning a view
                    // swiftlint:disable redundant_discardable_let
                    let _ = NotificationCenter.default.post(
                        name: .DismissBottomSheet,
                        object: nil,
                        userInfo: nil
                    )
                    // swiftlint:enable redundant_discardable_let

                    RadioBeaconDetailView(featureNumber: featureNumber, volumeNumber: volumeNumber)
                }
            }
            .navigationDestination(for: DifferentialGPSStationRoute.self) { item in
                switch item {
                case .detail(let featureNumber, let volumeNumber):
                    // disable this rule in order to execute a statement prior to returning a view
                    // swiftlint:disable redundant_discardable_let
                    let _ = NotificationCenter.default.post(
                        name: .DismissBottomSheet,
                        object: nil,
                        userInfo: nil
                    )
                    // swiftlint:enable redundant_discardable_let

                    DifferentialGPSStationDetailView(featureNumber: featureNumber, volumeNumber: volumeNumber)
                }
            }
            .navigationDestination(for: NoticeToMarinersRoute.self) { item in
                switch item {
                case .fullView(let noticeNumber):
                    NoticeToMarinersFullNoticeView(noticeNumber: noticeNumber)
                case .notices:
                    NoticesList()
                case .chartQuery:
                    ChartCorrectionQuery()
                }
            }
            .navigationDestination(for: NavigationalWarningRoute.self) { item in
                switch item {
                case .detail(let msgYear, let msgNumber, let navArea):
                    // disable this rule in order to execute a statement prior to returning a view
                    // swiftlint:disable redundant_discardable_let
                    let _ = NotificationCenter.default.post(
                        name: .DismissBottomSheet,
                        object: nil,
                        userInfo: nil
                    )
                    // swiftlint:enable redundant_discardable_let
                    NavigationalWarningDetailView(msgYear: msgYear, msgNumber: msgNumber, navArea: navArea)
                case .areaList(let navArea):
                    NavigationalWarningNavAreaListView(
                        navArea: navArea,
                        mapName: "Navigational Warning List View Map"
                    )
                }
            }
            .navigationDestination(for: ElectronicPublicationRoute.self) { item in
                switch item {
                case .publications(typeId: let typeId):
                    ElectronicPublicationsTypeIdListView(pubTypeId: typeId)
                case .completeVolumes(typeId: let typeId):
                    ElectronicPublicationsCompleteVolumesList(pubTypeId: typeId)
                case .nestedFolder(typeId: let typeId):
                    ElectronicPublicationsNestedFolder(pubTypeId: typeId)
                case .publicationList(key: let key, pubs: let pubs):
                    ElectronicPublicationsListView(key: key, publications: pubs)
                case .completeAndChapters(typeId: let typeId, title: let title, chapterTitle: let chapterTitle):
                    ElectronicPublicationsChaptersList(pubTypeId: typeId, title: title, chapterTitle: chapterTitle)
                }
            }
            .navigationDestination(for: ItemWrapper.self) { item in
                if let dataSourceViewBuilder = item.dataSource as? (any DataSourceViewBuilder) {
                    dataSourceViewBuilder.detailView
                }
            }
    }
    // swiftlint:enable cyclomatic_complexity function_body_length
}
