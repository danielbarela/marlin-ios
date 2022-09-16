//
//  LocationManager.swift
//  Marlin
//
//  Created by Daniel Barela on 7/19/22.
//

import Foundation
import CoreLocation
import Combine
import sf_ios
import geopackage_ios
import ExceptionCatcher

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    private let locationManager = CLLocationManager()
    @Published var locationStatus: CLAuthorizationStatus?
    @Published var lastLocation: CLLocation?
    @Published var currentNavArea: NavigationalWarningNavArea?
    
    let navAreaGeoPackageFileName = "navigation_areas"
    let navAreaGeoPackageTableName = "navigation_areas"
    var navAreaGeoPackage: GPKGGeoPackage?
    var navAreaFeatureDao: GPKGFeatureDao?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        DispatchQueue.main.async {
            self.locationManager.startUpdatingLocation()
        }
        
        initializeGeoPackage()
    }
    
    func initializeGeoPackage() {
        guard let manager = GPKGGeoPackageFactory.manager() else {
            return
        }
        let geoPackagePath = Bundle.main.path(forResource: navAreaGeoPackageFileName, ofType: "gpkg")
        if !manager.exists(navAreaGeoPackageFileName) {
            do {
                let imported = try ExceptionCatcher.catch {
                    return manager.importGeoPackage(fromPath: geoPackagePath)
                }
                if !imported {
                    return
                }
            } catch {
                print("Error:", error.localizedDescription)
                // probably was already imported, just ignore
            }
        }
        
        navAreaGeoPackage = manager.open(navAreaGeoPackageFileName)
        navAreaFeatureDao = navAreaGeoPackage?.featureDao(withTableName: navAreaGeoPackageTableName)
    }
    
    var statusString: String {
        guard let status = locationStatus else {
            return "unknown"
        }
        
        switch status {
        case .notDetermined: return "notDetermined"
        case .authorizedWhenInUse: return "authorizedWhenInUse"
        case .authorizedAlways: return "authorizedAlways"
        case .restricted: return "restricted"
        case .denied: return "denied"
        default: return "unknown"
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        locationStatus = status
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastLocation = location
        updateCurrentNavArea()
    }
    
    func updateCurrentNavArea() {
        guard let navAreaFeatureDao = navAreaFeatureDao, let navAreaGeoPackage = navAreaGeoPackage, let lastLocation = lastLocation else {
            return
        }
        let rtree = GPKGRTreeIndexExtension(geoPackage: navAreaGeoPackage)
        let rtreeDao = rtree?.tableDao(with: navAreaFeatureDao)
        guard let point = SFPoint(xValue: lastLocation.coordinate.longitude, andYValue: lastLocation.coordinate.latitude), let resultSet = rtreeDao?.queryFeatures(with: point.envelope()) else {
            return
        }
        if resultSet.moveToNext() {
            if let code = resultSet.row().value(withColumn: "code") as? String {
                currentNavArea = NavigationalWarningNavArea.fromId(id: code)
            }
        }
        resultSet.close()
    }
}
