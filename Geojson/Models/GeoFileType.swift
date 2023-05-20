//
//  GeoFileType.swift
//  Geojson
//
//  Created by Jack Finnis on 08/05/2023.
//

import Foundation

// Format    Seconds
// KML       0.023
// GPX       0.028
// GeoJSON   0.016
enum GeoFileType: String, CaseIterable {
    case geojson = "GeoJSON File"
    case gpx = "GPX File"
    case kml = "KML File"
    
    init?(fileExtension: String) {
        for type in GeoFileType.allCases {
            if type.fileExtensions.contains(fileExtension) {
                self = type
                return
            }
        }
        return nil
    }
    
    var fileExtensions: [String] {
        switch self {
        case .geojson:
            return ["geojson", "json"]
        case .gpx:
            return ["gpx"]
        case .kml:
            return ["kml", "kmz"]
        }
    }
    
    var helpUrl: URL {
        switch self {
        case .geojson:
            return URL(string: "https://geojson.io")!
        case .gpx:
            return URL(string: "https://gpx.studio")!
        case .kml:
            return URL(string: "https://www.google.com/maps/d")!
        }
    }
    
    static var allFileExtensions: [String] {
        Array(allCases.map(\.fileExtensions).joined())
    }
}
