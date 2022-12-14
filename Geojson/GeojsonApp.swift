//
//  GeojsonApp.swift
//  Geojson
//
//  Created by Jack Finnis on 19/11/2022.
//

import SwiftUI

let NAME = "GeoJSON Viewer"
let SIZE = 48.0
let EMAIL = "jack.finnis@icloud.com"
let APP_URL = URL(string: "https://apps.apple.com/app/id6444589175")!

@main
struct GeojsonApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
