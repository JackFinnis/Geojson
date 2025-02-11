//
//  Polygon.swift
//  Geojson
//
//  Created by Jack Finnis on 07/02/2025.
//

import Foundation
import MapKit

class Polygon: NSObject {
    let mkPolygon: MKPolygon
    let color: UIColor?
    
    init(mkPolygon: MKPolygon, properties: Properties?) {
        self.mkPolygon = mkPolygon
        self.color = properties?.color?.hexColor ?? properties?.colour?.hexColor
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
