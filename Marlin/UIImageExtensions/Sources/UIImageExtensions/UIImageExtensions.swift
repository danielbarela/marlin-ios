import UIKit
import AVKit
import CoreLocation

extension CLLocationCoordinate2D {
    public func toPixel(
        zoomLevel: Int,
        swCorner: (x: Double, y: Double),
        neCorner: (x: Double, y: Double),
//        tileBounds3857: MapBoundingBox,
        tileSize: Double,
        canCross180thMeridian: Bool = true
    ) -> CGPoint {
        var object3857Location = to3857()

        // TODO: this logic should be improved
        // just check on the edges of the world presuming that no light will span 90 degrees, which none will
        if canCross180thMeridian && (longitude < -90 || longitude > 90) {
            // if the x location has fallen off the left side and this tile is on the other side of the world
            if object3857Location.x > swCorner.x
                && swCorner.x < 0
                && object3857Location.x > 0 {
                let newCoordinate = CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude - 360.0)
                object3857Location = newCoordinate.to3857()
            }

            // if the x value has fallen off the right side and this tile is on the other side of the world
            if object3857Location.x < neCorner.x
                && neCorner.x > 0
                && object3857Location.x < 0 {
                let newCoordinate = CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude + 360.0)
                object3857Location = newCoordinate.to3857()
            }
        }

        let xPosition = (
            (
                (object3857Location.x - swCorner.x)
                / (neCorner.x - swCorner.x)
            )
            * tileSize
        )
        let yPosition = tileSize - (
            (
                (object3857Location.y - swCorner.y)
                / (neCorner.y - swCorner.y)
            )
            * tileSize
        )
        return CGPoint(x: xPosition, y: yPosition)
    }

    public func to3857() -> (x: Double, y: Double) {
        let a = 6378137.0
        let lambda = longitude / 180 * Double.pi
        let phi = latitude / 180 * Double.pi
        let x = a * lambda
        let y = a * log(tan(Double.pi / 4 + phi / 2))

        return (x: x, y: y)
    }

    // MARK: These methods and constants are copied from SFGeometryUtils in sf-ios
    // it is impossible to use a pod as a dependency in a swift package
    static let SF_WGS84_HALF_WORLD_LON_WIDTH: Double = 180.0
    static let SF_WGS84_HALF_WORLD_LAT_HEIGHT: Double = 90.0
    static let SF_DEGREES_TO_METERS_MIN_LAT: Double = -89.99999999999999
    static let SF_WEB_MERCATOR_HALF_WORLD_WIDTH: Double = 20037508.342789244

    public func degreesToMeters() -> (x: Double, y: Double) {
        let x = normalize(x: longitude, maxX: CLLocationCoordinate2D.SF_WGS84_HALF_WORLD_LON_WIDTH)
        var y = min(latitude, CLLocationCoordinate2D.SF_WGS84_HALF_WORLD_LAT_HEIGHT)
        y = max(y, CLLocationCoordinate2D.SF_DEGREES_TO_METERS_MIN_LAT)
        let xValue = x * CLLocationCoordinate2D.SF_WEB_MERCATOR_HALF_WORLD_WIDTH
        / CLLocationCoordinate2D.SF_WGS84_HALF_WORLD_LON_WIDTH
        var yValue = log(tan(
            (CLLocationCoordinate2D.SF_WGS84_HALF_WORLD_LAT_HEIGHT + y) * .pi
            / (2 * CLLocationCoordinate2D.SF_WGS84_HALF_WORLD_LON_WIDTH)))
        / (.pi / CLLocationCoordinate2D.SF_WGS84_HALF_WORLD_LON_WIDTH)
        yValue = yValue * CLLocationCoordinate2D.SF_WEB_MERCATOR_HALF_WORLD_WIDTH
        / CLLocationCoordinate2D.SF_WGS84_HALF_WORLD_LON_WIDTH
        return (x: xValue, y: yValue)
    }

    func normalize(x: Double, maxX: Double) -> Double {
        var normalized: Double = x
        if x < -maxX {
            normalized = x + (maxX * 2.0)
        } else if x > maxX {
            normalized = x - (maxX * 2.0)
        }
        return normalized
    }

    public static func metersToDegrees(x: Double, y: Double) -> (x: Double, y: Double) {
        let xValue = x * CLLocationCoordinate2D.SF_WGS84_HALF_WORLD_LON_WIDTH
        / CLLocationCoordinate2D.SF_WEB_MERCATOR_HALF_WORLD_WIDTH
        var yValue = y * CLLocationCoordinate2D.SF_WGS84_HALF_WORLD_LON_WIDTH
        / CLLocationCoordinate2D.SF_WEB_MERCATOR_HALF_WORLD_WIDTH
        yValue = atan(exp(yValue
                          * (.pi / CLLocationCoordinate2D.SF_WGS84_HALF_WORLD_LON_WIDTH)))
        / .pi * (2 * CLLocationCoordinate2D.SF_WGS84_HALF_WORLD_LON_WIDTH)
        - CLLocationCoordinate2D.SF_WGS84_HALF_WORLD_LAT_HEIGHT
        return (x: xValue, y: yValue)
    }
}

extension UIImage {

    public func resized(to size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }

    public func aspectResize(to size: CGSize) -> UIImage {
        let scaledRect = AVMakeRect(
            aspectRatio: self.size,
            insideRect: CGRect(x: 0, y: 0, width: size.width, height: size.height)
        )
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: scaledRect)
        }
    }

    public func aspectResizeJpeg(to size: CGSize) -> Data? {
        let scaledRect = AVMakeRect(
            aspectRatio: self.size,
            insideRect: CGRect(x: 0, y: 0, width: size.width, height: size.height)
        )
        return UIGraphicsImageRenderer(size: size).jpegData(withCompressionQuality: 1.0) { _ in

            draw(in: scaledRect)
        }
    }

    public func imageWithInsets(insets: UIEdgeInsets) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(
            CGSize(width: self.size.width + insets.left + insets.right,
                   height: self.size.height + insets.top + insets.bottom), false, self.scale)
        _ = UIGraphicsGetCurrentContext()
        let origin = CGPoint(x: insets.left, y: insets.top)
        self.draw(at: origin)
        let imageWithInsets = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return imageWithInsets
    }

    public func combineCentered(image1: UIImage?, image2: UIImage?) -> UIImage? {
        guard let image1 = image1 else {
            return image2
        }
        guard let image2 = image2 else {
            return image1
        }
        let maxSize = CGSize(width: max(image1.size.width, image2.size.width),
                             height: max(image1.size.height, image2.size.height))
        UIGraphicsBeginImageContextWithOptions(maxSize, false, image1.scale)
        _ = UIGraphicsGetCurrentContext()
        let origin = CGPoint(
            x: (maxSize.width - image1.size.width) / 2.0,
            y: (maxSize.height - image1.size.height) / 2.0
        )
        image1.draw(at: origin)
        let origin2 = CGPoint(
            x: (maxSize.width - image2.size.width) / 2.0,
            y: (maxSize.height - image2.size.height) / 2.0
        )
        image2.draw(at: origin2)
        let imageWithInsets = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return imageWithInsets
    }

    public func maskWithColor(color: UIColor) -> UIImage? {
        let maskImage = cgImage!

        let width = size.width
        let height = size.height
        let bounds = CGRect(x: 0, y: 0, width: width, height: height)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let context = CGContext(
            data: nil,
            width: Int(width),
            height: Int(height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        )!

        context.clip(to: bounds, mask: maskImage)
        context.setFillColor(color.cgColor)
        context.fill(bounds)

        if let cgImage = context.makeImage() {
            let coloredImage = UIImage(cgImage: cgImage)
            return coloredImage
        } else {
            return nil
        }
    }
}
