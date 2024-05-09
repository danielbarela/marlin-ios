// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import UIKit
import SwiftUI

public protocol DataSourceDefinition2: ObservableObject {
    var mappable: Bool { get }
    var color: UIColor { get }
    var imageName: String? { get }
    var systemImageName: String? { get }
    var image: UIImage? { get }
    var key: String { get }
//    var metricsKey: String { get }
    var name: String { get }
    var fullName: String { get }
//    var order: Int { get }
    // this should be moved to a map centric protocol
    var imageScale: CGFloat { get }
//    func shouldSync() -> Bool
//    var dateFormatter: DateFormatter { get }
//    var filterable: Filterable? { get }
}

extension DataSourceDefinition2 {
    //    var order: Int {
    //        UserDefaults.standard.dataSourceMapOrder(key)
    //    }

    var imageScale: CGFloat {
        1.0
//        UserDefaults.standard.imageScale(key) ?? 1.0
    }

    var image: UIImage? {
        if let imageName = imageName {
            return UIImage(named: imageName)
        } else if let systemImageName = systemImageName {
            return UIImage(systemName: systemImageName)
        }
        return nil
    }

    func shouldSync() -> Bool {
        false
    }

    var dateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter
    }

//    var filterable: Filterable? {
//        nil
//    }
//
//    var defaultSort: [DataSourceSortParameter] {
//        filterable?.defaultSort ?? []
//    }
}
