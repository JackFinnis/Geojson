//
//  Polyline.swift
//  Geojson
//
//  Created by Jack Finnis on 07/02/2025.
//

import Foundation
import MapKit
import GoogleMapsUtils

class Polyline: NSObject {
    let mkPolyline: MKPolyline
    let color: UIColor?
    
    private init(mkPolyline: MKPolyline, color: UIColor?) {
        self.mkPolyline = mkPolyline
        self.color = color
    }
}

extension Polyline {
    convenience init(mkPolyline: MKPolyline) {
        self.init(mkPolyline: mkPolyline, color: nil)
    }
    
    convenience init(mkPolyline: MKPolyline, properties: Properties?) {
        self.init(mkPolyline: mkPolyline, color: properties?.color?.hexColor ?? properties?.colour?.hexColor)
    }
    
    convenience init(mkPolyline: MKPolyline, style: GMUStyle?) {
        self.init(mkPolyline: mkPolyline, color: style?.strokeColor)
    }
}

extension Polyline: MKOverlay {
    var coordinate: CLLocationCoordinate2D { mkPolyline.coordinate }
    var boundingMapRect: MKMapRect { mkPolyline.boundingMapRect }
}

class MultiPolyline: NSObject {
    let mkMultiPolyline: MKMultiPolyline
    let uiColor: UIColor?
    
    init(mkMultiPolyline: MKMultiPolyline, uiColor: UIColor?) {
        self.mkMultiPolyline = mkMultiPolyline
        self.uiColor = uiColor
    }
}

extension MultiPolyline: MKOverlay {
    var coordinate: CLLocationCoordinate2D { mkMultiPolyline.coordinate }
    var boundingMapRect: MKMapRect { mkMultiPolyline.boundingMapRect }
}
