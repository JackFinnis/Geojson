//
//  Polygon.swift
//  Geojson
//
//  Created by Jack Finnis on 07/02/2025.
//

import Foundation
import MapKit
import GoogleMapsUtils

class Polygon: NSObject {
    let mkPolygon: MKPolygon
    let color: UIColor?
    
    private init(mkPolygon: MKPolygon, color: UIColor?) {
        self.mkPolygon = mkPolygon
        self.color = color
    }
}

extension Polygon {
    convenience init(mkPolygon: MKPolygon) {
        self.init(mkPolygon: mkPolygon, color: nil)
    }
    
    convenience init(polygon: GMUPolygon, style: GMUStyle?) {
        let exteriorCoords = polygon.paths.first?.coords ?? []
        let interiorCoords = polygon.paths.dropFirst().map(\.coords)
        let mkPolygon = MKPolygon(exteriorCoords: exteriorCoords, interiorCoords: interiorCoords)
        self.init(mkPolygon: mkPolygon, color: style?.strokeColor ?? style?.fillColor)
    }
    
    convenience init(mkPolygon: MKPolygon, properties: Properties?) {
        self.init(mkPolygon: mkPolygon, color: properties?.color_)
    }
}

extension Polygon: MKOverlay {
    var coordinate: CLLocationCoordinate2D { mkPolygon.coordinate }
    var boundingMapRect: MKMapRect { mkPolygon.boundingMapRect }
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
