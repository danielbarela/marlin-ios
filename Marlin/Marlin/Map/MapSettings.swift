//
//  MapSettings.swift
//  Marlin
//
//  Created by Daniel Barela on 6/30/22.
//

import SwiftUI
import MapKit

struct MapSettings: View {
    @EnvironmentObject var scheme: MarlinScheme

    @AppStorage("showMGRSGrid") var showMGRSGrid: Bool = false
    @AppStorage("showGARSGrid") var showGARSGrid: Bool = false
    @AppStorage("mapType") var mapType: Int = Int(MKMapType.standard.rawValue)
    var body: some View {
        List {
            Section("Map") {
                HStack(spacing: 4) {
                    Text("Standard").font(Font(scheme.containerScheme.typographyScheme.body1))
                        .foregroundColor(Color(scheme.containerScheme.colorScheme.onSurfaceColor.withAlphaComponent(0.87)))
                    Spacer()
                    Image(systemName: mapType == MKMapType.standard.rawValue ? "circle.inset.filled": "circle")
                        .foregroundColor(Color(scheme.containerScheme.colorScheme.primaryColor))
                        .onTapGesture {
                            mapType = Int(MKMapType.standard.rawValue)
                        }
                }
                .padding(.top, 4)
                .padding(.bottom, 4)
                HStack(spacing: 4) {
                    Text("Satellite").font(Font(scheme.containerScheme.typographyScheme.body1))
                        .foregroundColor(Color(scheme.containerScheme.colorScheme.onSurfaceColor.withAlphaComponent(0.87)))
                    Spacer()
                    Image(systemName: mapType == MKMapType.satellite.rawValue ? "circle.inset.filled": "circle")
                        .foregroundColor(Color(scheme.containerScheme.colorScheme.primaryColor))
                        .onTapGesture {
                            mapType = Int(MKMapType.satellite.rawValue)
                        }
                }
                .padding(.top, 4)
                .padding(.bottom, 4)
                HStack(spacing: 4) {
                    Text("Hybrid").font(Font(scheme.containerScheme.typographyScheme.body1))
                        .foregroundColor(Color(scheme.containerScheme.colorScheme.onSurfaceColor.withAlphaComponent(0.87)))
                    Spacer()
                    Image(systemName: mapType == MKMapType.hybrid.rawValue ? "circle.inset.filled": "circle")
                        .foregroundColor(Color(scheme.containerScheme.colorScheme.primaryColor))
                        .onTapGesture {
                            mapType = Int(MKMapType.hybrid.rawValue)
                        }
                }
                .padding(.top, 4)
                .padding(.bottom, 4)
                HStack(spacing: 4) {
                    Text("Satellite Flyover").font(Font(scheme.containerScheme.typographyScheme.body1))
                        .foregroundColor(Color(scheme.containerScheme.colorScheme.onSurfaceColor.withAlphaComponent(0.87)))
                    Spacer()
                    Image(systemName: mapType == MKMapType.satelliteFlyover.rawValue ? "circle.inset.filled": "circle")
                        .foregroundColor(Color(scheme.containerScheme.colorScheme.primaryColor))
                        .onTapGesture {
                            mapType = Int(MKMapType.satelliteFlyover.rawValue)
                        }
                }
                .padding(.top, 4)
                .padding(.bottom, 4)
                HStack(spacing: 4) {
                    Text("Hybrid Flyover").font(Font(scheme.containerScheme.typographyScheme.body1))
                        .foregroundColor(Color(scheme.containerScheme.colorScheme.onSurfaceColor.withAlphaComponent(0.87)))
                    Spacer()
                    Image(systemName: mapType == MKMapType.hybridFlyover.rawValue ? "circle.inset.filled": "circle")
                        .foregroundColor(Color(scheme.containerScheme.colorScheme.primaryColor))
                        .onTapGesture {
                            mapType = Int(MKMapType.hybridFlyover.rawValue)
                        }
                }
                .padding(.top, 4)
                .padding(.bottom, 4)
                HStack(spacing: 4) {
                    Text("Muted").font(Font(scheme.containerScheme.typographyScheme.body1))
                        .foregroundColor(Color(scheme.containerScheme.colorScheme.onSurfaceColor.withAlphaComponent(0.87)))
                    Spacer()
                    Image(systemName: mapType == MKMapType.mutedStandard.rawValue ? "circle.inset.filled": "circle")
                        .foregroundColor(Color(scheme.containerScheme.colorScheme.primaryColor))
                        .onTapGesture {
                            mapType = Int(MKMapType.mutedStandard.rawValue)
                        }
                }
                .padding(.top, 4)
                .padding(.bottom, 4)
                HStack(spacing: 4) {
                    Text("Open Street Map").font(Font(scheme.containerScheme.typographyScheme.body1))
                        .foregroundColor(Color(scheme.containerScheme.colorScheme.onSurfaceColor.withAlphaComponent(0.87)))
                    Spacer()
                    Image(systemName: mapType == ExtraMapTypes.osm.rawValue ? "circle.inset.filled": "circle")
                        .foregroundColor(Color(scheme.containerScheme.colorScheme.primaryColor))
                        .onTapGesture {
                            mapType = ExtraMapTypes.osm.rawValue
                        }
                }
                .padding(.top, 4)
                .padding(.bottom, 4)
            }
            Section("Grids (Coming soon)") {
                Toggle(isOn: $showMGRSGrid) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("MGRS").font(Font(scheme.containerScheme.typographyScheme.body1))
                            .foregroundColor(Color(scheme.containerScheme.colorScheme.onSurfaceColor.withAlphaComponent(0.87)))
                        Text("Military Grid Reference System")
                            .font(Font(scheme.containerScheme.typographyScheme.caption))
                            .foregroundColor(Color(scheme.containerScheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6)))
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 4)
                }
                .tint(Color(scheme.containerScheme.colorScheme.primaryColor))
                Toggle(isOn: $showGARSGrid) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("GARS").font(Font(scheme.containerScheme.typographyScheme.body1))
                            .foregroundColor(Color(scheme.containerScheme.colorScheme.onSurfaceColor.withAlphaComponent(0.87)))
                        Text("Global Area Reference System")
                            .font(Font(scheme.containerScheme.typographyScheme.caption))
                            .foregroundColor(Color(scheme.containerScheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6)))
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 4)
                }
                .tint(Color(scheme.containerScheme.colorScheme.primaryColor))
            }
        }
        .navigationTitle("Map Settings")
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(.grouped)
    }
}

struct MapSettings_Previews: PreviewProvider {
    static var previews: some View {
        MapSettings()
    }
}