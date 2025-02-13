//
//  Overlay.swift
//  Geojson
//
//  Created by Jack Finnis on 12/02/2025.
//

import MapKit

class Annotation: NSObject {
    let coordinate: CLLocationCoordinate2D
    let properties: Properties
    let color: UIColor?
    
    init(coordinate: CLLocationCoordinate2D, properties: Properties, color: UIColor?) {
        self.coordinate = coordinate
        self.properties = properties
        self.color = color
    }
}

extension Annotation: MKAnnotation {
    var title: String? { properties.title }
    var subtitle: String? { properties.subtitle }
}
