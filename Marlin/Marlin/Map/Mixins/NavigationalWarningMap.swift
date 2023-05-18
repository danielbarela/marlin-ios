//
//  NavigationWarningMap.swift
//  Marlin
//
//  Created by Daniel Barela on 5/1/23.
//

import Foundation
import MapKit
import CoreData
import Combine
import sf_wkt_ios

class NavigationalWarningPolygon: MKPolygon {
    var warning: NavigationalWarning?
}

class NavigationalWarningPolyline: MKPolyline {
    var warning: NavigationalWarning?
}

class NavigationalWarningAnnotation: MKPointAnnotation {
    var warning: NavigationalWarning?
}

class NavigationalWarningCircle: MKCircle {
    var warning: NavigationalWarning?
}

class NavigationalWarningMap: NSObject, MapMixin {
    var warning: NavigationalWarning?
    var mapState: MapState?
    var lastChange: Date?
    var mapOverlays: [MKOverlay] = []
    var mapAnnotations: [MKAnnotation] = []
    var userDefaultsShowPublisher: NSObject.KeyValueObservingPublisher<UserDefaults, Bool>?
    var show: Bool = true
    var cancellable = Set<AnyCancellable>()
    var zoomOnFocus: Bool = false
    var setup: Bool = false
    
    static let MIXIN_STATE_KEY = "FetchRequestMixin\(NavigationalWarning.key)DateUpdated"
    
    init(zoomOnFocus: Bool = false) {
        super.init()
        self.zoomOnFocus = zoomOnFocus
    }
    
    init(warning: NavigationalWarning, zoomOnFocus: Bool = false) {
        super.init()
        self.warning = warning
        self.zoomOnFocus = zoomOnFocus
    }
    
    func setupMixin(marlinMap: MarlinMap, mapView: MKMapView) {
        mapView.register(MKAnnotationView.self, forAnnotationViewWithReuseIdentifier: NavigationalWarning.key)
        mapState = marlinMap.mapState
        if warning != nil {
            setupSingleNavigationalWarning(mapView: mapView)
        }

        NotificationCenter.default.publisher(for: .DataSourceUpdated)
            .receive(on: RunLoop.main)
            .compactMap {
                $0.object as? DataSourceUpdatedNotification
            }
            .sink { item in
                if item.key == NavigationalWarning.key {
                    self.refresh()
                }
            }
            .store(in: &cancellable)

        userDefaultsShowPublisher?
            .removeDuplicates()
            .handleEvents(receiveOutput: { show in
                print("Show \(NavigationalWarning.self): \(show)")
            })
            .sink() { [weak self] show in
                self?.show = show
                self?.refresh()
            }
            .store(in: &cancellable)
    }
    
    func addWarning(warning: NavigationalWarning, location: [String : String]) {
        if let wkt = location["wkt"] {
            var distance: Double?
            if let distanceString = location["distance"] {
                distance = Double(distanceString)
            }
            if let shape = MKShape.fromWKT(wkt: wkt, distance: distance) {
                if let polygon = shape as? MKPolygon {
                    let navPoly = NavigationalWarningPolygon(points: polygon.points(), count: polygon.pointCount)
                    navPoly.warning = warning
                    mapOverlays.append(navPoly)
                } else if let polyline = shape as? MKPolyline {
                    let navline = NavigationalWarningPolyline(points: polyline.points(), count: polyline.pointCount)
                    navline.warning = warning
                    mapOverlays.append(navline)
                } else if let point = shape as? MKPointAnnotation {
                    let navpoint = NavigationalWarningAnnotation()
                    navpoint.coordinate = point.coordinate
                    navpoint.warning = warning
                    mapAnnotations.append(navpoint)
                } else if let circle = shape as? MKCircle {
                    let navcircle = NavigationalWarningCircle(center: circle.coordinate, radius: circle.radius)
                    navcircle.warning = warning
                    mapOverlays.append(navcircle)
                }
            }
        }
    }
    
    func setupSingleNavigationalWarning(mapView: MKMapView) {
        if let warning = warning, let locations = warning.locations {
            for location in locations {
                addWarning(warning: warning, location: location)
            }
        }
        
        mapView.addOverlays(mapOverlays)
        mapView.addAnnotations(mapAnnotations)
    }
    
    func updateMixin(mapView: MKMapView, mapState: MapState) {
        if warning == nil && (lastChange == nil || (lastChange != mapState.mixinStates[NavigationalWarningMap.MIXIN_STATE_KEY] as? Date && mapState.mixinStates[NavigationalWarningMap.MIXIN_STATE_KEY] != nil)) {
            lastChange = mapState.mixinStates[NavigationalWarningMap.MIXIN_STATE_KEY] as? Date ?? Date()
            
            if mapState.mixinStates[NavigationalWarningMap.MIXIN_STATE_KEY] as? Date == nil {
                DispatchQueue.main.async {
                    mapState.mixinStates[NavigationalWarningMap.MIXIN_STATE_KEY] = self.lastChange
                }
            }
            
            mapView.removeOverlays(mapOverlays)
            mapView.removeAnnotations(mapAnnotations)
            
            let newFetchRequest = self.getFetchRequest(show: self.show)
            let context = PersistenceController.current.newTaskContext()
            context.performAndWait {
                if let objects = try? context.fetch(newFetchRequest) {
                    
                    for warning in objects {
                        if let locations = warning.locations {
                            for location in locations {
                                addWarning(warning: warning, location: location)
                            }
                        }
                    }
                }
            }
            mapView.addOverlays(self.mapOverlays)
            mapView.addAnnotations(self.mapAnnotations)
        }
    }
    
    func refresh() {
        DispatchQueue.main.async {
            self.mapState?.mixinStates[NavigationalWarningMap.MIXIN_STATE_KEY] = Date()
        }
    }
    
    func getFetchRequest(show: Bool) -> NSFetchRequest<NavigationalWarning> {
        let fetchRequest: NSFetchRequest<NavigationalWarning> = NavigationalWarning.fetchRequest()
        fetchRequest.sortDescriptors = NavigationalWarning.defaultSort.map({ parameter in
            parameter.toNSSortDescriptor()
        })
        var filterPredicates: [NSPredicate] = []
        if !show == true {
            filterPredicates.append(NSPredicate(value: false))
        }
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: filterPredicates)
        return fetchRequest
    }
    
    func viewForAnnotation(annotation: MKAnnotation, mapView: MKMapView) -> MKAnnotationView? {
        let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: NavigationalWarning.key, for: annotation)
        if let systemImageName = NavigationalWarning.systemImageName, let annotation = annotation as? NavigationalWarningAnnotation, let warning = annotation.warning {
            let images = warning.mapImage(marker: false, zoomLevel: 2, tileBounds3857: nil)
            var combinedImage: UIImage? = UIImage.combineCentered(image1: images.first, image2: nil)
            if !images.isEmpty {
                for image in images.dropFirst() {
                    combinedImage = UIImage.combineCentered(image1: combinedImage, image2: image)
                }
            }
            annotationView.image = combinedImage ?? UIImage(systemName: systemImageName)
        }
        return annotationView
    }

    func items(at location: CLLocationCoordinate2D, mapView: MKMapView, touchPoint: CGPoint) -> [DataSource]? {
        let screenPercentage = 0.03
        let tolerance = mapView.visibleMapRect.size.width * Double(screenPercentage)
        
        var items: Set<NavigationalWarning> = Set<NavigationalWarning>()
        
        for overlay in mapOverlays {
            if let overlay = overlay as? NavigationalWarningPolyline {
                if lineHitTest(line: overlay, location: location, tolerance: tolerance), let warning = overlay.warning {
                    PersistenceController.current.viewContext.performAndWait {
                        if let thing = PersistenceController.current.viewContext.object(with: warning.objectID) as? NavigationalWarning {
                            items.insert(thing)
                        }
                    }
                }
            } else if let overlay = overlay as? NavigationalWarningPolygon {
                if polygonHitTest(polygon: overlay, location: location), let warning = overlay.warning {
                    PersistenceController.current.viewContext.performAndWait {
                        if let thing = PersistenceController.current.viewContext.object(with: warning.objectID) as? NavigationalWarning {
                            items.insert(thing)
                        }
                    }
                }
            } else if let overlay = overlay as? NavigationalWarningCircle {
                if circleHitTest(circle: overlay, location: location), let warning = overlay.warning {
                    PersistenceController.current.viewContext.performAndWait {
                        if let thing = PersistenceController.current.viewContext.object(with: warning.objectID) as? NavigationalWarning {
                            items.insert(thing)
                        }
                    }
                }
            }
        }
        
        // find the points
        let longitudeTolerance = mapView.region.span.longitudeDelta * Double(screenPercentage)
        let minLon = location.longitude - longitudeTolerance
        let maxLon = location.longitude + longitudeTolerance
        let minLat = location.latitude - longitudeTolerance
        let maxLat = location.latitude + longitudeTolerance
        
        let fetchRequest = self.getFetchRequest(show: self.show)
        
        var predicates: [NSPredicate] = []
        if let predicate = fetchRequest.predicate {
            predicates.append(predicate)
        }
        
        predicates.append(getBoundingPredicate(minLat: minLat, maxLat: maxLat, minLon: minLon, maxLon: maxLon))
        
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        if let points = try? PersistenceController.current.fetch(fetchRequest: fetchRequest) {
            for point in points {
                items.insert(point)
            }
        }
        
        return Array(items)
    }
    
    func getBoundingPredicate(minLat: Double, maxLat: Double, minLon: Double, maxLon: Double) -> NSPredicate {
        return NSPredicate(
            format: "latitude >= %lf AND latitude <= %lf AND longitude >= %lf AND longitude <= %lf", minLat, maxLat, minLon, maxLon
        )
    }
    
    func renderer(overlay: MKOverlay) -> MKOverlayRenderer? {
        if let polygon = overlay as? NavigationalWarningPolygon {
            let renderer = MKPolygonRenderer(polygon: polygon)
            renderer.strokeColor = NavigationalWarning.color
            renderer.lineWidth = 3
            renderer.fillColor = NavigationalWarning.color.withAlphaComponent(0.2)
            return renderer
        } else if let polyline = overlay as? NavigationalWarningPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = NavigationalWarning.color
            renderer.lineWidth = 3
            return renderer
        } else if let circle = overlay as? NavigationalWarningCircle {
            let renderer = MKCircleRenderer(circle: circle)
            renderer.strokeColor = NavigationalWarning.color
            renderer.fillColor = NavigationalWarning.color.withAlphaComponent(0.2)
            renderer.lineWidth = 3
            return renderer
        }
        return nil
    }
}
