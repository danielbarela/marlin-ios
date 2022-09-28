//
//  DynamicListView.swift
//  Marlin
//
//  Created by Daniel Barela on 9/22/22.
//

import SwiftUI
import CoreData

struct MSIListView<T: NSManagedObject & DataSourceViewBuilder>: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    var sortDescriptors: [NSSortDescriptor] = []
    @State var filters: [DataSourceFilterParameter] = []
    @State var filterCount: Int = 0
    
    @ObservedObject var focusedItem: ItemWrapper
    @State var selection: String? = nil
    @State var filterOpen: Bool = false
    var userDefaultsShowPublisher: NSObject.KeyValueObservingPublisher<UserDefaults, Data?>
    
    var watchFocusedItem: Bool = false
    
    init(focusedItem: ItemWrapper, watchFocusedItem: Bool = false, sortDescriptors: [NSSortDescriptor], filterPublisher: NSObject.KeyValueObservingPublisher<UserDefaults, Data?>) {
        self.sortDescriptors = sortDescriptors
        self.focusedItem = focusedItem
        self.watchFocusedItem = watchFocusedItem
        self.userDefaultsShowPublisher = filterPublisher
    }
    
    var body: some View {
        ZStack {
            if watchFocusedItem, let focusedAsam = focusedItem.dataSource as? T {
                NavigationLink(tag: "detail", selection: $selection) {
                    focusedAsam.detailView
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
                    if watchFocusedItem, let _ = focusedItem.dataSource as? T {
                        selection = "detail"
                    }
                }
                
            }
            GenericList<T>(filters: filters, sortDescriptors: sortDescriptors)
            
        }
        .modifier(FilterButton(filterOpen: $filterOpen, dataSources: Binding.constant([DataSourceItem(dataSource: T.self)])))
        .bottomSheet(isPresented: $filterOpen, delegate: self) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    FilterView(dataSource: T.self)
                        .padding(.trailing, 16)
                        .background(Color.surfaceColor)
                    
                    Spacer()
                }
                
            }
            .navigationTitle("\(T.dataSourceName) Filters")
            .background(Color.backgroundColor)
        }
        .onReceive(userDefaultsShowPublisher) { output in
            guard let output = output else {
                return
            }
            do {
                // Create JSON Decoder
                let decoder = JSONDecoder()
                
                // Decode Note
                let filter = try decoder.decode([DataSourceFilterParameter].self, from: output)
                self.filters = filter
                self.filterCount = filters.count
            } catch {
                print("Unable to Decode Notes (\(error))")
            }
        }
    }
}

extension MSIListView: BottomSheetDelegate {
    func bottomSheetDidDismiss() {
        filterOpen.toggle()
    }
}

struct GenericList<T: NSManagedObject & DataSourceViewBuilder>: View {
    // That will store our fetch request, so that we can loop over it inside the body.
    // However, we don’t create the fetch request here, because we still don’t know what we’re searching for.
    // Instead, we’re going to create custom initializer(s) that accepts filtering information to set the fetchRequest property.
    @FetchRequest var fetchRequest: FetchedResults<T>
    
    var body: some View {
        List {
            ForEach(fetchRequest) { (asam: DataSourceViewBuilder) in
                //                        asam =  as! Asam
                ZStack {
                    NavigationLink(destination: asam.detailView
                    ) {
                        EmptyView()
                    }
                    .opacity(0)
                    
                    HStack {
                        asam.summaryView(showMoreDetails: false, showSectionHeader: false)
                    }
                    .padding(.all, 16)
                    .card()
                }
                
            }
            .dataSourceSummaryItem()
        }
        .navigationTitle(T.dataSourceName)
        .navigationBarTitleDisplayMode(.inline)
        .dataSourceSummaryList()
    }
    
    init(filters: [DataSourceFilterParameter], sortDescriptors: [NSSortDescriptor]) {
        var predicates: [NSPredicate] = []
        
        for filter in filters {
            if let predicate = filter.toPredicate() {
                predicates.append(predicate)
            }
        }
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        _fetchRequest = FetchRequest<T>(sortDescriptors: sortDescriptors, predicate: predicate)
    }
}
