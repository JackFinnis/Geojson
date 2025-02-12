//
//  Polygon.swift
//  Geojson
//
//  Created by Jack Finnis on 07/02/2025.
//

import Foundation
import MapKit
import GoogleMapsUtils

struct Polygon {
    let mkPolygon: MKPolygon
    let color: UIColor?
}

extension Polygon {
    init(polygon: GMUPolygon, style: GMUStyle?) {
        let exteriorCoords = polygon.paths.first?.coords ?? []
        let interiorCoords = polygon.paths.dropFirst().map(\.coords)
        let mkPolygon = MKPolygon(exteriorCoords: exteriorCoords, interiorCoords: interiorCoords)
        self.init(mkPolygon: mkPolygon, color: style?.strokeColor ?? style?.fillColor)
    }
    
    init(mkPolygon: MKPolygon, properties: Properties?) {
        self.init(mkPolygon: mkPolygon, color: properties?.color_)
    }
}

class MultiPolygon: NSObject {
    let mkMultiPolygon: MKMultiPolygon
    let color: UIColor?
    
    init(mkMultiPolygon: MKMultiPolygon, color: UIColor?) {
        self.mkMultiPolygon = mkMultiPolygon
        self.color = color
    }
}

extension MultiPolygon: MKOverlay {
    var coordinate: CLLocationCoordinate2D { mkMultiPolygon.coordinate }
    var boundingMapRect: MKMapRect { mkMultiPolygon.boundingMapRect }
}
