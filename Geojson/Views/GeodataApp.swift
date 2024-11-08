//
//  GeojsonApp.swift
//  Geojson
//
//  Created by Jack Finnis on 19/11/2022.
//

import SwiftUI
import SwiftData

// https://cycling.data.tfl.gov.uk/CycleRoutes/CycleRoutes.json
// polyline colour/width
// polyline properties eg name
// edit/add/delete data

@main
struct GeodataApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: File.self)
    }
}
