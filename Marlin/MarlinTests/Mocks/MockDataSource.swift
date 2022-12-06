//
//  MockDataSource.swift
//  MarlinTests
//
//  Created by Daniel Barela on 12/2/22.
//

import Foundation
import CoreLocation

@testable import Marlin

enum MockEnum: String, CaseIterable, CustomStringConvertible {
    case Y
    case N
    
    static func fromValue(_ value: String?) -> MockEnum {
        guard let value = value else {
            return .Y
        }
        return MockEnum(rawValue: value) ?? .Y
    }
    
    var description: String {
        switch self {
        case .Y:
            return "Yes"
        case .N:
            return "No"
        default:
            return "No"
        }
    }
    
    static var keyValueMap: [String: [String]] {
        DecisionEnum.allCases.reduce(into: [String: [String]]()) {
            var array: [String] = $0[$1.description] ?? []
            array.append($1.rawValue)
            return $0[$1.description] = array
        }
    }
}

class MockDataSource: DataSource {
    static var properties: [Marlin.DataSourceProperty] = [
        DataSourceProperty(name: "String", key: "stringProperty", type: .string),
        DataSourceProperty(name: "Date", key: "dateProperty", type: .date),
        DataSourceProperty(name: "Int", key: "intProperty", type: .int)
    ]
    
    static var defaultSort: [Marlin.DataSourceSortParameter] = []
    
    static var defaultFilter: [Marlin.DataSourceFilterParameter] = []
    
    static var isMappable: Bool = true
    
    static var dataSourceName: String = "mock"
    
    static var fullDataSourceName: String = "mock"
    
    static var key: String = "mock"
    
    static var color: UIColor = UIColor.black
    
    static var imageName: String?
    
    static var systemImageName: String? = "face.smiling"
    
    var color: UIColor = UIColor.black
    
    static var imageScale: CGFloat = 0.5
    
    static var dateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return dateFormatter
    }
    
    @objc var latitude: Double = 1.0
    
    @objc var longitude: Double = 1.0
    
    var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 1.0, longitude: 1.0)
    
    @objc var stringProperty: String = ""
    @objc var intProperty: Int = 0
    @objc var doubleProperty: Double = 0.0
    @objc var floatProperty: Float = 0.0
    @objc var enumerationProperty: String = MockEnum.Y.description
    @objc var locationProperty: String = ""
    @objc var dateProperty: Date = Date()
    @objc var booleanProperty: Bool = true
}

class MockDataSourceDefaultSort: DataSource {
    static var properties: [Marlin.DataSourceProperty] = [
        DataSourceProperty(name: "String", key: "stringProperty", type: .string),
        DataSourceProperty(name: "Date", key: "dateProperty", type: .date),
        DataSourceProperty(name: "Int", key: "intProperty", type: .int)
    ]
    
    static var defaultSort: [Marlin.DataSourceSortParameter] = [
        DataSourceSortParameter(property: DataSourceProperty(name: "Date", key: "dateProperty", type: .date), ascending: true)
    ]
    
    static var defaultFilter: [Marlin.DataSourceFilterParameter] = [DataSourceFilterParameter(property: DataSourceProperty(name: "Date", key: #keyPath(MockDataSourceDefaultSort.dateProperty), type: .date), comparison: .window, windowUnits: DataSourceWindowUnits.last365Days)]
    
    static var isMappable: Bool = true
    
    static var dataSourceName: String = "mockdefaultsort"
    
    static var fullDataSourceName: String = "mockdefaultsort"
    
    static var key: String = "mockdefaultsort"
    
    static var color: UIColor = UIColor.black
    
    static var imageName: String?
    
    static var systemImageName: String? = "face.smiling"
    
    var color: UIColor = UIColor.black
    
    static var imageScale: CGFloat = 0.5
    
    static var dateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return dateFormatter
    }
    
    @objc var latitude: Double = 1.0
    
    @objc var longitude: Double = 1.0
    
    var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 1.0, longitude: 1.0)
    
    @objc var stringProperty: String = ""
    @objc var intProperty: Int = 0
    @objc var doubleProperty: Double = 0.0
    @objc var floatProperty: Float = 0.0
    @objc var enumerationProperty: String = MockEnum.Y.description
    @objc var locationProperty: String = ""
    @objc var dateProperty: Date = Date()
    @objc var booleanProperty: Bool = true
}