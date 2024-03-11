//
//  GeojsonApp.swift
//  Geojson
//
//  Created by Jack Finnis on 19/11/2022.
//

import SwiftUI

@main
struct GeojsonApp: App {
    @Environment(\.scenePhase) var scenePhase
    @State var app = AppState.shared
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            FilesView()
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        app.updateBookmarks()
                    }
                }
                .onOpenURL { url in
                    app.importFile(url: url)
                }
        }
        .environmentObject(app)
    }
}
