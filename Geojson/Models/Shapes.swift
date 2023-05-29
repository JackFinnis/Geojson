//
//  Point.swift
//  Geojson
//
//  Created by Jack Finnis on 11/05/2023.
//

import Foundation
import MapKit
import CoreGPX
import RCKML

class Point: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    var index: Int?
    
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }
    
    init?(i: Int, waypoint: GPXWaypoint) {
        guard let coord = waypoint.coord else { return nil }
        coordinate = coord
        title = waypoint.name
        subtitle = waypoint.desc ?? waypoint.comment
        index = i
    }
    
    init(point: KMLPoint, placemark: KMLPlacemark) {
        coordinate = point.coordinate.coord
        title = placemark.name
        subtitle = placemark.featureDescription
    }
}

extension MKPolygon {
    convenience init(exteriorCoords: [CLLocationCoordinate2D], interiorCoords: [[CLLocationCoordinate2D]]?) {
        self.init(coordinates: exteriorCoords, count: exteriorCoords.count, interiorPolygons: interiorCoords?.map { coords in
            MKPolygon(coordinates: coords, count: coords.count)
        })
    }
}

extension MKPolyline {
    convenience init(coords: [CLLocationCoordinate2D]) {
        self.init(coordinates: coords, count: coords.count)
    }
}
