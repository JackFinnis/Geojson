//
//  GeoError.swift
//  Geojson
//
//  Created by Jack Finnis on 08/05/2023.
//

import Foundation

enum GeoError: Error {
    case unknown
    case fileType
    case fileCorrupted
    case fileEmpty
    case fileManager
    case invalidGeoJSON
    case invalidGPX
    case invalidKML
    case internet
    
    var description: String {
        switch self {
        case .unknown:
            return "An unknown error occured. Please try again later."
        case .fileType:
            return "This file has an invalid file type. Only files with the following file extensions can be imported: .json, .geojson, .gpx, .kml, .kmz"
        case .fileCorrupted:
            return "This file cannot be read. Try importing it again."
        case .fileEmpty:
            return "This file contains no points, lines or shapes."
        case .fileManager:
            return "An error occured with saving this file. Try importing it again."
        case .invalidGeoJSON:
            return "This file contains invalid GeoJSON data."
        case .invalidGPX:
            return "This file contains invalid GPX data."
        case .invalidKML:
            return "This file contains invalid KML data"
        case .internet:
            return "Check your internet connection and try again."
        }
    }
}
