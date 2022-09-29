//
//  AsamDetailView.swift
//  Marlin
//
//  Created by Daniel Barela on 6/15/22.
//

import SwiftUI
import MapKit
import CoreData

struct AsamDetailView: View {
    @StateObject var mapState: MapState = MapState()
    var fetchRequest: NSFetchRequest<Asam>

    var asam: Asam
    
    init(asam: Asam) {
        self.asam = asam
        let predicate = NSPredicate(format: "reference == %@", asam.reference ?? "")
        fetchRequest = Asam.fetchRequest()
        fetchRequest.predicate = predicate
    }
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    MarlinMap(name: "Asam Detail Map", mixins: [AsamMap(fetchPredicate: fetchRequest.predicate)], mapState: mapState)
                        .frame(maxWidth: .infinity, minHeight: 300, maxHeight: 300)
                        .onAppear {
                            mapState.center = MKCoordinateRegion(center: asam.coordinate, zoomLevel: 17.0, pixelWidth: 300.0)
                        }
                        .onChange(of: asam) { asam in
                            mapState.center = MKCoordinateRegion(center: asam.coordinate, zoomLevel: 17.0, pixelWidth: 300.0)
                        }
                    Group {
                        Text(asam.dateString ?? "")
                            .overline()
                        Text("\(asam.hostility ?? "")\(asam.hostility != nil ? ": " : "")\(asam.victim ?? "")")
                            .primary()
                        AsamActionBar(asam: asam)
                            .padding(.bottom, 16)
                    }.padding([.leading, .trailing], 16)
                }
                .card()
            } header: {
                EmptyView().frame(width: 0, height: 0, alignment: .leading)
            }
            .dataSourceSection()

            Section("Description") {
                Text(asam.asamDescription ?? "")
                    .secondary()
                    .frame(maxWidth:.infinity)
                    .padding(.all, 16)
                    .card()
            }
            .dataSourceSection()

            Section("Additional Information") {
                VStack(alignment: .leading, spacing: 8) {
                    if let hostility = asam.hostility {
                        Property(property: "Hostility", value: hostility)
                    }
                    if let victim = asam.victim {
                        Property(property: "Victim", value: victim)
                    }
                    if let reference = asam.reference {
                        Property(property: "Reference Number", value: reference)
                    }
                    if let dateString = asam.dateString {
                        Property(property: "Date of Occurence", value: dateString)
                    }
                    if let subregion = asam.subreg {
                        Property(property: "Geographical Subregion", value: subregion)
                    }
                    if let navarea = asam.navArea {
                        Property(property: "Navigational Area", value: navarea)
                    }
                }
                .padding(.all, 16)
                .card()
                .frame(maxWidth: .infinity)
            }
            .dataSourceSection()
        }
        .dataSourceDetailList()
        .navigationTitle(asam.reference ?? Asam.dataSourceName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AsamDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let asam = try? context.fetchFirst(Asam.self)
        return AsamDetailView(asam: asam!)
    }
}
