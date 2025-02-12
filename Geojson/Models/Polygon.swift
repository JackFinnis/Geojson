//
//  Polygon.swift
//  Geojson
//
//  Created by Jack Finnis on 07/02/2025.
//

import Foundation
import MapKit
import GoogleMapsUtils

struct Polygon: Annotation {
    let mkPolygon: MKPolygon
    let color: UIColor?
    let properties: Properties
}

extension Polygon {
    init(polygon: GMUPolygon, placemark: GMUPlacemark, style: GMUStyle?) {
        let exteriorCoords = polygon.paths.first?.coords ?? []
        let interiorCoords = polygon.paths.dropFirst().map(\.coords)
        let mkPolygon = MKPolygon(exteriorCoords: exteriorCoords, interiorCoords: interiorCoords)
        self.init(mkPolygon: mkPolygon, color: style?.strokeColor ?? style?.fillColor, properties: placemark.properties)
    }
    
    init(mkPolygon: MKPolygon, properties: Properties?) {
        self.init(mkPolygon: mkPolygon, color: properties?.color, properties: properties ?? .empty)
    }
}

class MultiPolygon: NSObject {
    let mkMultiPolygon: MKMultiPolygon
    let polygons: [Polygon]
    let color: UIColor?
    
    init(color: UIColor?, polygons: [Polygon]) {
        self.mkMultiPolygon = MKMultiPolygon(polygons.map(\.mkPolygon))
        self.polygons = polygons
        self.color = color
    }
}

extension MultiPolygon: MKOverlay {
    var coordinate: CLLocationCoordinate2D { mkMultiPolygon.coordinate }
    var boundingMapRect: MKMapRect { mkMultiPolygon.boundingMapRect }
}
