//
//  Properties.swift
//  Geojson
//
//  Created by Jack Finnis on 12/02/2025.
//

import SwiftUI

struct Properties {
    let dict: [String : Any]
    
    var title: String? {
        getStrings("title", "name").first
    }
    var subtitle: String? {
        getStrings("subtitle", "description", "address").first
    }
    var color: UIColor? {
        getStrings("color", "colour").first?.hexColor
    }
    
    func getString(_ key: String) -> String? {
        dict[key] as? String
    }
    func getStrings(_ keys: String...) -> [String] {
        keys.compactMap(getString)
    }
    
    static var empty: Properties {
        .init(dict: [:])
    }
}
