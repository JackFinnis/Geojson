//
//  GeoData.swift
//  Geojson
//
//  Created by Jack Finnis on 10/03/2024.
//

import Foundation
import MapKit

struct GeoData: Hashable {
    let points: [Point]
    let multiPolylines: [MultiPolyline]
    let multiPolygons: [MultiPolygon]
    
    var rect: MKMapRect { multiPolygons.rect.union(multiPolylines.rect).union(points.rect) }
    var empty: Bool { points.isEmpty && multiPolylines.isEmpty && multiPolygons.isEmpty }
    
    @MainActor
    static let empty = GeoData(points: [], multiPolylines: [], multiPolygons: [])
}
