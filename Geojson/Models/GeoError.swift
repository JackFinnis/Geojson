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
    case download
}
