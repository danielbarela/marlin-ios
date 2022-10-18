//
//  RadioBeaconMap.swift
//  Marlin
//
//  Created by Daniel Barela on 8/25/22.
//

import Foundation
import MapKit
import CoreData
import Combine

class RadioBeaconMap<T: RadioBeacon & MapImage>: FetchRequestMap<T> {
    override public init(fetchPredicate: NSPredicate? = nil, objects: [T]? = nil, showAsTiles: Bool = true) {
        super.init(fetchPredicate: fetchPredicate, showAsTiles: showAsTiles)
        self.showKeyPath = \MapState.showRadioBeacons
        self.sortDescriptors = [NSSortDescriptor(keyPath: \RadioBeacon.featureNumber, ascending: true)]
        self.focusNotificationName = .FocusRadioBeacon
        self.userDefaultsShowPublisher = UserDefaults.standard.publisher(for: \.showOnMapradioBeacon)
    }
    
    override func setupMixin(marlinMap: MarlinMap, mapView: MKMapView) {
        super.setupMixin(marlinMap: marlinMap, mapView: mapView)
        mapView.register(ImageAnnotationView.self, forAnnotationViewWithReuseIdentifier: RadioBeacon.key)
    }
}
