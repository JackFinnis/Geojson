//
//  Properties.swift
//  Geojson
//
//  Created by Jack Finnis on 11/02/2025.
//

import UIKit

struct Properties: Codable {
    private let name: String?
    private let title: String?
    private let address: String?
    private let description: String?
    private let color: String?
    private let colour: String?
    private let strokeColor: String?
    private let strokeColour: String?
    private let fillColor: String?
    private let fillColour: String?
    
    var color_: UIColor? {
        [color, colour, strokeColor, strokeColour, fillColor, fillColour].compactMap(\.self).first?.hexColor
    }
    var title_: String? {
        title ?? name
    }
    var subtitle_: String? {
        description ?? address
    }
}
