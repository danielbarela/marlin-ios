//
//  ModuListView.swift
//  Marlin
//
//  Created by Daniel Barela on 6/17/22.
//

import SwiftUI

import CoreData

struct ModuListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var scheme: MarlinScheme
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Modu.date, ascending: false)],
        animation: .default)
    private var modus: FetchedResults<Modu>
    
    var body: some View {
        NavigationView {
            List {
                ForEach(modus) { modu in
                    
                    ZStack {
                        NavigationLink(destination: ModuDetailView(modu: modu)
                            .navigationTitle(modu.name ?? "MODU")
                            .navigationBarTitleDisplayMode(.inline)) {
                                EmptyView()
                            }
                            .opacity(0)
                        
                        HStack {
                            ModuSummaryView(modu: modu)
                        }
                        .padding(.all, 16)
                        .background(Color(scheme.containerScheme.colorScheme.surfaceColor))
                        .modifier(CardModifier())
                    }
                    
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
            }
            .navigationTitle("MODUs")
            .navigationBarTitleDisplayMode(.inline)
            .listStyle(.grouped)
        }
    }
}

struct ModuListView_Previews: PreviewProvider {
    static var previews: some View {
        ModuListView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}