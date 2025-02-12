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

struct Polyline {
    let mkPolyline: MKPolyline
    let color: UIColor?
}

extension Polyline {
    init(route: GPXRoute) {
        let coords = route.points.compactMap(\.coord)
        let mkPolyline = MKPolyline(coords: coords)
        self.init(mkPolyline: mkPolyline, color: nil)
    }
    
    init(segment: GPXTrackSegment) {
        let coords = segment.points.compactMap(\.coord)
        let mkPolyline = MKPolyline(coords: coords)
        self.init(mkPolyline: mkPolyline, color: nil)
    }
    
    init(mkPolyline: MKPolyline, properties: Properties?) {
        self.init(mkPolyline: mkPolyline, color: properties?.color_)
    }
    
    init(line: GMULineString, style: GMUStyle?) {
        let mkPolyline = MKPolyline(coords: line.path.coords)
        self.init(mkPolyline: mkPolyline, color: style?.strokeColor)
    }
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
