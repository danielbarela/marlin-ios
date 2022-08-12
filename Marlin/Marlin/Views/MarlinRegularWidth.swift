//
//  MarlinRegularWidth.swift
//  Marlin
//
//  Created by Daniel Barela on 8/5/22.
//

import SwiftUI

struct MarlinRegularWidth: View {
    @State var activeRailItem: DataSourceItem? = nil
    
    @ObservedObject var dataSourceList: DataSourceList
    
    var marlinMap: MarlinMap
    
    var body: some View {
        HStack(spacing: 0) {
            DataSourceRail(dataSourceList: dataSourceList, activeRailItem: $activeRailItem)
                .frame(minWidth: 72, idealWidth: 72, maxWidth: 72)
                .onAppear {
                    activeRailItem = dataSourceList.tabs[0]
                }
                .background(Color.surfaceColor)
                .padding(.horizontal, 2)
            
            if let activeRailItem = activeRailItem {
                NavigationView {
                    createListView(dataSource: activeRailItem)
                }
                .navigationViewStyle(.stack)
                .frame(width: 256)
                .background(Color.backgroundColor)
            }
            
            NavigationView {
                ZStack(alignment: .topLeading) {
                    marlinMap
                    
                        .ignoresSafeArea()
                    VStack {
                        // top of map
                        HStack(alignment: .top, spacing: 0) {
                            Spacer()
                            // top right button stack
                            VStack(alignment: .trailing, spacing: 16) {
                                NavigationLink {
                                    MapSettings()
                                } label: {
                                    Label(
                                        title: {},
                                        icon: { Image(systemName: "square.3.stack.3d")
                                                .renderingMode(.template)
                                        }
                                    )
                                }
                                .isDetailLink(false)
                                .offset(x: -8, y: 16)
                                .fixedSize()
                                .buttonStyle(MaterialFloatingButtonStyle(type: .secondary, size: .mini))
                            }
                        }
                        Spacer()
                        // bottom of map
                        HStack(alignment: .bottom, spacing: 0) {
                            Spacer()
                            // bottom right button stack
                            VStack(alignment: .trailing, spacing: 16) {
                                UserTrackingButton(mapView: marlinMap.mutatingWrapper.mapView)
                                    .offset(x: -8, y: -24)
                                    .fixedSize()
                            }
                        }
                    }
                }
                .navigationBarHidden(true)
            }.navigationViewStyle(.stack)
        }
    }
    
    @ViewBuilder
    func createListView(dataSource: DataSourceItem) -> some View {
        if dataSource.key == Asam.key {
            AsamListView()
        } else if dataSource.key == Modu.key {
            ModuListView()
        } else if dataSource.key == Light.key {
            LightsListView()
        } else if dataSource.key == NavigationalWarning.key {
            NavigationalWarningListView()
        }
    }
}