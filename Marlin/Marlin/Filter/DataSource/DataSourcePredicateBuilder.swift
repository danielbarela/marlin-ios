//
//  DataSourceFilterParameterPredicateBuilder.swift
//  Marlin
//
//  Created by Daniel Barela on 12/20/23.
//

import Foundation
import sf_ios

class DataSourcePredicateBuilder {

    var property: DataSourceProperty
    var comparison: DataSourceFilterComparison
    var filterable: Filterable

    var valueString: String?
    var valueDate: Date?
    var valueInt: Int?
    var valueDouble: Double?
    var valueLatitude: Double?
    var valueLongitude: Double?
    var valueBounds: MapBoundingBox?
    var windowUnits: DataSourceWindowUnits?

    init(
        property: DataSourceProperty,
        comparison: DataSourceFilterComparison,
        filterable: Filterable,
        valueString: String? = nil,
        valueDate: Date? = nil,
        valueInt: Int? = nil,
        valueDouble: Double? = nil,
        valueLatitude: Double? = nil,
        valueLongitude: Double? = nil,
        valueBounds: MapBoundingBox? = nil,
        windowUnits: DataSourceWindowUnits? = nil
    ) {
        self.property = property
        self.comparison = comparison
        self.filterable = filterable
        self.valueString = valueString
        self.valueDate = valueDate
        self.valueInt = valueInt
        self.valueDouble = valueDouble
        self.valueLatitude = valueLatitude
        self.valueLongitude = valueLongitude
        self.valueBounds = valueBounds
        self.windowUnits = windowUnits
    }

    func propertyAndComparison() -> String {
        var propertyAndComparison: String = "\(property.key) \(comparison.coreDataComparison())"
        if let subEntityKey = property.subEntityKey {
            propertyAndComparison = "ANY \(property.key).\(subEntityKey) \(comparison.coreDataComparison())"
        }
        return propertyAndComparison
    }

    func toPredicate() -> NSPredicate? {
        if property.type == .string {
            return stringPredicate()
        } else if property.type == .date {
            return datePredicate(propertyAndComparison: propertyAndComparison())
        } else if property.type == .int {
            return intPredicate(propertyAndComparison: propertyAndComparison())
        } else if property.type == .boolean {
            return boolPredicate(propertyAndComparison: propertyAndComparison())
        } else if property.type == .float || property.type == .double {
            return doublePredicate(propertyAndComparison: propertyAndComparison())
        } else if property.type == .latitude {
            return latitudePredicate(propertyAndComparison: propertyAndComparison())
        } else if property.type == .longitude {
            return longitudePredicate(propertyAndComparison: propertyAndComparison())
        } else if property.type == .enumeration {
            return enumPredicate(propertyAndComparison: propertyAndComparison())
        } else if property.type == .location {
            return locationPredicate(dataSource: filterable)
        }
        return nil
    }

    func stringPredicate() -> NSPredicate? {
        if let value = valueString {
            return NSPredicate(format: "\(property.key) \(comparison.coreDataComparison()) %@", value)
        }
        return nil
    }

    func datePredicate(propertyAndComparison: String) -> NSPredicate? {
        if comparison == .window {
            if let value = windowUnits {
                var calendar = Calendar.current
                calendar.timeZone = NSTimeZone(forSecondsFromGMT: 0) as TimeZone

                // Get today's beginning & end
                let start = calendar.startOfDay(for: Date())
                if let dateFrom = calendar.date(byAdding: .day, value: -value.numberOfDays(), to: start) {
                    return NSPredicate(format: "\(propertyAndComparison) %@", dateFrom as NSDate)
                }
            }
        } else if let value = valueDate {
            var calendar = Calendar.current
            calendar.timeZone = NSTimeZone(forSecondsFromGMT: 0) as TimeZone

            // Get today's beginning & end
            let dateFrom = calendar.startOfDay(for: value)

            if comparison == .equals {

                guard let dateTo = calendar.date(byAdding: .day, value: 1, to: dateFrom) else {
                    return nil
                }
                // Set predicate as date being today's date
                let fromPredicate = NSPredicate(format: "\(property.key) >= %@", dateFrom as NSDate)
                let toPredicate = NSPredicate(format: "\(property.key) < %@", dateTo as NSDate)
                return NSCompoundPredicate(andPredicateWithSubpredicates: [fromPredicate, toPredicate])
            } else {
                return NSPredicate(format: "\(propertyAndComparison) %@", dateFrom as NSDate)
            }
        }
        return nil
    }

    func intPredicate(propertyAndComparison: String) -> NSPredicate? {
        if let value = valueInt {
            return NSPredicate(format: "\(propertyAndComparison) %d", value)
        }
        return nil
    }

    func boolPredicate(propertyAndComparison: String) -> NSPredicate? {
        if let value = valueInt {
            return NSPredicate(format: "\(propertyAndComparison) %d", value)
        }
        return nil
    }

    func doublePredicate(propertyAndComparison: String) -> NSPredicate? {
        if let value = valueDouble {
            return NSPredicate(format: "\(propertyAndComparison) %f", value)
        }
        return nil
    }

    func latitudePredicate(propertyAndComparison: String) -> NSPredicate? {
        if let value = valueLatitude {
            return NSPredicate(format: "\(propertyAndComparison) %f", value)
        }
        return nil
    }

    func longitudePredicate(propertyAndComparison: String) -> NSPredicate? {
        if let value = valueLongitude {
            return NSPredicate(format: "\(propertyAndComparison) %f", value)
        }
        return nil
    }

    func enumPredicate(propertyAndComparison: String) -> NSPredicate? {
        if let value = valueString {
            if let queryValues = property.enumerationValues?[value], !queryValues.isEmpty {
                var valuePredicates: [NSPredicate] = []
                for queryValue in queryValues {
                    valuePredicates.append(NSPredicate(format: "\(propertyAndComparison) %@", queryValue))
                }
                return NSCompoundPredicate(orPredicateWithSubpredicates: valuePredicates)
            }

            return NSPredicate(format: "\(propertyAndComparison) %@", value)
        }
        return nil
    }

    func locationPredicate(dataSource: Filterable) -> NSPredicate? {
        if comparison == .bounds {
            return boundsPredicate(dataSource: dataSource)
        }
        var centralLongitude: Double?
        var centralLatitude: Double?

        if comparison == .nearMe {
            if let lastLocation = LocationManager.shared().lastLocation {
                centralLongitude = lastLocation.coordinate.longitude
                centralLatitude = lastLocation.coordinate.latitude
            }
        } else if comparison == .closeTo {
            centralLongitude = valueLongitude
            centralLatitude = valueLatitude
        }

        guard let distance = valueInt, let latitude = centralLatitude, let longitude = centralLongitude else {
            NSLog("Nothing to use as location predicate")
            return nil
        }

        let nauticalMilesMeasurement = NSMeasurement(doubleValue: Double(distance), unit: UnitLength.nauticalMiles)
        let metersMeasurement = nauticalMilesMeasurement.converting(to: UnitLength.meters)
        let metersDistance = metersMeasurement.value

        if let metersPoint = SFGeometryUtils.degreesToMetersWith(x: longitude, andY: latitude),
           let x = metersPoint.x as? Double,
           let y = metersPoint.y as? Double {
            let southWest = SFGeometryUtils.metersToDegreesWith(x: x - metersDistance, andY: y - metersDistance)
            let northEast = SFGeometryUtils.metersToDegreesWith(x: x + metersDistance, andY: y + metersDistance)
            if let southWest = southWest,
               let northEast = northEast,
               let maxy = northEast.y,
               let miny = southWest.y,
               let minx = southWest.x,
               let maxx = northEast.x {
                if let dataSource = dataSource as? Locatable {
                    return type(of: dataSource).getBoundingPredicate(
                        minLat: miny.doubleValue,
                        maxLat: maxy.doubleValue,
                        minLon: minx.doubleValue,
                        maxLon: maxx.doubleValue)
                }
                return nil
            }
        }
        return nil
    }

    func boundsPredicate(dataSource: Filterable) -> NSPredicate? {
        guard let bounds = valueBounds else {
            return nil
        }
        if let dataSource = dataSource.locatableClass {
            return dataSource.getBoundingPredicate(
                minLat: bounds.swCorner.y,
                maxLat: bounds.neCorner.y,
                minLon: bounds.swCorner.x,
                maxLon: bounds.neCorner.x)
        }
        return nil
    }
}
