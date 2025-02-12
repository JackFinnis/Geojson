//
//  GMUPlacemark.swift
//  Geojson
//
//  Created by Jack Finnis on 12/02/2025.
//

import GoogleMapsUtils

extension GMUPlacemark {
    var strings: [String] {
        [title, snippet].compactMap(\.self)
    }
}
