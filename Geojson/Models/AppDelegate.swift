//
//  AppDelegate.swift
//  Geojson
//
//  Created by Jack Finnis on 28/07/2023.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    var vm: ViewModel { .shared }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        Task {
            if let url = launchOptions?[.url] as? URL {
                vm.importFile(url: url, canShowAlert: true)
            } else if let url = vm.recentUrls.last {
                vm.importFile(url: url, canShowAlert: false)
            }
        }
        
        return true
    }
}
