//
//  RootView.swift
//  Paddle
//
//  Created by Jack Finnis on 11/09/2022.
//

import SwiftUI

struct RootView: View {
    @StateObject var vm = ViewModel()
    @AppStorage("launchedBefore") var launchedBefore = false
    
    @State var showWelcomeView = false
    @State var showFileImporter = false
    @State var firstLaunch = false
    @State var shouldShowFileImporter = false
    
    var body: some View {
        ZStack {
            MapView()
                .ignoresSafeArea()
                .alert("Importing Files", isPresented: $vm.showExtensionAlert) {
                    Button("OK", role: .cancel) {
                        showFileImporter = true
                    }
                } message: {
                    Text("Please ensure the file you want to import has the extension .json, not .geojson")
                }
            
            VStack(spacing: 0) {
                Blur()
                    .ignoresSafeArea()
                Spacer()
                    .layoutPriority(1)
            }
            .alert("Import Failed", isPresented: $vm.showFailedAlert) {
                Button("OK", role: .cancel) {}
                if vm.error == .invalidGeojosn {
                    Button("Open Website") {
                        UIApplication.shared.open(URL(string: "https://geojson.io")!)
                    }
                }
            } message: {
                Text(vm.error.rawValue)
            }
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    FloatingButtons(showFileImporter: $showFileImporter, showWelcomeView: $showWelcomeView)
                }
            }
            .alert("Access Denied", isPresented: $vm.showAuthAlert) {
                Button("Close") {}
                Button("Settings") {
                    vm.openSettings()
                }
            } message: {
                Text("\(NAME) needs access to your location to show you where you are on the map. Please grant access in Settings.")
            }
        }
        .environmentObject(vm)
        .task {
            if !launchedBefore {
                launchedBefore = true
                firstLaunch = true
                showWelcomeView = true
            } else if let url = vm.recentURLs.last {
                vm.importData(from: url)
            }
        }
        .sheet(isPresented: $showWelcomeView, onDismiss: {
            showFileImporter = shouldShowFileImporter
            shouldShowFileImporter = false
            firstLaunch = false
        }) {
            WelcomeView(shouldShowFileImporter: $shouldShowFileImporter, firstLaunch: firstLaunch)
        }
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.json, .plainText]) { result in
            switch result {
            case .success(let url):
                vm.importData(from: url)
            case .failure(let error):
                debugPrint(error)
            }
        }
    }
}
