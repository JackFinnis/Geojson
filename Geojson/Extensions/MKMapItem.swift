//
//  MKMapItem.swift
//  Visited
//
//  Created by Jack Finnis on 25/07/2023.
//

import MapKit

extension MKMapItem: MKAnnotation {
    public var coordinate: CLLocationCoordinate2D { placemark.coordinate }
    public var title: String? { placemark.name }
    public var subtitle: String? { placemark.subLocality ?? placemark.locality ?? "" }
}
