//
//  GeoShapeType.swift
//  Geojson
//
//  Created by Jack Finnis on 08/05/2023.
//

import Foundation

enum GeoShapeType: String, CaseIterable {
    case point = "Points"
    case polygon = "Polygons"
    case polyline = "Polylines"
}
