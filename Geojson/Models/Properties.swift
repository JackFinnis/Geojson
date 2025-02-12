//
//  Properties.swift
//  Geojson
//
//  Created by Jack Finnis on 12/02/2025.
//

import SwiftUI

struct Properties {
    static var empty: Properties {
        .init(dict: [:])
    }
    
    let dict: [String : Any]
    
    var urls: [URL] {
        dict.values.compactMap { $0 as? String }.compactMap(URL.init)
    }
    
    var string: String {
        dict.map { key, value in
            "\(key): \(value)"
        }.joined(separator: "\n")
    }
    
    var title: String? {
        (dict["title"] ?? dict["name"]) as? String
    }
    
    var subtitle: String? {
        (dict["subtitle"] ?? dict["description"] ?? dict["address"]) as? String
    }
    
    var color: UIColor? {
        ((dict["color"] ?? dict["colour"]) as? String)?.hexColor
    }
}
