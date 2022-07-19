//
//  NavigationalWarningListView.swift
//  Marlin
//
//  Created by Daniel Barela on 6/23/22.
//

import SwiftUI

struct NavigationalWarningListViewBackground: View {
    
    @State var color: Color
    
    var body: some View {
        HStack {
            Rectangle()
                .fill(color)
                .frame(maxWidth: 6, maxHeight: .infinity)
            Spacer()
        }.padding([.leading, .top, .bottom], -8)
    }
}

struct NavigationalWarningListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var scheme: MarlinScheme
    
    @StateObject var locationManager = LocationManager()

    var navareaMap = GeoPackageMap(fileName: "navigation_areas", tableName: "navigation_areas", index: 0)
    
    var body: some View {
        NavigationView {
            List {
                MarlinMap()
                    .mixin(navareaMap)
                    .mixin(GeoPackageMap(fileName: "natural_earth_1_100", tableName: "Natural Earth", polygonColor: scheme.dynamicLandColor, index: 1))
                    .frame(minHeight: 250, maxHeight: 250)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                NavigationalWarningAreasView(currentArea: locationManager.currentNavArea)
                    .listRowBackground(Color(scheme.containerScheme.colorScheme.surfaceColor))
                    .listRowInsets(EdgeInsets(top: 10, leading: 8, bottom: 8, trailing: 8))
            }
            .navigationTitle("Navigational Warnings")
            .navigationBarTitleDisplayMode(.inline)
            .listStyle(.grouped)
            .padding(.top, -36)
        }
    }
}

struct NavigationalWarningAreasView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var scheme: MarlinScheme
    
    @SectionedFetchRequest<String, NavigationalWarning>
    var currentNavigationalWarningsSections: SectionedFetchResults<String, NavigationalWarning>

    @SectionedFetchRequest<String, NavigationalWarning>
    var navigationalWarningsSections: SectionedFetchResults<String, NavigationalWarning>
    
    init(currentArea: NavigationalWarningNavArea?) {
        self._currentNavigationalWarningsSections = SectionedFetchRequest<String, NavigationalWarning>(entity: NavigationalWarning.entity(), sectionIdentifier: \NavigationalWarning.navArea!, sortDescriptors: [NSSortDescriptor(keyPath: \NavigationalWarning.navArea, ascending: false), NSSortDescriptor(keyPath: \NavigationalWarning.issueDate, ascending: false)], predicate: NSPredicate(format: "navArea = %@", currentArea?.name ?? ""))
    
        self._navigationalWarningsSections = SectionedFetchRequest<String, NavigationalWarning>(entity: NavigationalWarning.entity(), sectionIdentifier: \NavigationalWarning.navArea!, sortDescriptors: [NSSortDescriptor(keyPath: \NavigationalWarning.navArea, ascending: false), NSSortDescriptor(keyPath: \NavigationalWarning.issueDate, ascending: false)], predicate: NSPredicate(format: "navArea != %@", currentArea?.name ?? ""))
    }
    
    var body: some View {
        ForEach(currentNavigationalWarningsSections) { section in
            NavigationLink {
                NavigationalWarningNavAreaListView(warnings: Array<NavigationalWarning>(section), navArea: section.id)
                    .navigationTitle(NavigationalWarningNavArea.fromId(id: section.id)?.display ?? "Navigational Warnings")
            } label: {
                HStack {
                    VStack(alignment: .leading) {
                        Text(NavigationalWarningNavArea.fromId(id: section.id)?.display ?? "")
                            .font(Font(scheme.containerScheme.typographyScheme.body1))
                            .foregroundColor(Color(scheme.containerScheme.colorScheme.onSurfaceColor))
                            .opacity(0.87)
                        Text("\(section.count) Active")
                            .font(Font(scheme.containerScheme.typographyScheme.body2))
                            .foregroundColor(Color(scheme.containerScheme.colorScheme.onSurfaceColor))
                            .opacity(0.6)
                    }
                    Spacer()
                    NavigationalWarningAreaUnreadBadge(navArea: section.id, warnings: Array<NavigationalWarning>(section))
                }
            }
            .padding(.leading, 8)
            .padding(.top, 8)
            .padding(.bottom, 8)
            .background(NavigationalWarningListViewBackground(color: Color(NavigationalWarningNavArea.fromId(id: section.id)?.color ?? UIColor.clear)))
        }
        .listRowBackground(Color(scheme.containerScheme.colorScheme.surfaceColor))
        .listRowInsets(EdgeInsets(top: 10, leading: 8, bottom: 8, trailing: 8))
        
        ForEach(navigationalWarningsSections) { section in
            NavigationLink {
                NavigationalWarningNavAreaListView(warnings: Array<NavigationalWarning>(section), navArea: section.id)
                    .navigationTitle(NavigationalWarningNavArea.fromId(id: section.id)?.display ?? "Navigational Warnings")
            } label: {
                HStack {
                    VStack(alignment: .leading) {
                        Text(NavigationalWarningNavArea.fromId(id: section.id)?.display ?? "")
                            .font(Font(scheme.containerScheme.typographyScheme.body1))
                            .foregroundColor(Color(scheme.containerScheme.colorScheme.onSurfaceColor))
                            .opacity(0.87)
                        Text("\(section.count) Active")
                            .font(Font(scheme.containerScheme.typographyScheme.body2))
                            .foregroundColor(Color(scheme.containerScheme.colorScheme.onSurfaceColor))
                            .opacity(0.6)
                    }
                    Spacer()
                    NavigationalWarningAreaUnreadBadge(navArea: section.id, warnings: Array<NavigationalWarning>(section))
                }
            }
            .padding(.leading, 8)
            .padding(.top, 8)
            .padding(.bottom, 8)
            .background(NavigationalWarningListViewBackground(color: Color(NavigationalWarningNavArea.fromId(id: section.id)?.color ?? UIColor.clear)))
        }
        .listRowBackground(Color(scheme.containerScheme.colorScheme.surfaceColor))
        .listRowInsets(EdgeInsets(top: 10, leading: 8, bottom: 8, trailing: 8))
    }
}


struct NavigationalWarningListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationalWarningListView()
    }
}
