//
//  Polyline.swift
//  Geojson
//
//  Created by Jack Finnis on 07/02/2025.
//

import Foundation
import MapKit
import GoogleMapsUtils
import CoreGPX

class Polyline: NSObject {
    let mkPolyline: MKPolyline
    let color: UIColor?
    
    private init(mkPolyline: MKPolyline, color: UIColor?) {
        self.mkPolyline = mkPolyline
        self.color = color
    }
}

extension Polyline {
    convenience init(route: GPXRoute) {
        let coords = route.points.compactMap(\.coord)
        let mkPolyline = MKPolyline(coords: coords)
        self.init(mkPolyline: mkPolyline, color: nil)
    }
    
    convenience init(segment: GPXTrackSegment) {
        let coords = segment.points.compactMap(\.coord)
        let mkPolyline = MKPolyline(coords: coords)
        self.init(mkPolyline: mkPolyline, color: nil)
    }
    
    convenience init(mkPolyline: MKPolyline, properties: Properties?) {
        self.init(mkPolyline: mkPolyline, color: properties?.color_)
    }
    
    convenience init(line: GMULineString, style: GMUStyle?) {
        let mkPolyline = MKPolyline(coords: line.path.coords)
        self.init(mkPolyline: mkPolyline, color: style?.strokeColor)
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
