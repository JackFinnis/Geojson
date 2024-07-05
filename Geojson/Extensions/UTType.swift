//
//  UTType.swift
//  Geojson
//
//  Created by Jack Finnis on 05/07/2024.
//

import Foundation
import UniformTypeIdentifiers

extension UTType {
    static let geojson = UTType("public.geojson")!
    static let gpx = UTType("com.topografix.gpx")!
    static let kml = UTType("com.google.earth.kml")!
    static let kmz = UTType("com.google.earth.kmz")!
}
