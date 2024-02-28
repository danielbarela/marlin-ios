//
//  RadioBeaconList.swift
//  Marlin
//
//  Created by Daniel Barela on 2/7/24.
//

import Foundation
import SwiftUI

struct RadioBeaconList: View {
    @EnvironmentObject var radioBeaconRepository: RadioBeaconRepository
    @StateObject var viewModel: RadioBeaconsViewModel = RadioBeaconsViewModel()

    @EnvironmentObject var router: MarlinRouter

    @State var sortOpen: Bool = false
    @State var filterOpen: Bool = false
    @State var filterViewModel: FilterViewModel = PersistedFilterViewModel(
        dataSource: DataSources.filterableFromDefintion(DataSources.radioBeacon)
    )

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                VStack(alignment: .center, spacing: 16) {
                    HStack(alignment: .center, spacing: 0) {
                        Spacer()
                        Image("settings_input_antenna")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .padding([.trailing, .leading], 24)
                            .foregroundColor(Color.onSurfaceColor)
                        Spacer()
                    }
                    Text("Loading Radio Beacons")
                        .font(.headline)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.center)
                    ProgressView()
                        .tint(Color.primaryColorVariant)
                }
                .padding(24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.backgroundColor)
                .transition(AnyTransition.opacity)
            case let .loaded(rows: rows):
                ZStack(alignment: .bottomTrailing) {
                    List(rows) { radioBeaconItem in
                        switch radioBeaconItem {
                        case .listItem(let radioBeacon):
                            RadioBeaconSummaryView(radioBeacon: radioBeacon)
                                .showBookmarkNotes(true)
                                .paddedCard()
                                .onAppear {
                                    if rows.last == radioBeaconItem {
                                        viewModel.loadMore()
                                    }
                                }
                                .onTapGesture {
                                    if let featureNumber = radioBeacon.featureNumber,
                                       let volumeNumber = radioBeacon.volumeNumber {
                                        router.path.append(
                                            RadioBeaconRoute.detail(
                                                featureNumber: featureNumber,
                                                volumeNumber: volumeNumber
                                            )
                                        )
                                    }
                                }
                                .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.backgroundColor)
                        case .sectionHeader(let header):
                            Text(header)
                                .onAppear {
                                    if rows.last == radioBeaconItem {
                                        viewModel.loadMore()
                                    }
                                }
                                .sectionHeader()
                        }

                    }
                    .listStyle(.plain)
                    .listSectionSeparator(.hidden)
                    .refreshable {
                        viewModel.reload()
                    }
                }
                .emptyPlaceholder(rows) {
                    VStack(alignment: .center, spacing: 16) {
                        HStack(alignment: .center, spacing: 0) {
                            Spacer()
                            Image("settings_input_antenna")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity)
                                .padding([.trailing, .leading], 24)
                                .foregroundColor(Color.onSurfaceColor)
                            Spacer()
                        }
                        Text("No radio beacons match this filter")
                            .font(.headline)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.center)
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.backgroundColor)
                }
                .transition(AnyTransition.opacity)
            case let .failure(error: error):
                Text(error.localizedDescription)
            }
        }
        .navigationTitle(DataSources.radioBeacon.fullName)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.backgroundColor)
        .foregroundColor(Color.onSurfaceColor)
        .onChange(of: filterOpen) { filterOpen in
            if !filterOpen {
                viewModel.reload()
            }
        }
        .onChange(of: sortOpen) { sortOpen in
            if !sortOpen {
                viewModel.reload()
            }
        }
        .onAppear {
            viewModel.repository = radioBeaconRepository
            Metrics.shared.dataSourceList(dataSource: DataSources.radioBeacon)
        }
        .modifier(
            FilterButton(
                filterOpen: $filterOpen,
                sortOpen: $sortOpen,
                dataSources: Binding.constant([
                    DataSourceItem(dataSource: DataSources.radioBeacon)
                ]),
                allowSorting: true,
                allowFiltering: true)
        )
        .background {
            DataSourceFilter(filterViewModel: filterViewModel, showBottomSheet: $filterOpen)
        }
        .sheet(isPresented: $sortOpen) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        SortView(definition: DataSources.radioBeacon)
                            .background(Color.surfaceColor)

                        Spacer()
                    }

                }
                .navigationTitle("\(DataSources.radioBeacon.name) Sort")
                .navigationBarTitleDisplayMode(.inline)
                .background(Color.backgroundColor)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(
                            action: {
                                sortOpen.toggle()
                            },
                            label: {
                                Image(systemName: "xmark.circle.fill")
                                    .imageScale(.large)
                                    .foregroundColor(Color.onPrimaryColor.opacity(0.87))
                            }
                        )
                        .accessibilityElement()
                        .accessibilityLabel("Close Sort")
                    }
                }
                .presentationDetents([.large])
            }

            .onAppear {
                Metrics.shared.dataSourceSort(dataSource: DataSources.radioBeacon)
            }
        }
    }
}