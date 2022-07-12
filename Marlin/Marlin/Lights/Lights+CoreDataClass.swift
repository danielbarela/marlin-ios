//
//  Lights+CoreDataClass.swift
//  Marlin
//
//  Created by Daniel Barela on 7/6/22.
//

import Foundation
import CoreData
import MapKit
import OSLog

class Lights: NSManagedObject, MKAnnotation, AnnotationWithView, DataSource {
    static let whiteSector = UIColor(red: 1.00, green: 1.00, blue: 0.0, alpha: 0.87)
    static let greenSector = UIColor(red: 0.05, green: 0.89, blue: 0.1, alpha: 1.00)
    static let redSector = UIColor(red: 0.98, green: 0.0, blue: 0.0, alpha: 1.00)
    
    static var isMappable: Bool = true
    static var dataSourceName: String = "Lights"
    static var key: String = "Lights"
    
    static var color: UIColor = .systemYellow
    var color: UIColor {
        return Lights.color
    }
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var isLight: Bool {
        guard let name = self.name else {
            return false
        }
        return !name.contains("RACON")
    }
    
    var expandedCharacteristic: String? {
        var expanded = characteristic
        expanded = expanded?.replacingOccurrences(of: "Al.", with: "Alternating ")
        expanded = expanded?.replacingOccurrences(of: "lt.", with: "Lit ")
        expanded = expanded?.replacingOccurrences(of: "bl.", with: "Blast ")
        expanded = expanded?.replacingOccurrences(of: "Mo.", with: "Morse code ")
        expanded = expanded?.replacingOccurrences(of: "Bu.", with: "Blue ")
        expanded = expanded?.replacingOccurrences(of: "min.", with: "Minute ")
        expanded = expanded?.replacingOccurrences(of: "Dir.", with: "Directional ")
        expanded = expanded?.replacingOccurrences(of: "obsc.", with: "Obscured ")
        expanded = expanded?.replacingOccurrences(of: "ec.", with: "Eclipsed ")
        expanded = expanded?.replacingOccurrences(of: "Oc.", with: "Occulting ")
        expanded = expanded?.replacingOccurrences(of: "ev.", with: "Every ")
        expanded = expanded?.replacingOccurrences(of: "Or.", with: "Orange ")
        expanded = expanded?.replacingOccurrences(of: "F.", with: "Fixed ")
        expanded = expanded?.replacingOccurrences(of: "Q.", with: "Quick Flashing ")
        expanded = expanded?.replacingOccurrences(of: "Fl.", with: "Flashing ")
        expanded = expanded?.replacingOccurrences(of: "R.", with: "Red ")
        expanded = expanded?.replacingOccurrences(of: "fl.", with: "Flash ")
        expanded = expanded?.replacingOccurrences(of: "s.", with: "Seconds ")
        expanded = expanded?.replacingOccurrences(of: "G.", with: "Green ")
        expanded = expanded?.replacingOccurrences(of: "si.", with: "Silent ")
        expanded = expanded?.replacingOccurrences(of: "horiz.", with: "Horizontal ")
        expanded = expanded?.replacingOccurrences(of: "U.Q.", with: "Ultra Quick ")
        expanded = expanded?.replacingOccurrences(of: "flashing intes.", with: "Intensified ")
        expanded = expanded?.replacingOccurrences(of: "I.Q.", with: "Interrupted Quick ")
        expanded = expanded?.replacingOccurrences(of: "flashing unintens.", with: "Unintensified ")
        expanded = expanded?.replacingOccurrences(of: "vert.", with: "Vertical ")
        expanded = expanded?.replacingOccurrences(of: "Iso.", with: "Isophase ")
        expanded = expanded?.replacingOccurrences(of: "Vi.", with: "Violet ")
        expanded = expanded?.replacingOccurrences(of: "I.V.Q.", with: "Interrupted Very Quick Flashing ")
        expanded = expanded?.replacingOccurrences(of: "vis.", with: "Visible ")
        expanded = expanded?.replacingOccurrences(of: "V.Q.", with: "Very Quick ")
        expanded = expanded?.replacingOccurrences(of: "Km.", with: "Kilometer ")
        expanded = expanded?.replacingOccurrences(of: "W.", with: "White ")
        expanded = expanded?.replacingOccurrences(of: "L.Fl.", with: "Long Flashing ")
        expanded = expanded?.replacingOccurrences(of: "Y.", with: "Yellow ")
        return expanded
    }
    
    var lightSectors: [LightSector]? {
        guard let remarks = remarks else {
            return nil
        }
        var sectors: [LightSector] = []
        
        let pattern = #"(?<color>[A-Z]+)\.?(?<unintensified>(\(unintensified\))?)( (?<startdeg>(\d*))°)?(?<startminutes>[0-9]*)'?(-(?<enddeg>(\d*))°)(?<endminutes>[0-9]*)`?"#
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let nsrange = NSRange(remarks.startIndex..<remarks.endIndex,
                              in: remarks)
        var previousEnd: Double = 0.0

        regex?.enumerateMatches(in: remarks, range: nsrange, using: { match, flags, stop in
            guard let match = match else {
                return
            }
            var color: String = ""
            var end: Double = 0.0
            var start: Double?
            for component in ["color", "startdeg", "startminutes", "enddeg", "endminutes"] {

                
                let nsrange = match.range(withName: component)
                if nsrange.location != NSNotFound,
                   let range = Range(nsrange, in: remarks)
                {
                    if component == "color" {
                        color = "\(remarks[range])"
                    } else if component == "startdeg" {
                        start = (Double(remarks[range]) ?? 0.0)
                    } else if component == "startminutes" {
                        if start != nil {
                            start = start! + (Double(remarks[range]) ?? 0.0) / 60
                        }
                    } else if component == "enddeg" {
                        end = (Double(remarks[range]) ?? 0.0)
                    } else if component == "endminutes" {
                        end += (Double(remarks[range]) ?? 0.0) / 60
                    }
                }
            }
            let uicolor: UIColor = {
                if color == "W" {
                    return Lights.whiteSector
                } else if color == "R" {
                    return Lights.redSector
                } else if color == "G" {
                    return Lights.greenSector
                }
                return UIColor.clear
            }()
            if let start = start {
                sectors.append(LightSector(startDegrees: start, endDegrees: end, color: uicolor, text: color))
            } else {
                if end < previousEnd {
                    end += 360
                }
                sectors.append(LightSector(startDegrees: previousEnd, endDegrees: end, color: uicolor, text: color))
            }
            previousEnd = end
        })
        return sectors
    }
    
    var morseCode: String? {
        return "- • - "
    }
    
    var mapImage: UIImage {
        if let lightSectors = lightSectors {
            return LightColorImage(frame: CGRect(x: 0, y: 0, width: 200, height: 200), sectors: lightSectors, arcWidth: 6, arcRadius: 50, includeSectorDashes: true, includeLetters: true, darkMode: false) ?? UIImage()
        }
        return UIImage()
    }
    
    func view(on: MKMapView) -> MKAnnotationView {
        let annotationView = on.dequeueReusableAnnotationView(withIdentifier: LightAnnotationView.ReuseID, for: self)
        if let lightSectors = lightSectors {
            let image = LightColorImage.dynamicAsset(frame: CGRect(x: 0, y: 0, width: 100, height: 100), sectors: lightSectors, arcWidth: 3, arcRadius: 25, includeSectorDashes: true, includeLetters: true)
            if let lav = annotationView as? LightAnnotationView {
                lav.combinedImage = image
            } else {
                annotationView.image = image
            }
        }
        self.annotationView = annotationView
        return annotationView
    }
    
    var annotationView: MKAnnotationView?
    
    static func newBatchInsertRequest(with propertyList: [LightsProperties]) -> NSBatchInsertRequest {
        var index = 0
        let total = propertyList.count
        
        var previousRegionHeading: String?
        var previousSubregionHeading: String?
        var previousLocalHeading: String?
        // Provide one dictionary at a time when the closure is called.
        let batchInsertRequest = NSBatchInsertRequest(entity: Lights.entity(), dictionaryHandler: { dictionary in
            guard index < total else { return true }
            let propertyDictionary = propertyList[index].dictionaryValue
            let region = propertyDictionary["regionHeading"] as? String ?? previousRegionHeading
            let subregion = propertyDictionary["subregionHeading"] as? String ?? previousSubregionHeading
            let local = propertyDictionary["localHeading"] as? String ?? previousSubregionHeading
            
            var correctedLocationDictionary: [String:String?] = [
                "regionHeading": propertyDictionary["regionHeading"] as? String ?? previousRegionHeading,
                "subregionHeading": propertyDictionary["subregionHeading"] as? String ?? previousSubregionHeading,
                "localHeading": propertyDictionary["localHeading"] as? String ?? previousSubregionHeading
            ]
            correctedLocationDictionary["sectionHeader"] = "\(propertyDictionary["geopoliticalHeading"] as? String ?? "")\(correctedLocationDictionary["regionHeading"] != nil ? ": \(correctedLocationDictionary["regionHeading"] as? String ?? "")" : "")"

            
            if previousRegionHeading != region {
                previousRegionHeading = region
                previousSubregionHeading = nil
                previousLocalHeading = nil
            } else if previousSubregionHeading != subregion {
                previousSubregionHeading = subregion
                previousLocalHeading = nil
            } else if previousLocalHeading != local {
                previousLocalHeading = local
            }
            
            dictionary.addEntries(from: propertyDictionary.filter({
                return $0.value != nil
            }) as [AnyHashable : Any])
            dictionary.addEntries(from: correctedLocationDictionary.filter({
                return $0.value != nil
            }) as [AnyHashable : Any])
            index += 1
            return false
        })
        return batchInsertRequest
    }
    
    static func batchImport(from propertiesList: [LightsProperties], taskContext: NSManagedObjectContext) async throws {
        guard !propertiesList.isEmpty else { return }
        
        // Add name and author to identify source of persistent history changes.
        taskContext.name = "importContext"
        taskContext.transactionAuthor = "importLight"
        
        /// - Tag: performAndWait
        try await taskContext.perform {
            // Execute the batch insert.
            /// - Tag: batchInsertRequest
            let batchInsertRequest = Lights.newBatchInsertRequest(with: propertiesList)
            batchInsertRequest.resultType = .count
            do {
                let fetchResult = try taskContext.execute(batchInsertRequest)
                  if let batchInsertResult = fetchResult as? NSBatchInsertResult,
                   let success = batchInsertResult.result as? Int {
                    print("Inserted \(success) lights")
                    return
                  }
            } catch {
                print("error was \(error)")
            }
            throw MSIError.batchInsertError
        }
    }
    
    override var description: String {
        return "LIGHT\n\n" +
        "aidType \(aidType)\n" +
        "characteristic \(characteristic)\n" +
        "characteristicNumber \(characteristicNumber)\n" +
        "deleteFlag \(deleteFlag)\n" +
        "featureNumber \(featureNumber)\n" +
        "geopoliticalHeading \(geopoliticalHeading)\n" +
        "heightFeet \(heightFeet)\n" +
        "heightMeters \(heightMeters)\n" +
        "internationalFeature \(internationalFeature)\n" +
        "localHeading \(localHeading)\n" +
        "name \(name)\n" +
        "noticeNumber \(noticeNumber)\n" +
        "noticeWeek \(noticeWeek)\n" +
        "noticeYear \(noticeYear)\n" +
        "position \(position)\n" +
        "postNote \(postNote)\n" +
        "precedingNote \(precedingNote)\n" +
        "range \(range)\n" +
        "regionHeading \(regionHeading)\n" +
        "remarks \(remarks)\n" +
        "removeFromList \(removeFromList)\n" +
        "structure \(structure)\n" +
        "subregionHeading \(subregionHeading)\n" +
        "volumeNumber \(volumeNumber)"
        
        
//        return "ASAM\n\n" +
//        "Reference: \(reference ?? "")\n" +
//        "Date: \(dateString ?? "")\n" +
//        "Latitude: \(latitude ?? 0.0)\n" +
//        "Longitude: \(longitude ?? 0.0)\n" +
//        "Navigate Area: \(navArea ?? "")\n" +
//        "Subregion: \(subreg ?? "")\n" +
//        "Description: \(asamDescription ?? "")\n" +
//        "Hostility: \(hostility ?? "")\n" +
//        "Victim: \(victim ?? "")\n"
    }
}

struct LightsPropertyContainer: Decodable {
    let ngalol: [LightsProperties]
}

struct LightsProperties: Decodable {
    
    static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter
    }()
    
    // MARK: Codable
    
    private enum CodingKeys: String, CodingKey {
        case volumeNumber
        case aidType
        case geopoliticalHeading
        case regionHeading
        case subregionHeading
        case localHeading
        case precedingNote
        case featureNumber
        case name
        case position
        case charNo
        case characteristic
        case heightFeetMeters
        case range
        case structure
        case remarks
        case postNote
        case noticeNumber
        case removeFromList
        case deleteFlag
        case noticeWeek
        case noticeYear
    }
    
    let aidType: String?
    let characteristic: String?
    let characteristicNumber: Int?
    let deleteFlag: String?
    let featureNumber: String?
    let geopoliticalHeading: String?
    let heightFeet: Float?
    let heightMeters: Float?
    let internationalFeature: String?
    let localHeading: String?
    let name: String?
    let noticeNumber: Int?
    let noticeWeek: String?
    let noticeYear: String?
    let position: String?
    let postNote: String?
    let precedingNote: String?
    let range: String?
    let regionHeading: String?
    let remarks: String?
    let removeFromList: String?
    let structure: String?
    let subregionHeading: String?
    let volumeNumber: String?
//    let sectionHeader: String?
    let latitude: Double?
    let longitude: Double?
//    let lightCharacteristics: Set<LightCaracteristic>
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        // this potentially is US and international feature number combined with a new line
        let rawFeatureNumber = try? values.decode(String.self, forKey: .featureNumber)
        let rawVolumeNumber = try? values.decode(String.self, forKey: .volumeNumber)
        let rawPosition = try? values.decode(String.self, forKey: .position)
        
        guard let featureNumber = rawFeatureNumber,
              let volumeNumber = rawVolumeNumber,
              let position = rawPosition
        else {
            let values = "featureNumber = \(rawFeatureNumber?.description ?? "nil"), "
            + "volumeNumber = \(rawVolumeNumber?.description ?? "nil"), "
            + "position = \(rawPosition?.description ?? "nil")"
            
            let logger = Logger(subsystem: "mil.nga.msi.Marlin", category: "parsing")
            logger.debug("Ignored: \(values)")
            
            throw MSIError.missingData
        }
        
        self.volumeNumber = volumeNumber
        self.position = position
        self.aidType = try? values.decode(String.self, forKey: .aidType)
        self.characteristic = try? values.decode(String.self, forKey: .characteristic)
        self.characteristicNumber = try? values.decode(Int.self, forKey: .charNo)
        self.deleteFlag = try? values.decode(String.self, forKey: .deleteFlag)
        let featureNumberSplit = featureNumber.split(separator: "\n")
        self.featureNumber = "\(featureNumberSplit[0])"
        if featureNumberSplit.count == 2 {
            self.internationalFeature = "\(featureNumberSplit[1])"
        } else {
            self.internationalFeature = nil
        }
        self.geopoliticalHeading = try? values.decode(String.self, forKey: .geopoliticalHeading)
        let heightFeetMeters = try? values.decode(String.self, forKey: .heightFeetMeters)
        let heightFeetMetersSplit = heightFeetMeters?.split(separator: "\n")
        self.heightFeet = Float(heightFeetMetersSplit?[0] ?? "0.0")
        self.heightMeters = Float(heightFeetMetersSplit?[1] ?? "0.0")
        self.localHeading = try? values.decode(String.self, forKey: .localHeading)
        self.name = try? values.decode(String.self, forKey: .name)
        self.noticeNumber = try? values.decode(Int.self, forKey: .noticeNumber)
        self.noticeWeek = try? values.decode(String.self, forKey: .noticeWeek)
        self.noticeYear = try? values.decode(String.self, forKey: .noticeYear)
        self.postNote = try? values.decode(String.self, forKey: .postNote)
        self.precedingNote = try? values.decode(String.self, forKey: .precedingNote)
        self.range = try? values.decode(String.self, forKey: .range)
        if var rawRegionHeading = try? values.decode(String.self, forKey: .regionHeading) {
            if rawRegionHeading.last == ":" {
                rawRegionHeading.removeLast()
            }
            self.regionHeading = rawRegionHeading
        } else {
            self.regionHeading = nil
        }
        self.remarks = try? values.decode(String.self, forKey: .remarks)
        self.removeFromList = try? values.decode(String.self, forKey: .removeFromList)
        self.structure = try? values.decode(String.self, forKey: .structure)
        self.subregionHeading = try? values.decode(String.self, forKey: .subregionHeading)
//        self.sectionHeader = self.geopoliticalHeading
        if let position = self.position {
            let coordinate = LightsProperties.parsePosition(position: position)
            self.longitude = coordinate.longitude
            self.latitude = coordinate.latitude
        } else {
            self.longitude = 0.0
            self.latitude = 0.0
        }
    }
    
    static func parsePosition(position: String) -> CLLocationCoordinate2D {
        var latitude = 0.0
        var longitude = 0.0
        
        let pattern = #"(?<latdeg>[0-9]*)°(?<latminutes>[0-9]*)'(?<latseconds>[0-9]*\.?[0-9]*)\"(?<latdirection>[NS]) \n(?<londeg>[0-9]*)°(?<lonminutes>[0-9]*)'(?<lonseconds>[0-9]*\.?[0-9]*)\"(?<londirection>[EW])"#
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let nsrange = NSRange(position.startIndex..<position.endIndex,
                              in: position)
        if let match = regex?.firstMatch(in: position,
                                        options: [],
                                        range: nsrange)
        {
            for component in ["latdeg", "latminutes", "latseconds", "latdirection"] {
                let nsrange = match.range(withName: component)
                if nsrange.location != NSNotFound,
                   let range = Range(nsrange, in: position)
                {
                    if component == "latdeg" {
                        latitude = Double(position[range]) ?? 0.0
                    } else if component == "latminutes" {
                        latitude += (Double(position[range]) ?? 0.0) / 60
                    } else if component == "latseconds" {
                        latitude += (Double(position[range]) ?? 0.0) / 3600
                    } else if component == "latdirection", position[range] == "S" {
                        latitude *= -1
                    }
                    print("\(component): \(position[range])")
                }
            }
            for component in ["londeg", "lonminutes", "lonseconds", "londirection"] {
                let nsrange = match.range(withName: component)
                if nsrange.location != NSNotFound,
                   let range = Range(nsrange, in: position)
                {
                    if component == "londeg" {
                        longitude = Double(position[range]) ?? 0.0
                    } else if component == "lonminutes" {
                        longitude += (Double(position[range]) ?? 0.0) / 60
                    } else if component == "lonseconds" {
                        longitude += (Double(position[range]) ?? 0.0) / 3600
                    } else if component == "londirection", position[range] == "W" {
                        longitude *= -1
                    }
                    print("\(component): \(position[range])")
                }
            }
        }
        
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    // The keys must have the same name as the attributes of the Lights entity.
    var dictionaryValue: [String: Any?] {
        [
            "aidType": aidType,
            "characteristic": characteristic,
            "characteristicNumber": characteristicNumber,
            "deleteFlag": deleteFlag,
            "featureNumber": featureNumber,
            "geopoliticalHeading": geopoliticalHeading,
            "heightFeet": heightFeet,
            "heightMeters": heightMeters,
            "internationalFeature": internationalFeature,
            "localHeading": localHeading,
            "name": name,
            "noticeNumber": noticeNumber,
            "noticeWeek": noticeWeek,
            "noticeYear": noticeYear,
            "position": position,
            "postNote": postNote,
            "precedingNote": precedingNote,
            "range": range,
            "regionHeading": regionHeading,
            "remarks": remarks,
            "removeFromList": removeFromList,
            "structure": structure,
            "subregionHeading": subregionHeading,
            "volumeNumber": volumeNumber,
            "latitude": latitude,
            "longitude": longitude
//            ,
//            "sectionHeader": sectionHeader
        ]
    }
}

