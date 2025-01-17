//
//  RouteList.swift
//  Marlin
//
//  Created by Daniel Barela on 8/14/23.
//

import SwiftUI

struct RouteSummaryView: DataSourceSummaryView {
    var showBookmarkNotes: Bool = false
    
    var showMoreDetails: Bool = false
    
    var showTitle: Bool = false
    
    var showSectionHeader: Bool = false
    
    var route: RouteModel
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text("\(route.name ?? "")")
                        .primary()
                    Text("Created \(route.createdTime?.formatted() ?? "")")
                        .overline()
                    HStack {
                        if let first = route.waypointArray.first {
                            if let dataSourceKey = first.dataSource, 
                                let type = DataSourceType.fromKey(dataSourceKey)?.toDataSource() {
                                DataSourceCircleImage(dataSource: type, size: 15)
                            }
                            if let dataSource = first.decodeToDataSource() {
                                Text(dataSource.itemTitle)
                                    .font(Font.overline)
                                    .foregroundColor(Color.onSurfaceColor)
                                    .opacity(0.8)
                            }
                        }
                        Image(systemName: "ellipsis")
                        if let last = route.waypointArray.last {
                            Group {
                                if let dataSourceKey = last.dataSource, 
                                    let type = DataSourceType.fromKey(dataSourceKey)?.toDataSource() {
                                    DataSourceCircleImage(dataSource: type, size: 15)
                                }
                                if let dataSource = last.decodeToDataSource() {
                                    Text(dataSource.itemTitle)
                                        .font(Font.overline)
                                        .foregroundColor(Color.onSurfaceColor)
                                        .opacity(0.8)
                                }
                            }
                            
                        }
                    }
                    if let distance = route.nauticalMilesDistance {
                        Text("Total Distance: \(distance)")
                            .overline()
                    }
                }
                Spacer()
            }
            DataSourceActionBar(data: route, showMoreDetailsButton: showMoreDetails, showFocusButton: false)
        }
    }
}

struct RouteList: View {
    @EnvironmentObject var routeRepository: RouteRepositoryManager
    @StateObject var viewModel: RoutesViewModel = RoutesViewModel()
    
    @Binding var path: NavigationPath
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            List(viewModel.routes) { route in
                RouteSummaryView(route: route)
                .contentShape(Rectangle())
                .onTapGesture {
                    path.append(MarlinRoute.editRoute(routeURI: route.routeURL))
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        print("delete")
                        viewModel.deleteRoute(route: route.routeURL)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .accessibilityElement()
                    .accessibilityLabel("remove route \(route.name ?? "")")
                    .tint(Color.red)
                }
            }
            CreateRouteButton()
        }
        .emptyPlaceholder(viewModel.routes) {
            Group {
                if viewModel.loaded {
                    RouteListEmptyState()
                } else {
                    RouteListLoadingState()
                }
            }
        }
        .navigationTitle(Route.fullDataSourceName)
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(.grouped)
        .listRowBackground(Color.surfaceColor)
        .background(Color.backgroundColor)
        .foregroundColor(Color.onSurfaceColor)
        .onAppear {
            viewModel.repository = routeRepository
            viewModel.fetchRoutes()
            Metrics.shared.dataSourceList(dataSource: Route.definition)
        }
    }
}
