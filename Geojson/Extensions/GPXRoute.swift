//
//  GPXRoute.swift
//  Geojson
//
//  Created by Jack Finnis on 12/02/2025.
//

import Foundation
import CoreGPX
import CoreLocation

extension GPXRoute {
    var strings: [String] {
        [name, comment, desc].compactMap(\.self)
    }
}
