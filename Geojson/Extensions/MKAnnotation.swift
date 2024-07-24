//
//  MKAnnotation.swift
//  Geojson
//
//  Created by Jack Finnis on 05/07/2024.
//

import Foundation
import MapKit

extension MKAnnotation {
    var googleURL: URL? {
        guard let query = title??.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
        return URL(string: "https://google.com/search?q=\(query)")
    }
    
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
