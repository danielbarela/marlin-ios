//
//  PortListView.swift
//  Marlin
//
//  Created by Daniel Barela on 8/17/22.
//

import SwiftUI

struct PortListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Port.portNumber, ascending: true)],
        animation: .default)
    private var ports: FetchedResults<Port>
    
    @ObservedObject var focusedItem: ItemWrapper
    @State var selection: String? = nil
    
    @State var sortedPorts: [Port] = []
    
    @EnvironmentObject var locationManager: LocationManager

    var watchFocusedItem: Bool = false
    
    var body: some View {
        ZStack {
            if watchFocusedItem, let focusedPort = focusedItem.dataSource as? Port {
                NavigationLink(tag: "detail", selection: $selection) {
                    PortDetailView(port: focusedPort)
                        .navigationTitle(focusedPort.portName ?? "Port")
                        .navigationBarTitleDisplayMode(.inline)
                } label: {
                    EmptyView().hidden()
                }
                
                .isDetailLink(false)
                .onAppear {
                    selection = "detail"
                }
                .onChange(of: focusedItem.date) { newValue in
                    if watchFocusedItem, let _ = focusedItem.dataSource as? Port {
                        selection = "detail"
                    }
                }
            }
            List {
                ForEach(sortedPorts) { port in
                    
                    ZStack {
                        NavigationLink(destination: PortDetailView(port: port)
                            .navigationTitle(port.portName ?? "Port")
                            .navigationBarTitleDisplayMode(.inline)) {
                                EmptyView()
                            }
                            .opacity(0)
                        
                        HStack {
                            PortSummaryView(port: port, currentLocation: locationManager.lastLocation, showMoreDetails: false)
                        }
                        .padding(.all, 16)
                        .background(Color.surfaceColor)
                        .modifier(CardModifier())
                    }
                    
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
            }
            .navigationTitle(Port.dataSourceName)
            .navigationBarTitleDisplayMode(.inline)
            .listStyle(.plain)
            .background(Color.backgroundColor)
            .onAppear {
                if let lastLocation = locationManager.lastLocation {
                    sortedPorts = ports.sorted { first, second in
                        return first.distanceTo(lastLocation) < second.distanceTo(lastLocation)
                    }
                }
            }
            .onChange(of: locationManager.lastLocation) { newValue in
                if sortedPorts.count == 0 {
                    if let lastLocation = locationManager.lastLocation {
                        sortedPorts = ports.sorted { first, second in
                            return first.distanceTo(lastLocation) < second.distanceTo(lastLocation)
                        }
                    }
                }
            }
        }
    }
}

struct PortListView_Previews: PreviewProvider {
    static var previews: some View {
        PortListView(focusedItem: ItemWrapper())
    }
}