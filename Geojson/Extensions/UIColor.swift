//
//  Color.swift
//  Geojson
//
//  Created by Jack Finnis on 07/02/2025.
//

import SwiftUI

extension UIColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if hexSanitized.hasPrefix("#") {
            hexSanitized.removeFirst()
        }
        
        if hexSanitized.count == 6 || hexSanitized.count == 8 {
            var rgb: UInt64 = 0
            Scanner(string: hexSanitized).scanHexInt64(&rgb)
            
            if hexSanitized.count == 6 {
                self.init(
                    red: Double((rgb & 0xFF0000) >> 16) / 255.0,
                    green: Double((rgb & 0x00FF00) >> 8) / 255.0,
                    blue: Double(rgb & 0x0000FF) / 255.0,
                    alpha: 1
                )
            } else if hexSanitized.count == 8 {
                self.init(
                    red: Double((rgb & 0xFF000000) >> 24) / 255.0,
                    green: Double((rgb & 0x00FF0000) >> 16) / 255.0,
                    blue: Double((rgb & 0x0000FF00) >> 8) / 255.0,
                    alpha: Double(rgb & 0x000000FF) / 255.0
                )
            }
        }
        
        return nil
    }
}
