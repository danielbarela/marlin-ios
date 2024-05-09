//
//  DataSourceImage.swift
//
//
//  Created by Daniel Barela on 3/14/24.
//

import Foundation
import DataSourceDefinition
import UIKit
import CoreLocation
import Kingfisher
import UIImageExtensions
import MapKit

public protocol DataSourceImage2 {
    static var dataSource: any DataSourceDefinition2 { get }
    static var imageCache: Kingfisher.ImageCache { get }
    @discardableResult
    func image(
        context: CGContext?,
        zoom: Int,
        tileBounds: MapBoundingBox2,
        tileSize: Double
    ) -> [UIImage]
}

public extension DataSourceImage2 {
    static var imageCache: Kingfisher.ImageCache {
        Kingfisher.ImageCache(name: dataSource.key)
    }

    var TILE_SIZE: Double {
        return 512.0
    }

    static func defaultCircleImage(dataSource: any DataSourceDefinition2) -> [UIImage] {
        var images: [UIImage] = []
        if let circleImage = CircleImage(color: dataSource.color, radius: 40 * UIScreen.main.scale, fill: true) {
            images.append(circleImage)
            if let image = dataSource.image,
               let dataSourceImage = image.aspectResize(
                to: CGSize(width: circleImage.size.width / 1.5, height: circleImage.size.height / 1.5))
                .withRenderingMode(.alwaysTemplate)
                .maskWithColor(color: UIColor.white) {
                images.append(dataSourceImage)
            }
        }
        return images
    }

    public func defaultMapImage(
        marker: Bool,
        zoomLevel: Int,
        pointCoordinate: CLLocationCoordinate2D,
        tileBounds3857: MapBoundingBox2? = nil,
        context: CGContext? = nil,
        tileSize: Double
    ) -> [UIImage] {
        // zoom level 36 is a temporary hack to draw a large image for a real map marker
        if zoomLevel == 36 {
            return Self.defaultCircleImage(dataSource: Self.dataSource)
        }

        var images: [UIImage] = []
        var radius = CGFloat(zoomLevel) / 3.0 * UIScreen.main.scale * Self.dataSource.imageScale

        if let tileBounds3857 = tileBounds3857, context != nil {
            // have to do this b/c an ImageRenderer will automatically do this
            radius *= UIScreen.main.scale
            let coordinate = pointCoordinate // ?? kCLLocationCoordinate2DInvalid
//            ?? {
//                if let point = SFGeometryUtils.centroid(of: feature) {
//                    return CLLocationCoordinate2D(latitude: point.y.doubleValue, longitude: point.x.doubleValue)
//                }
//                return kCLLocationCoordinate2DInvalid
//            }()
            if CLLocationCoordinate2DIsValid(coordinate) {
                let pixel = coordinate.toPixel(
                    zoomLevel: zoomLevel,
                    swCorner: tileBounds3857.swCorner,
                    neCorner: tileBounds3857.neCorner,
                    tileSize: tileSize)
                let circle = UIBezierPath(
                    arcCenter: pixel,
                    radius: radius,
                    startAngle: 0,
                    endAngle: 2 * CGFloat.pi,
                    clockwise: true)
                circle.lineWidth = 0.5
                Self.dataSource.color.setStroke()
                circle.stroke()
                Self.dataSource.color.setFill()
                circle.fill()
                if let dataSourceImage = Self.dataSource.image?.aspectResize(
                    to: CGSize(width: radius * 2.0 / 1.5, height: radius * 2.0 / 1.5))
                    .withRenderingMode(.alwaysTemplate).maskWithColor(color: UIColor.white) {
                    dataSourceImage.draw(
                        at: CGPoint(
                            x: pixel.x - dataSourceImage.size.width / 2.0,
                            y: pixel.y - dataSourceImage.size.height / 2.0))
                }
            }
        } else {
            if let image = CircleImage(color: Self.dataSource.color, radius: radius, fill: true) {
                images.append(image)
                if let dataSourceImage = Self.dataSource.image?.aspectResize(
                    to: CGSize(
                        width: image.size.width / 1.5,
                        height: image.size.height / 1.5)).withRenderingMode(.alwaysTemplate)
                    .maskWithColor(color: UIColor.white) {
                    images.append(dataSourceImage)
                }
            }
        }
        return images
    }

    func drawImageIntoTile(
        mapImage: UIImage,
        latitude: Double,
        longitude: Double,
        tileBounds3857: MapBoundingBox2,
        tileSize: Double
    ) {
        let object3857Location =
        coord4326To3857(
            longitude: longitude,
            latitude: latitude)
        let xPosition = (
            ((object3857Location.x - tileBounds3857.swCorner.x) /
             (tileBounds3857.neCorner.x - tileBounds3857.swCorner.x)
            )  * tileSize)
        let yPosition = tileSize - (
            ((object3857Location.y - tileBounds3857.swCorner.y)
             / (tileBounds3857.neCorner.y - tileBounds3857.swCorner.y)
            ) * tileSize)
        mapImage.draw(
            in: CGRect(
                x: (xPosition - (mapImage.size.width / 2)),
                y: (yPosition - (mapImage.size.height / 2)),
                width: mapImage.size.width,
                height: mapImage.size.height
            )
        )
    }

    func coord4326To3857(longitude: Double, latitude: Double) -> (x: Double, y: Double) {
        let a = 6378137.0
        let lambda = longitude / 180 * Double.pi
        let phi = latitude / 180 * Double.pi
        let x = a * lambda
        let y = a * log(tan(Double.pi / 4 + phi / 2))

        return (x: x, y: y)
    }

    func coord3857To4326(y: Double, x: Double) -> (lat: Double, lon: Double) {
        let a = 6378137.0
        let distance = -y / a
        let phi = Double.pi / 2 - 2 * atan(exp(distance))
        let lambda = x / a
        let lat = phi / Double.pi * 180
        let lon = lambda / Double.pi * 180

        return (lat: lat, lon: lon)
    }
}

public class MapBoundingBox2: Codable, ObservableObject {
    @Published var swCorner: (x: Double, y: Double)
    @Published var neCorner: (x: Double, y: Double)

    enum CodingKeys: String, CodingKey {
        case swCornerX
        case swCornerY
        case neCornerX
        case neCornerY
    }

    init(swCorner: (x: Double, y: Double), neCorner: (x: Double, y: Double)) {
        self.swCorner = swCorner
        self.neCorner = neCorner
    }

    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let swCornerX = try values.decode(Double.self, forKey: .swCornerX)
        let swCornerY = try values.decode(Double.self, forKey: .swCornerY)
        swCorner = (x: swCornerX, y: swCornerY)

        let neCornerX = try values.decode(Double.self, forKey: .neCornerX)
        let neCornerY = try values.decode(Double.self, forKey: .neCornerY)
        neCorner = (x: neCornerX, y: neCornerY)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(swCorner.x, forKey: .swCornerX)
        try container.encode(swCorner.y, forKey: .swCornerY)
        try container.encode(neCorner.x, forKey: .neCornerX)
        try container.encode(neCorner.y, forKey: .neCornerY)
    }

    var swCoordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: swCorner.y, longitude: swCorner.x)
    }

    var seCoordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: swCorner.y, longitude: neCorner.x)
    }

    var neCoordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: neCorner.y, longitude: neCorner.x)
    }

    var nwCoordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: neCorner.y, longitude: swCorner.x)
    }
}

public protocol DataSourceOverlay2 {
    var key: String? { get set }
}

public class DataSourceTileOverlay2: MKTileOverlay, DataSourceOverlay2 {
    public var key: String?
    let tileRepository: TileRepository2

    public init(tileRepository: TileRepository2, key: String) {
        self.tileRepository = tileRepository
        self.key = key
        super.init(urlTemplate: nil)
    }

    public override func loadTile(at path: MKTileOverlayPath, result: @escaping (Data?, Error?) -> Void) {
        let options: KingfisherOptionsInfo? =
        (tileRepository.cacheSourceKey != nil && tileRepository.imageCache != nil) ?
        [.targetCache(tileRepository.imageCache!)] : [.forceRefresh]

        KingfisherManager.shared.retrieveImage(
            with: .provider(
                DataSourceTileProvider2(
                    tileRepository: tileRepository,
                    path: path
                )
            ),
            options: options
        ) { imageResult in
            switch imageResult {
            case .success(let value):
                result(value.image.pngData(), nil)

            case .failure:
                break
            }
        }
    }
}

struct ImageSector: CustomStringConvertible {
    var startDegrees: Double
    var endDegrees: Double
    var color: UIColor
    var text: String?
    var obscured: Bool = false
    var range: Double?

    var description: String {
        return """
        Sector starting at \(startDegrees - 90.0)\
        , going to \(endDegrees - 90.0) has color\
         \(color) is \(obscured ? "obscured" : "visible")\
         with range of \(range ?? -1)\n
        """
    }
}

class CircleImage: UIImage {
    // just have this draw the text at an offset fom the middle
    // based on the passed in image or maybe just a passed in size
    convenience init?(imageSize: CGSize, sideText: String, fontSize: CGFloat) {
        var rect = CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height)
        let labelColor = UIColor.label

        // Color text
        let attributes = [ NSAttributedString.Key.foregroundColor: labelColor,
                           NSAttributedString.Key.font: UIFont.systemFont(ofSize: fontSize)]

        let size = sideText.size(withAttributes: attributes)
        // expand the rect on both sides, to maintain the center, to fit the text
        let textWidth = 8 + size.width
        rect = CGRect(x: 0, y: 0, width: imageSize.width + (textWidth * 2), height: rect.size.height)
        let renderer = UIGraphicsImageRenderer(size: rect.size)
        let image = renderer.image { _ in
            let center = CGPoint(x: (rect.width / 2.0), y: rect.height / 2.0)

            let textRect = CGRect(
                x: 4 + center.x + imageSize.width / 2,
                y: center.y - size.height / 2,
                width: rect.width,
                height: rect.height)
            sideText.draw(in: textRect, withAttributes: attributes)
        }
        guard  let cgImage = image.cgImage else {
            return nil
        }
        self.init(cgImage: cgImage)
    }

    convenience init?(
        color: UIColor,
        radius: CGFloat,
        fill: Bool = false,
        withoutScreenScale: Bool = false,
        arcWidth: CGFloat? = nil
    ) {
        let strokeWidth = arcWidth ?? 0.5
        let rect = CGRect(
            x: 0,
            y: 0,
            width: strokeWidth + radius * 2,
            height: strokeWidth + radius * 2)

        let renderer = {
            if withoutScreenScale {
                let format = UIGraphicsImageRendererFormat()
                format.scale = 1
                return UIGraphicsImageRenderer(size: rect.size, format: format)
            }
            return UIGraphicsImageRenderer(size: rect.size)
        }()
        let image = renderer.image { _ in
            let circle = UIBezierPath()
            let center = CGPoint(x: (rect.width / 2.0), y: rect.height / 2.0)
            circle.addArc(withCenter: center, radius: radius,
                          startAngle: 0, endAngle: 360 * (CGFloat.pi / 180.0),
                          clockwise: true)
            circle.lineWidth = strokeWidth
            color.setStroke()
            circle.stroke()
            if fill {
                color.setFill()
                circle.fill()
            }
        }

        guard  let cgImage = image.cgImage else {
            return nil
        }
        self.init(cgImage: cgImage)
    }

    class func drawOuterBoundary(color: UIColor, diameter: CGFloat, width: CGFloat) {
        color.setStroke()
        let outerBoundary = UIBezierPath(
            ovalIn: CGRect(
                x: width / 2.0,
                y: width / 2.0,
                width: diameter + width,
                height: diameter + width )
        )
        outerBoundary.lineWidth = width / 4.0
        outerBoundary.stroke()
    }

    class func drawSectorPiece(
        sector: ImageSector,
        center: CGPoint,
        radius: CGFloat,
        strokeWidth: CGFloat,
        fill: Bool
    ) {
        let startAngle = CGFloat(sector.startDegrees) * (CGFloat.pi / 180.0)
        let endAngle = CGFloat(sector.endDegrees) * (CGFloat.pi / 180.0)

        let piePath = UIBezierPath()
        piePath.addArc(withCenter: center, radius: radius,
                       startAngle: startAngle, endAngle: endAngle,
                       clockwise: true)

        if fill {
            piePath.addLine(to: CGPoint(x: radius, y: radius))
            piePath.close()
            if sector.obscured {
                UIColor.lightGray.setFill()
            } else {
                sector.color.setFill()
            }
            piePath.fill()

        } else {
            if sector.obscured {
                piePath.setLineDash([3.0, 3.0], count: 2, phase: 0.0)
                piePath.lineWidth = strokeWidth / 2.0
                UIColor.lightGray.setStroke()
            } else {
                piePath.lineWidth = strokeWidth
                sector.color.setStroke()
            }
            piePath.stroke()
        }
    }

    class func drawSectorSeparators(
        sector: ImageSector,
        center: CGPoint,
        sectorDashLength: CGFloat
    ) {
        let dashColor = UIColor.label.withAlphaComponent(0.87)

        let sectorDash = UIBezierPath()
        sectorDash.move(to: center)

        sectorDash.addLine(to: CGPoint(x: center.x + sectorDashLength, y: center.y))
        sectorDash.apply(CGAffineTransform(translationX: -center.x, y: -center.y))
        sectorDash.apply(CGAffineTransform(rotationAngle: CGFloat(sector.startDegrees) * .pi / 180))
        sectorDash.apply(CGAffineTransform(translationX: center.x, y: center.y))

        sectorDash.lineWidth = 0.2
        let  dashes: [ CGFloat ] = [ 2.0, 1.0 ]
        sectorDash.setLineDash(dashes, count: dashes.count, phase: 0.0)
        sectorDash.lineCapStyle = .butt
        dashColor.setStroke()
        sectorDash.stroke()

        let sectorEndDash = UIBezierPath()
        sectorEndDash.move(to: center)

        sectorEndDash.addLine(to: CGPoint(x: center.x + sectorDashLength, y: center.y))
        sectorEndDash.apply(CGAffineTransform(translationX: -center.x, y: -center.y))
        sectorEndDash.apply(CGAffineTransform(rotationAngle: CGFloat(sector.endDegrees) * .pi / 180))
        sectorEndDash.apply(CGAffineTransform(translationX: center.x, y: center.y))

        sectorEndDash.lineWidth = 0.2
        sectorEndDash.setLineDash(dashes, count: dashes.count, phase: 0.0)
        sectorEndDash.lineCapStyle = .butt
        dashColor.setStroke()
        sectorEndDash.stroke()
    }

    class func drawSectorText(
        sector: ImageSector,
        center: CGPoint,
        radius: CGFloat,
        arcWidth: CGFloat?,
        fill: Bool
    ) {
        if let text = sector.text {
            // always use black letters when filled
            let color = fill ? UIColor.black : UIColor.label
            let attributes = [ NSAttributedString.Key.foregroundColor: color,
                               NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: arcWidth ?? 3)]
            let size = text.size(withAttributes: attributes)

            let endDegrees = sector.endDegrees > sector.startDegrees
            ? sector.endDegrees : sector.endDegrees + 360.0
            let midPointAngle = CGFloat(sector.startDegrees) + CGFloat(endDegrees - sector.startDegrees) / 2.0
            var textRadius = radius
            if let arcWidth = arcWidth {
                textRadius -= arcWidth * 1.75
            } else {
                textRadius -= size.height
            }
            text.drawWithBasePoint(
                basePoint: center,
                radius: textRadius,
                andAngle: (midPointAngle - 90) * .pi / 180,
                andAttributes: attributes
            )
        }
    }

    // sector degrees start at 0 at 3 o'clock
    convenience init?(
        suggestedFrame: CGRect,
        sectors: [ImageSector],
        outerStroke: UIColor? = nil,
        radius: CGFloat? = nil,
        fill: Bool = false,
        arcWidth: CGFloat? = nil,
        sectorSeparator: Bool = true
    ) {
        let strokeWidth = arcWidth ?? 2.0
        let outerStrokeWidth = strokeWidth / 4.0
        let rect = suggestedFrame
        let finalRadius = radius ?? min(rect.width / 2.0, rect.height / 2.0) - (outerStrokeWidth)
        let diameter = finalRadius * 2.0
        let sectorDashLength = min(rect.width / 2.0, rect.height / 2.0)

        let renderer = UIGraphicsImageRenderer(size: rect.size)
        let image = renderer.image { _ in
            if let outerStroke = outerStroke {
                CircleImage.drawOuterBoundary(color: outerStroke, diameter: diameter, width: outerStrokeWidth)
            }

            let center = CGPoint(x: rect.width / 2.0, y: rect.height / 2.0)

            for sector in sectors {
                CircleImage.drawSectorPiece(
                    sector: sector,
                    center: center,
                    radius: finalRadius,
                    strokeWidth: strokeWidth,
                    fill: fill
                )

                if sectorSeparator && sector.endDegrees - sector.startDegrees < 360 {
                    CircleImage.drawSectorSeparators(
                        sector: sector,
                        center: center,
                        sectorDashLength: sectorDashLength
                    )
                }

                CircleImage.drawSectorText(
                    sector: sector,
                    center: center,
                    radius: finalRadius,
                    arcWidth: arcWidth,
                    fill: fill
                )
            }
        }

        guard  let cgImage = image.cgImage else {
            return nil
        }
        self.init(cgImage: cgImage)
    }
}

extension UIImage {

    static func dynamicAsset(lightImage: UIImage, darkImage: UIImage) -> UIImage {
        let imageAsset = UIImageAsset()

        let lightMode = UITraitCollection(traitsFrom: [.init(userInterfaceStyle: .light)])
        imageAsset.register(lightImage, with: lightMode)

        let darkMode = UITraitCollection(traitsFrom: [.init(userInterfaceStyle: .dark)])
        imageAsset.register(darkImage, with: darkMode)

        return imageAsset.image(with: .current)
    }

}

extension String {
    func drawWithBasePoint(basePoint: CGPoint,
                           radius: CGFloat,
                           andAngle angle: CGFloat,
                           andAttributes attributes: [NSAttributedString.Key: Any]) {
        let size: CGSize = self.size(withAttributes: attributes)
        let context: CGContext = UIGraphicsGetCurrentContext()!
        let translation: CGAffineTransform = CGAffineTransform(translationX: basePoint.x, y: basePoint.y)
        let rotation: CGAffineTransform = CGAffineTransform(rotationAngle: angle)
        context.concatenate(translation)
        context.concatenate(rotation)
        let rect = CGRect(x: -(size.width / 2), y: radius, width: size.width, height: size.height)
        self.draw(in: rect, withAttributes: attributes)
        context.concatenate(rotation.inverted())
        context.concatenate(translation.inverted())
    }
}
