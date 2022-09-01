//
//  ModuMap.swift
//  Marlin
//
//  Created by Daniel Barela on 6/17/22.
//

import Foundation
import MapKit
import CoreData
import Combine

class ModuMap: FetchRequestMap<Modu> {
    override public init(fetchRequest: NSFetchRequest<Modu>? = nil, showAsTiles: Bool = true) {
        super.init(fetchRequest: fetchRequest, showAsTiles: showAsTiles)
        self.showKeyPath = \MapState.showModus
        self.sortDescriptors = [NSSortDescriptor(keyPath: \Modu.date, ascending: true)]
        self.focusNotificationName = .FocusModu
        self.userDefaultsShowPublisher = UserDefaults.standard.publisher(for: \.showOnMapmodu)
    }
    
    override func setupMixin(marlinMap: MarlinMap, mapView: MKMapView) {
        super.setupMixin(marlinMap: marlinMap, mapView: mapView)
        mapView.register(ImageAnnotationView.self, forAnnotationViewWithReuseIdentifier: Modu.key)
    }
}
