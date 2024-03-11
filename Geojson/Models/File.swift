//
//  GeoData.swift
//  Geojson
//
//  Created by Jack Finnis on 10/03/2024.
//

import Foundation
import MapKit

struct File: Hashable {
    let points: [Point]
    let polylines: [MKPolyline]
    let polygons: [MKPolygon]
    
    var empty: Bool { points.isEmpty && polylines.isEmpty && polygons.isEmpty }
    var multipleTypes: Bool { [points.isNotEmpty, polylines.isNotEmpty, polygons.isNotEmpty].filter { $0 }.count > 1 }
}
