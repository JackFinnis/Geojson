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

struct Polyline: Annotation {
    let mkPolyline: MKPolyline
    let color: UIColor?
    let properties: Properties
}

extension Polyline {
    init(route: GPXRoute) {
        let coords = route.points.compactMap(\.coord)
        let mkPolyline = MKPolyline(coords: coords)
        self.init(mkPolyline: mkPolyline, color: nil, properties: route.properties)
    }
    
    init(segment: GPXTrackSegment) {
        let coords = segment.points.compactMap(\.coord)
        let mkPolyline = MKPolyline(coords: coords)
        self.init(mkPolyline: mkPolyline, color: nil, properties: .empty)
    }
    
    init(mkPolyline: MKPolyline, properties: Properties?) {
        self.init(mkPolyline: mkPolyline, color: properties?.color, properties: properties ?? .empty)
    }
    
    init(line: GMULineString, placemark: GMUPlacemark, style: GMUStyle?) {
        let mkPolyline = MKPolyline(coords: line.path.coords)
        self.init(mkPolyline: mkPolyline, color: style?.strokeColor, properties: placemark.properties)
    }
}

class MultiPolyline: NSObject {
    let mkMultiPolyline: MKMultiPolyline
    let polylines: [Polyline]
    let color: UIColor?
    
    init(color: UIColor?, polylines: [Polyline]) {
        self.mkMultiPolyline = MKMultiPolyline(polylines.map(\.mkPolyline))
        self.polylines = polylines
        self.color = color
    }
}

extension MultiPolyline: MKOverlay {
    var coordinate: CLLocationCoordinate2D { mkMultiPolyline.coordinate }
    var boundingMapRect: MKMapRect { mkMultiPolyline.boundingMapRect }
}
