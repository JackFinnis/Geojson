//
//  MKAnnotation.swift
//  Geojson
//
//  Created by Jack Finnis on 05/07/2024.
//

import Foundation
import MapKit

extension MKAnnotation {
    var name: String? {
        guard let title, let title, title.isNotEmpty else { return nil }
        guard let subtitle, let subtitle, subtitle.isNotEmpty else { return title }
        return title + "\n" + subtitle
    }
}
