//
//  KMLCoordinate.swift
//  Geojson
//
//  Created by Jack Finnis on 08/05/2023.
//

import Foundation
import RCKML
import CoreLocation

extension KMLCoordinate {
    var coord: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
