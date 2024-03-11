//
//  GeoFileType.swift
//  Geojson
//
//  Created by Jack Finnis on 08/05/2023.
//

import Foundation
import UniformTypeIdentifiers

enum GeoFileType: String, CaseIterable {
    case geojson = "GeoJSON"
    case gpx = "GPX"
    case kml = "KML"
    
    init?(fileExtension: String) {
        for type in GeoFileType.allCases where type.fileExtensions.contains(fileExtension) {
            self = type
            return
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
    
    var helpUrlName: String {
        switch self {
        case .geojson:
            return "GeoJSON.io"
        case .gpx:
            return "GPX Studio"
        case .kml:
            return "Google Maps"
        }
    }
    
    static var allFileExtensions: [String] {
        Array(allCases.map(\.fileExtensions).joined())
    }
    
    static let allUTTypes: [UTType] = [
        .json,
        UTType("com.jackfinnis.geojson")!,
        UTType("com.jackfinnis.gpx")!,
        UTType("com.jackfinnis.kml")!,
        UTType("com.jackfinnis.kmz")!
    ]
}
