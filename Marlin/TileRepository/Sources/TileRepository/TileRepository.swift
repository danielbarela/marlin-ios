// The Swift Programming Language
// https://docs.swift.org/swift-book

import DataSourceDefinition
import Kingfisher

public protocol TileRepository2 {
    var dataSource: any DataSourceDefinition2 { get }
    var cacheSourceKey: String? { get }

    var imageCache: Kingfisher.ImageCache? { get }

    var filterCacheKey: String { get }
    var alwaysShow: Bool { get }

    func getTileableItems(
        minLatitude: Double,
        maxLatitude: Double,
        minLongitude: Double,
        maxLongitude: Double
    ) async -> [DataSourceImage2]

    func getItemKeys(
        minLatitude: Double,
        maxLatitude: Double,
        minLongitude: Double,
        maxLongitude: Double
    ) async -> [String]

    func clearCache(completion: @escaping () -> Void)
}

public extension TileRepository2 {
    func clearCache(completion: @escaping () -> Void) {
        if let imageCache = self.imageCache {
            imageCache.clearCache(completion: completion)
        } else {
            completion()
        }
    }
}
