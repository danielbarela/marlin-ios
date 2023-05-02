//
//  Notifications.swift
//  Marlin
//
//  Created by Daniel Barela on 6/14/22.
//

import Foundation
import MapKit

extension Notification.Name {
    public static let PersistentStoreLoaded = Notification.Name("PersistenStoreLoaded")
    public static let MapItemsTapped = Notification.Name("MapItemsTapped")
    public static let MapAnnotationFocused = Notification.Name("MapAnnotationFocused")
    public static let FocusMapOnItem = Notification.Name("FocusMapOnItem")
    public static let DismissBottomSheet = Notification.Name("DismissBottomSheet")
    public static let BottomSheetDismissed = Notification.Name("BottomSheetDismissed")
    public static let MapRequestFocus = Notification.Name("MapRequestFocus")
    public static let FocusLight = Notification.Name("FocusLight")
    public static let FocusRadioBeacon = Notification.Name("FocusRadioBeacon")
    public static let FocusAsam = Notification.Name("FocusAsam")
    public static let FocusModu = Notification.Name("FocusModu")
    public static let FocusPort = Notification.Name("FocusPort")
    public static let FocusDifferentialGPSStation = Notification.Name("FocusDifferentialGPSStation")
    public static let FocusDFRS = Notification.Name("FocusDFRS")
    public static let FocusNavigationalWarning = Notification.Name("FocusNavigationalWarning")
    public static let ViewDataSource = Notification.Name("ViewDataSource")
    public static let ViewNavigationalWarning = Notification.Name("ViewNavigationalWarning")
    public static let SwitchTabs = Notification.Name("SwitchTabs")
    public static let SnackbarNotification = Notification.Name("Snackbar")
    public static let DataSourceUpdated = Notification.Name("DataSourceUpdated")
    public static let DataSourceLoading = Notification.Name("DataSourceLoading")
    public static let DataSourceLoaded = Notification.Name("DataSourceLoaded")
    public static let BatchUpdateComplete = Notification.Name("BatchUpdateComplete")
    public static let MappedDataSourcesUpdated = Notification.Name("MappedDataSourcesUpdated")
    public static let LocationAuthorizationStatusChanged = Notification.Name("LocationAuthorizationStatusChanged")
    public static let DocumentPreview = Notification.Name("DocumentPreview")
}

struct FocusMapOnItemNotification {
    var item: (any DataSourceLocation)?
}

struct MapAnnotationFocusedNotification {
    var annotation: MKAnnotation?
}

struct MapItemsTappedNotification {
    var annotations: [Any]?
    var items: [any DataSource]?
    var mapView: MKMapView?
}

struct SnackbarNotification {
    var snackbarModel: SnackbarModel?
}

struct DataSourceUpdatedNotification {
    var key: String
    var updates: Int?
    var inserts: Int?
    var deletes: Int?
}

struct BatchUpdateComplete {
    var dataSourceUpdates: [DataSourceUpdatedNotification]
}
