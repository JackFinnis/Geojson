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

class Point: NSObject, Annotation, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let properties: Properties
    let index: Int?
    let title: String?
    let subtitle: String?
    let color: UIColor?
    
    var isDroppedPin: Bool {
        title == Self.droppedPinTitle
    }
    
    static let droppedPinTitle = "Dropped Pin"
    
    init(coordinate: CLLocationCoordinate2D, properties: Properties?, index: Int?, title: String?, subtitle: String?, color: UIColor?) {
        self.coordinate = coordinate
        self.properties = properties ?? .empty
        self.index = index
        self.title = title
        self.subtitle = subtitle
        self.color = color
    }
    
    func openInMaps() async throws {
        guard let placemark = try await CLGeocoder().reverseGeocodeLocation(coordinate.location).first else { return }
        let mapItem = MKMapItem(placemark: MKPlacemark(placemark: placemark))
        mapItem.name = title ?? mapItem.name
        mapItem.openInMaps()
    }
}

extension Point {
    static func droppedPin(coordindate: CLLocationCoordinate2D) -> Point {
        Point(coordinate: coordindate, properties: nil, index: nil, title: Self.droppedPinTitle, subtitle: nil, color: nil)
    }
    
    convenience init?(waypoint: GPXWaypoint) {
        guard let coord = waypoint.coord else { return nil }
        var strings = [waypoint.name, waypoint.symbol, waypoint.comment, waypoint.desc].compactMap(\.self)
        let index = strings.map(Int.init).first ?? nil
        strings = strings.filter { Int($0) == nil }
        self.init(coordinate: coord, properties: waypoint.properties, index: index, title: strings.first, subtitle: strings.second, color: nil)
    }
    
    convenience init(point: GMUPoint, placemark: GMUPlacemark, style: GMUStyle?) {
        self.init(coordinate: point.coordinate, properties: placemark.properties, index: nil, title: placemark.title, subtitle: placemark.snippet, color: style?.fillColor)
    }
    
    convenience init(coordinate: CLLocationCoordinate2D, properties: Properties?) {
        self.init(coordinate: coordinate, properties: properties, index: nil, title: properties?.title, subtitle: properties?.subtitle, color: properties?.color)
    }
}
