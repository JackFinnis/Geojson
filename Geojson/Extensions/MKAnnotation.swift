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
        if let title, let title, title.isNotEmpty {
            if let subtitle, let subtitle, subtitle.isNotEmpty {
                return "\(title)\n\(subtitle)"
            } else {
                return title
            }
        } else {
            return nil
        }
    }
}
