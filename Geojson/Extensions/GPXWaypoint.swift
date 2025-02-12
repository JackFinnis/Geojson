//
//  GPX.swift
//  Geojson
//
//  Created by Jack Finnis on 11/05/2023.
//

import Foundation
import CoreGPX
import CoreLocation

extension GPXWaypoint {
    var coord: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    var strings: [String] {
        [name, symbol, comment, desc].compactMap(\.self)
    }
}
