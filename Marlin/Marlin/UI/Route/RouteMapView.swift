//
//  RouteMapView.swift
//  Marlin
//
//  Created by Daniel Barela on 8/21/23.
//

import SwiftUI
import MapKit
import Combine
import GeoJSON
import CoreData
import CoreLocation

class RouteMixin: MapMixin {
    var uuid: UUID = UUID()
    var mapState: MapState?
    var cancellable = Set<AnyCancellable>()
    
    var currentRoute: MKGeodesicPolyline?
    
    var viewModel: RouteViewModel
    
    init(viewModel: RouteViewModel) {
        self.viewModel = viewModel
    }
    
    func setupMixin(mapState: MapState, mapView: MKMapView) {
        self.mapState = mapState
        viewModel.$routeMKLine
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshLine()
            }
            .store(in: &cancellable)
    }
    
    func removeMixin(mapView: MKMapView, mapState: MapState) {
        
    }
    
    func refreshLine() {
        DispatchQueue.main.async {
            self.mapState?.mixinStates["\(String(describing: RouteMixin.self))DataUpdated"] = Date()
        }
    }
    
    func updateMixin(mapView: MKMapView, mapState: MapState) {
        if let currentRoute = self.currentRoute {
            print("remove current route")
            mapView.removeOverlay(currentRoute)
        }
        if let mkline = viewModel.routeMKLine {
            mapView.addOverlay(mkline)
            self.currentRoute = mkline
        }
    }
}

extension Notification.Name {
    public static let RouteMapTapped = Notification.Name("RouteMapTapped")
    public static let RouteFocus = Notification.Name("RouteFocus")
    public static let RouteMapLongPress = Notification.Name("RouteMapLongPress")
}

struct RouteMapView: View {
    @State var showBottomSheet: Bool = false
    @StateObject var itemList: BottomSheetItemList = BottomSheetItemList()
    
    @Binding var path: NavigationPath
    
    @ObservedObject var routeViewModel: RouteViewModel

    let focusMapAtLocation = NotificationCenter.default.publisher(for: .FocusMapAtLocation)

    @StateObject var mixins: MainMapMixins = MainMapMixins()
    @StateObject var mapState: MapState = MapState()
    
    let mapItemsTappedPub = NotificationCenter.default.publisher(for: .RouteMapTapped)
    let longPressPub = NotificationCenter.default.publisher(for: .RouteMapLongPress)
    
    var body: some View {
        VStack {
            MarlinMap(
                notificationOnTap: .RouteMapTapped,
                notificationOnLongPress: .RouteMapLongPress,
                focusNotification: .RouteFocus,
                name: "Marlin Map",
                mixins: mixins,
                mapState: mapState
            )
            .ignoresSafeArea()
        }
        .onAppear {
            mixins.mixins.append(RouteMixin(viewModel: routeViewModel))
        }
        .onReceive(focusMapAtLocation) { notification in
            mapState.forceCenter = notification.object as? MKCoordinateRegion
        }
        .overlay(bottomButtons(), alignment: .bottom)
        .overlay(topButtons(), alignment: .top)
        .onReceive(longPressPub) { output in
            guard let coordinate = output.object as? CLLocationCoordinate2D else {
                return
            }
            
            routeViewModel.addWaypoint(waypoint: CommonDataSource(name: "User Added Location", location: coordinate))
        }
        .onReceive(mapItemsTappedPub) { output in
            guard let notification = output.object as? MapItemsTappedNotification else {
                return
            }
            
            var bottomSheetItems: [BottomSheetItem] = []
            if let items = notification.items, !items.isEmpty {
                
                print("Route map items tapped")
                
                for item in items {
                    let bottomSheetItem = BottomSheetItem(item: item, mapName: "Route Map", zoom: false)
                    bottomSheetItems.append(bottomSheetItem)
                }
                itemList.bottomSheetItems = bottomSheetItems
                showBottomSheet.toggle()
            }

        }
        .sheet(
            isPresented: $showBottomSheet,
            onDismiss: {
                NSLog("dismissed")
                NotificationCenter.default.post(
                    name: .RouteFocus,
                    object: FocusMapOnItemNotification(item: nil)
                )
            },
            content: {
                MarlinBottomSheet(itemList: itemList, focusNotification: .RouteFocus) { dataSourceViewBuilder in
                    VStack {
                        Text(dataSourceViewBuilder.itemTitle)
                        HStack {
                            Button("Add To Route") {
                                print("add to route")
                                if let exportable = dataSourceViewBuilder as? any GeoJSONExportable {
                                    if let model = DataSourceType
                                        .fromKey(type(of: exportable).definition.key)?
                                        .createModel(dataSource: dataSourceViewBuilder) as? any GeoJSONExportable {
                                        routeViewModel.addWaypoint(waypoint: model)
                                        showBottomSheet.toggle()
                                    }
                                }
                            }
                            .buttonStyle(MaterialButtonStyle(type: .text))
                        }
                    }
                }
                .environmentObject(LocationManager.shared())
                .presentationDetents([.height(150)])
            }
        )
    }
    
    @ViewBuilder
    func topButtons() -> some View {
        HStack(alignment: .top, spacing: 8) {
            // top left button stack
            VStack(alignment: .leading, spacing: 8) {
                EmptyView()
            }
            .padding(.leading, 8)
            .padding(.top, 16)
            Spacer()
        }
    }
    
    @ViewBuilder
    func bottomButtons() -> some View {
        HStack(alignment: .bottom, spacing: 0) {
            DataSourceToggles()
                .padding(.leading, 8)
                .padding(.bottom, 30)
            
            Spacer()
                .frame(maxWidth: .infinity)
            
            // bottom right button stack
            VStack(alignment: .trailing, spacing: 16) {
                UserTrackingButton(mapState: mapState)
                    .fixedSize()
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("User Tracking")
            }
            .padding(.trailing, 8)
            .padding(.bottom, 30)
        }
    }
}
