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

    var body: some View {
        ZStack {
            MapView()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Blur()
                    .ignoresSafeArea()
                Spacer()
                    .layoutPriority(1)
            }
            .alert("Import Failed", isPresented: $vm.showImportFailedAlert) {
                Button("Ok", role: .cancel) {}
            } message: {
                Text("Please ensure this file is valid geojson and try again.")
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
                showWelcomeView = true
            } else{
                showFileImporter = true
            }
        }
        .sheet(isPresented: $showWelcomeView, onDismiss: {
            showFileImporter = true
        }) {
            WelcomeView()
        }
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.json]) { result in
            switch result {
            case .success(let url):
                vm.importData(from: url)
            case .failure(let error):
                debugPrint(error)
            }
        }
    }
}
