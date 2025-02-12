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
    let strings: [String]
    
    private init(mkPolyline: MKPolyline, color: UIColor?, strings: [String]) {
        self.mkPolyline = mkPolyline
        self.color = color
        self.strings = strings.sorted(using: SortDescriptor(\.count))
    }
}

extension Polyline {
    init(route: GPXRoute) {
        let coords = route.points.compactMap(\.coord)
        let mkPolyline = MKPolyline(coords: coords)
        self.init(mkPolyline: mkPolyline, color: nil, strings: route.strings)
    }
    
    init(segment: GPXTrackSegment) {
        let coords = segment.points.compactMap(\.coord)
        let mkPolyline = MKPolyline(coords: coords)
        self.init(mkPolyline: mkPolyline, color: nil, strings: [])
    }
    
    init(mkPolyline: MKPolyline, properties: Properties?) {
        self.init(mkPolyline: mkPolyline, color: properties?.color, strings: properties?.strings ?? [])
    }
    
    init(line: GMULineString, placemark: GMUPlacemark, style: GMUStyle?) {
        let mkPolyline = MKPolyline(coords: line.path.coords)
        self.init(mkPolyline: mkPolyline, color: style?.strokeColor, strings: placemark.strings)
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
