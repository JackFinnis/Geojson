//
//  Point.swift
//  Geojson
//
//  Created by Jack Finnis on 11/05/2023.
//

import Foundation
import MapKit
import CoreGPX
import GoogleMapsUtils

class Point: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?
    let index: Int?
    let color: UIColor?
    
    var isDroppedPin: Bool {
        title == Self.droppedPinTitle
    }
    
    var name: String? {
        guard let title, title.isNotEmpty else { return nil }
        guard let subtitle, subtitle.isNotEmpty else { return title }
        return title + "\n" + subtitle
    }
    
    static let droppedPinTitle = "Dropped Pin"
    
    private init(coordinate: CLLocationCoordinate2D, title: String?, subtitle: String?, index: Int?, color: UIColor?) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.index = index
        self.color = color
    }
}

extension Point {
    static func droppedPin(coordindate: CLLocationCoordinate2D) -> Point {
        Point(coordinate: coordindate, title: Self.droppedPinTitle, subtitle: nil, index: nil, color: nil)
    }
    
    convenience init?(waypoint: GPXWaypoint) {
        guard let coord = waypoint.coord else { return nil }
        let info = [waypoint.name, waypoint.symbol, waypoint.comment, waypoint.desc].compactMap(\.self)
        let index = info.map(Int.init).compactMap(\.self).first
        let strings = info.filter { Int($0) == nil }
        self.init(coordinate: coord, title: strings[safe: 0], subtitle: strings[safe: 1], index: index, color: nil)
    }
    
    convenience init(point: GMUPoint, placemark: GMUPlacemark, style: GMUStyle?) {
        self.init(coordinate: point.coordinate, title: placemark.title ?? style?.title, subtitle: placemark.snippet, index: nil, color: style?.fillColor)
    }
    
    convenience init(coordinate: CLLocationCoordinate2D, properties: Properties?) {
        self.init(coordinate: coordinate, title: properties?.title_, subtitle: properties?.subtitle_, index: nil, color: properties?.color_)
    }
}
