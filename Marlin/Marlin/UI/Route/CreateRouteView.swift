//
//  CreateRouteView.swift
//  Marlin
//
//  Created by Daniel Barela on 8/15/23.
//

import SwiftUI
import CoreLocation
import GeoJSON
import Combine

struct CreateRouteView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @EnvironmentObject var locationManager: LocationManager
    
    let maxFeatureAreaSize: CGFloat = 300
    @Binding var path: NavigationPath
    @State var routeURI: URL?
    
    @State private var waypointsFrameSize: CGSize = .zero
    @State private var firstWaypointFrameSize: CGSize = .zero
    @State private var lastWaypointFrameSize: CGSize = .zero
    @State private var instructionsFrameSize: CGSize = .zero
    @State private var distanceFrameSize: CGSize = .zero
    
    @StateObject var routeViewModel: RouteViewModel = RouteViewModel()
    enum Field: Hashable {
        case name
    }
    @FocusState private var focusedField: Field?

    private var tapGesture: some Gesture {
        (focusedField != nil) ? (TapGesture().onEnded { focusedField = nil }) : nil
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Route Name")
                    .overline()
                TextField("Route Name", text: $routeViewModel.routeName)
                    .focused($focusedField, equals: .name)
                    .keyboardType(.default)
                    .underlineTextFieldWithLabel()
                    .accessibilityElement()
                    .accessibilityLabel("Route Name input")
            }
            .padding([.leading, .trailing], 16)
            .padding(.top, 8)
            sizingOnlyStack()
                .frame(maxWidth: waypointsFrameSize.width, maxHeight: waypointsFrameSize.height)
                .overlay {
                    routeList()
                }
            RouteMapView(path: $path, routeViewModel: routeViewModel)
                .edgesIgnoringSafeArea([.leading, .trailing])
        }
        .gesture(tapGesture)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if routeViewModel.waypoints.count > 1 {
                    Button("Save") {
                        routeViewModel.createRoute(context: managedObjectContext)
                        path.removeLast()
                    }
                }
            }
        }
        .navigationTitle(Route.fullDataSourceName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let routeURI = routeURI {
                routeViewModel.routeURI = routeURI
            }
        }
    }
    
    @ViewBuilder
    func waypointRow(waypointViewBuilder: any DataSource, first: Bool = false, last: Bool = false) -> some View {
        HStack {
            Group {
                DataSourceCircleImage(dataSource: type(of: waypointViewBuilder), size: 12)
                HStack {
                    VStack(alignment: .leading) {
                        Text(waypointViewBuilder.itemTitle)
                            .font(Font.body2)
                            .foregroundColor(Color.onSurfaceColor)
                            .fixedSize(horizontal: false, vertical: true)
                        if let waypointLocation = waypointViewBuilder as? Locatable {
                            Text(waypointLocation.coordinate.format())
                                .overline()
                        }
                    }
                    Spacer()
                }
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
            }.padding([.top, .bottom], 8)
        }
        .background(HStack {
            let topPadding = first ? firstWaypointFrameSize.height / 2.0 : 0
            let bottomPadding = last ? lastWaypointFrameSize.height / 2.0 : 0
            Rectangle()
                .fill(Color.onSurfaceColor.opacity(0.45))
                .frame(maxWidth: 2, maxHeight: .infinity)
                .padding(.leading, 9)
                .padding(.top, topPadding)
                .padding(.bottom, bottomPadding)
            Spacer()
        })
    }

    @ViewBuilder
    func sizingWaypointRow(waypointViewBuilder: any DataSource, i: Range<Int>.Element) -> some View {
        waypointRow(waypointViewBuilder: waypointViewBuilder)
            .opacity(0)
            .overlay(
                GeometryReader { geo in
                    Color.clear.onAppear {
                        if i == routeViewModel.waypoints.indices.lowerBound {
                            firstWaypointFrameSize = CGSize(width: .infinity, height: geo.size.height)
                        }
                        if i == routeViewModel.waypoints.indices.upperBound.advanced(by: -1) {
                            lastWaypointFrameSize = CGSize(width: .infinity, height: geo.size.height)
                        }
                    }
                    .onChange(of: geo.size) { _ in
                        if i == routeViewModel.waypoints.indices.lowerBound {
                            firstWaypointFrameSize = CGSize(width: .infinity, height: geo.size.height)
                        }
                        if i == routeViewModel.waypoints.indices.upperBound.advanced(by: -1) {
                            lastWaypointFrameSize = CGSize(width: .infinity, height: geo.size.height)
                        }
                    }
                }
            )
    }

    @ViewBuilder
    func distance() -> some View {
        if let nauticalMilesDistance = routeViewModel.nauticalMilesDistance {
            Text("Total Distance: \(nauticalMilesDistance)")
                .font(Font.overline)
                .frame(maxWidth: .infinity, alignment: .center)
                .foregroundColor(Color.onSurfaceColor)
                .opacity(0.8)
                .listRowInsets(.init(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowSeparator(.hidden, edges: .bottom)
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    func sizingDistanceFor() -> some View {
        distance()
            .padding(.top, 16)
            .opacity(0)
            .overlay(
                GeometryReader { geo in
                    Color.clear.onAppear {
                        distanceFrameSize = CGSize(width: .infinity, height: geo.size.height)
                    }
                    .onChange(of: geo.size) { _ in
                        distanceFrameSize = CGSize(width: .infinity, height: geo.size.height)
                    }
                }
            )
    }

    @ViewBuilder
    func instructions() -> some View {
        Text("Select a feature to add to the route, long press to add custom point, drag to reorder")
            .font(Font.overline)
            .frame(maxWidth: .infinity, alignment: .center)
            .fixedSize(horizontal: false, vertical: true)
            .foregroundColor(Color.onSurfaceColor)
            .opacity(0.8)
            .listRowBackground(Color.clear)
            .listRowInsets(.init(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowSeparator(.hidden, edges: .bottom)
    }

    @ViewBuilder
    func sizingInstructions() -> some View {
        instructions()
            .padding(.top, 1)
            .padding(.bottom, 7)
            .opacity(0)
            .overlay(
                GeometryReader { geo in
                    Color.clear.onAppear {
                        instructionsFrameSize = CGSize(width: .infinity, height: geo.size.height)
                    }
                    .onChange(of: geo.size) { _ in
                        instructionsFrameSize = CGSize(width: .infinity, height: geo.size.height)
                    }
                }
            )
    }

    @ViewBuilder
    func routeList() -> some View {
        VStack {
            ScrollViewReader { (proxy: ScrollViewProxy) in
                List {
                    instructions()
                    ForEach(routeViewModel.waypoints.indices, id: \.self) { index in
                        let waypoint = routeViewModel.waypoints[index]
                        waypointRow(
                            waypointViewBuilder: waypoint,
                            first: index == 0,
                            last: index == (routeViewModel.waypoints.count - 1))
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                routeViewModel.removeWaypoint(waypoint: waypoint)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .accessibilityElement()
                            .accessibilityLabel("remove waypoint \(waypoint.uniqueId)")
                            .tint(Color.red)
                        }
                        .listRowInsets(.init(top: 0, leading: 20, bottom: 0, trailing: 0))
                        .listRowSeparator(.hidden, edges: .top)
                        .listRowSeparator(.visible, edges: .bottom)
                    }
                    .onMove { from, destination in
                        routeViewModel.reorder(fromOffsets: from, toOffset: destination)
                    }
                    distance()
                        .id("distance")
                }
                .onReceive(Just(routeViewModel.waypoints.count)) { _ in
                    proxy.scrollTo("distance", anchor: .bottom)
                }
                .listStyle(.plain)
                .padding(.top, 10)
                .padding(.leading, -4)
            }
        }
    }
    
    // this seems dumb, and it is.  This is used only for sizing because you 
    // cannot add swipe actions to anything
    // other than a list AND you can't get the content size of a list because,
    // of course you can't so we use this to create the right size, and set
    // the list as an overlay because the list will take up all the room
    // that it is given
    @ViewBuilder
    func sizingOnlyStack() -> some View {
        VStack(spacing: 0) {
            sizingInstructions()
            ForEach($routeViewModel.waypoints.indices, id: \.self) { i in
                let waypointViewBuilder = routeViewModel.waypoints[i]
                sizingWaypointRow(waypointViewBuilder: waypointViewBuilder, i: i)
            }
            sizingDistanceFor()

        }
        .padding(16)
        
        .overlay(
            GeometryReader { geo in
                Color.clear.onAppear {
                    waypointsFrameSize = CGSize(width: .infinity, height: min(geo.size.height, maxFeatureAreaSize))
                }
                .onChange(of: geo.size) { _ in
                    waypointsFrameSize = CGSize(width: .infinity, height: min(geo.size.height, maxFeatureAreaSize))
                }
            }
        )
    }
}
