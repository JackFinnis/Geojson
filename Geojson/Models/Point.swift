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
    
    var isDroppedPin: Bool {
        title == "Dropped Pin"
    }
    
    init(coordinate: CLLocationCoordinate2D, title: String? = nil, subtitle: String? = nil, index: Int? = nil) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.index = index
    }
}

extension Point {
    convenience init?(waypoint: GPXWaypoint) {
        guard let coord = waypoint.coord else { return nil }
        let info = [waypoint.name, waypoint.symbol, waypoint.comment, waypoint.desc].compactMap(\.self)
        let index = info.map(Int.init).compactMap(\.self).first
        let strings = info.filter { Int($0) == nil }
        self.init(coordinate: coord, title: strings[safe: 0], subtitle: strings[safe: 1], index: index)
    }
    
    convenience init(point: KMLPoint, placemark: KMLPlacemark) {
        if let index = Int(placemark.name) {
            self.init(coordinate: point.coordinate.coord, title: placemark.featureDescription, index: index)
        } else {
            self.init(coordinate: point.coordinate.coord, title: placemark.name, subtitle: placemark.featureDescription)
        }
    }
    
    convenience init(coordinate: CLLocationCoordinate2D, properties: Properties?) {
        self.init(coordinate: coordinate, title: properties?.title ?? properties?.name, subtitle: properties?.description ?? properties?.address)
    }
}
