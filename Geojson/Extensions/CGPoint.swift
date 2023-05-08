//
//  CGPoint.swift
//  Geojson
//
//  Created by Jack Finnis on 08/05/2023.
//

import Foundation
import CoreLocation

extension CGPoint {
    var coord: CLLocationCoordinate2D {
        CLLocationCoordinate2DMake(x, y)
    }
}
