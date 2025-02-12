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
    var properties: Properties {
        var dict: [String : Any] = [:]
        dict["Name"] = name
        dict["Comment"] = comment
        dict["Description"] = desc
        return .init(dict: dict)
    }
}
