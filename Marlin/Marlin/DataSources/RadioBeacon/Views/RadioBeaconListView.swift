//
//  RadioBeaconListView.swift
//  Marlin
//
//  Created by Daniel Barela on 8/25/22.
//

import SwiftUI

struct RadioBeaconListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @SectionedFetchRequest<String, RadioBeacon>(
        sectionIdentifier: \.geopoliticalHeading!,
        sortDescriptors: [NSSortDescriptor(keyPath: \RadioBeacon.geopoliticalHeading, ascending: true), NSSortDescriptor(keyPath: \RadioBeacon.featureNumber, ascending: true)]
    )
    var sectionedRadioBeacons: SectionedFetchResults<String, RadioBeacon>
    @ObservedObject var focusedItem: ItemWrapper
    @State var selection: String? = nil
    
    var watchFocusedItem: Bool = false
    
    var body: some View {
        ZStack {
            if watchFocusedItem, let focusedBeacon = focusedItem.dataSource as? RadioBeacon {
                NavigationLink(tag: "detail", selection: $selection) {
                    focusedBeacon.detailView
                        .navigationTitle("\(focusedBeacon.name ?? RadioBeacon.dataSourceName)" )
                        .navigationBarTitleDisplayMode(.inline)
                        .onDisappear {
                            focusedItem.dataSource = nil
                        }
                } label: {
                    EmptyView().hidden()
                }
                
                .isDetailLink(false)
                .onAppear {
                    selection = "detail"
                }
                .onChange(of: focusedItem.date) { newValue in
                    if watchFocusedItem, let _ = focusedItem.dataSource as? RadioBeacon {
                        selection = "detail"
                    }
                }
                
            }
            List(sectionedRadioBeacons) { section in
                
                Section(header: HStack {
                    Text(section.id)
                        .overline()
                }) {
                    
                    ForEach(section) { radioBeacon in
                        
                        ZStack {
                            NavigationLink(destination: radioBeacon.detailView
                                .navigationTitle("\(radioBeacon.name ?? RadioBeacon.dataSourceName)" )
                                .navigationBarTitleDisplayMode(.inline)) {
                                    EmptyView()
                                }
                                .opacity(0)
                            
                            HStack {
                                radioBeacon.summaryView()
                            }
                            .padding(.all, 16)
                            .card()
                        }
                        
                    }
                    .dataSourceSummaryItem()
                }
            }
            .navigationTitle(RadioBeacon.dataSourceName)
            .navigationBarTitleDisplayMode(.inline)
            .dataSourceSummaryList()
        }
    }
}

struct RadioBeaconListView_Previews: PreviewProvider {
    static var previews: some View {
        RadioBeaconListView(focusedItem: ItemWrapper())
    }
}
