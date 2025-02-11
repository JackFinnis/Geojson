//
//  Polyline.swift
//  Geojson
//
//  Created by Jack Finnis on 07/02/2025.
//

import Foundation
import MapKit

class Polyline: NSObject {
    let mkPolyline: MKPolyline
    let color: UIColor?
    
    init(mkPolyline: MKPolyline, properties: Properties?) {
        self.mkPolyline = mkPolyline
        self.color = properties?.color?.hexColor ?? properties?.colour?.hexColor
    }
}

extension Polyline: MKOverlay {
    var coordinate: CLLocationCoordinate2D { mkPolyline.coordinate }
    var boundingMapRect: MKMapRect { mkPolyline.boundingMapRect }
}

class MultiPolyline: NSObject {
    let mkMultiPolyline: MKMultiPolyline
    let color: UIColor?
    
    init(mkMultiPolyline: MKMultiPolyline, color: UIColor?) {
        self.mkMultiPolyline = mkMultiPolyline
        self.color = color
    }
}

extension MultiPolyline: MKOverlay {
    var coordinate: CLLocationCoordinate2D { mkMultiPolyline.coordinate }
    var boundingMapRect: MKMapRect { mkMultiPolyline.boundingMapRect }
}
