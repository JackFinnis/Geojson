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
    case shp = "Shapefile"
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
        case .shp:
            return ["gpx"]
        case .kml:
            return ["kml", "kmx"]
        }
    }
}
