//
//  GeoFileType.swift
//  Geojson
//
//  Created by Jack Finnis on 08/05/2023.
//

import Foundation

enum GeoFileType: String, CaseIterable {
    case geojson = "GeoJSON"
    case gpx = "GPX"
    case shp = "Shapefile"
    case kml = "KML"
    
    init?(fileExtension: String) {
        for type in GeoFileType.allCases {
            if type.fileExtensions.contains(fileExtension) {
                self = type
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
