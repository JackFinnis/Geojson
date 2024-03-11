//
//  Constants.swift
//  Geojson
//
//  Created by Jack Finnis on 20/05/2023.
//

import Foundation

struct Constants {
    static let name = "GeoViewer"
    static let size = 44.0
    static let email = "jack.finnis@icloud.com"
    static let appURL = URL(string: "https://apps.apple.com/app/id6444589175")!
    static let infoItems: [InfoItem] = [
        InfoItem(imageName: "map", title: "Import GPX, KML and GeoJSON", description: "Browse your geodata on a satellite or standard map."),
        InfoItem(imageName: "location.north.line.fill", title: "Track Your Location", description: "Watch you location and heading update live on the map."),
        InfoItem(imageName: "clock.arrow.circlepath", title: "Quickly Open Recent Files", description: "Open files that you have recently imported in just 2 taps.")
    ]
}

struct InfoItem: Hashable {
    let imageName: String
    let title: String
    let description: String
}
