//
//  AppDelegate.swift
//  Geojson
//
//  Created by Jack Finnis on 28/07/2023.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        //todo necessary?
        if let url = launchOptions?[.url] as? URL {
            AppState.shared.importFile(url: url)
        }
        
        return true
    }
}
