//
//  GeojsonApp.swift
//  Geojson
//
//  Created by Jack Finnis on 19/11/2022.
//

import SwiftUI

@main
struct GeojsonApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
