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

class Point: NSObject, Annotation {
    let coordinate: CLLocationCoordinate2D
    let strings: [String]
    let color: UIColor?
    
    var isDroppedPin: Bool {
        title == Self.droppedPinTitle
    }
    
    static let droppedPinTitle = "Dropped Pin"
    
    private init(coordinate: CLLocationCoordinate2D, strings: [String], color: UIColor?) {
        self.coordinate = coordinate
        self.strings = strings
        self.color = color
    }
    
    func openInMaps() async throws {
        guard let placemark = try await CLGeocoder().reverseGeocodeLocation(coordinate.location).first else { return }
        let mapItem = MKMapItem(placemark: MKPlacemark(placemark: placemark))
        mapItem.name = title ?? mapItem.name
        mapItem.openInMaps()
    }
}

extension Point: MKAnnotation {
    var title: String? { strings[safe: 0] }
    var subtitle: String? { strings[safe: 1] }
}

extension Point {
    static func droppedPin(coordindate: CLLocationCoordinate2D) -> Point {
        Point(coordinate: coordindate, strings: [Self.droppedPinTitle], color: nil)
    }
    
    convenience init?(waypoint: GPXWaypoint) {
        guard let coord = waypoint.coord else { return nil }
        self.init(coordinate: coord, strings: waypoint.strings, color: nil)
    }
    
    convenience init(point: GMUPoint, placemark: GMUPlacemark, style: GMUStyle?) {
        self.init(coordinate: point.coordinate, strings: placemark.strings, color: style?.fillColor)
    }
    
    convenience init(coordinate: CLLocationCoordinate2D, properties: Properties?) {
        self.init(coordinate: coordinate, strings: properties?.strings ?? [], color: properties?.color)
    }
}
