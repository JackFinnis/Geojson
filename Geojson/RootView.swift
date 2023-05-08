//
//  RootView.swift
//  Paddle
//
//  Created by Jack Finnis on 11/09/2022.
//

import SwiftUI

struct RootView: View {
    @StateObject var vm = ViewModel.shared
    @AppStorage("launchedBefore") var launchedBefore = false
    @State var showWelcomeView = false
    @State var showFileImporter = false
    
    var body: some View {
        ZStack(alignment: .trailing) {
            MapView()
                .ignoresSafeArea()
            
            VStack {
                CarbonCopy()
                    .blur(radius: 10, opaque: true)
                    .ignoresSafeArea()
                Spacer()
                    .layoutPriority(1)
            }
            
            MapButtons()
            ImportButton(showFileImporter: $showFileImporter)
        }
        .task {
            if !launchedBefore {
                launchedBefore = true
                showWelcomeView = true
            }
            if let url = vm.recentUrls.last {
                vm.importFile(url: url, canShowAlert: false)
            }
        }
        .sheet(isPresented: $showWelcomeView, onDismiss: {
            showFileImporter = true
        }) {
            InfoView(welcome: true)
        }
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.item]) { result in
            switch result {
            case .success(let url):
                vm.importFile(url: url)
            case .failure(let error):
                debugPrint(error)
            }
        }
        .background {
            Text("")
                .alert("Access Denied", isPresented: $vm.showAuthAlert) {
                    Button("Maybe Later") {}
                    Button("Settings", role: .cancel) {
                        vm.openSettings()
                    }
                } message: {
                    Text("\(NAME) needs access to your location to show where you are on the map. Please go to Settings > \(NAME) > Location and allow access while using the app.")
                }
            Text("")
                .alert("Import Failed", isPresented: $vm.showFailedAlert) {
                    Button("OK", role: .cancel) {}
                    if vm.importError == .invalidGeojosn {
                        Button("Open in Safari") {
                            UIApplication.shared.open(URL(string: "https://geojson.io")!)
                        }
                    }
                } message: {
                    Text(vm.importError.rawValue)
                }
        }
        .environmentObject(vm)
    }
}
