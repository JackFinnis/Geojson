//
//  GeojsonApp.swift
//  Geojson
//
//  Created by Jack Finnis on 19/11/2022.
//

import SwiftUI
import FirebaseCore

let NAME = "GeoViewer"
let SIZE = 44.0
let EMAIL = "jack.finnis@icloud.com"
let APP_URL = URL(string: "https://apps.apple.com/app/id6444589175")!
let VALIDATE_URL = URL(string: "https://geojson.io")!

@main
struct GeojsonApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}
