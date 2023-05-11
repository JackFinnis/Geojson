//
//  RootView.swift
//  Paddle
//
//  Created by Jack Finnis on 11/09/2022.
//

import SwiftUI

struct RootView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.scenePhase) var scenePhase
    @StateObject var vm = ViewModel.shared
    @AppStorage("launchedBefore") var launchedBefore = false
    @State var showWelcomeView = false
    
    var body: some View {
        ZStack(alignment: .trailing) {
            MapView()
                .ignoresSafeArea()
            
            VStack {
                CarbonCopy()
                    .id(colorScheme)
                    .blur(radius: 10, opaque: true)
                    .ignoresSafeArea()
                Spacer()
                    .layoutPriority(1)
            }
            
            VStack(alignment: .trailing) {
                MapButtons()
                Spacer()
                ImportButton(showInfoView: .constant(false), infoView: false)
                    .padding()
            }
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
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                vm.updateBookmarks()
            }
        }
        .sheet(isPresented: $showWelcomeView) {
            InfoView(isPresented: $showWelcomeView, welcome: true)
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
                    switch vm.geoError {
                    case .invalidGeoJSON:
                        Button("Open in Safari") {
                            UIApplication.shared.open(VALIDATE_URL)
                        }
                    default: EmptyView()
                    }
                } message: {
                    Text(vm.geoError.message)
                }
        }
        .environmentObject(vm)
    }
}
