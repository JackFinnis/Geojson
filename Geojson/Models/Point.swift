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
    let title: String?
    let subtitle: String?
    let index: Int?
    
    init(coordinate: CLLocationCoordinate2D, title: String? = nil, subtitle: String? = nil, index: Int? = nil) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.index = index
    }
}

extension Point {
    convenience init?(index: Int, waypoint: GPXWaypoint) {
        guard let coord = waypoint.coord else { return nil }
        self.init(coordinate: coord, title: waypoint.name, subtitle: waypoint.desc ?? waypoint.comment, index: index)
    }
    
    convenience init(point: KMLPoint, placemark: KMLPlacemark) {
        if let index = Int(placemark.name) {
            self.init(coordinate: point.coordinate.coord, title: placemark.featureDescription, index: index)
        } else {
            self.init(coordinate: point.coordinate.coord, title: placemark.name, subtitle: placemark.featureDescription)
        }
    }
}
