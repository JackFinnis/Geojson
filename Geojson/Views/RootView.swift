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
        .background {
            Text("")
                .alert("Access Denied", isPresented: $vm.showAuthAlert) {
                    Button("Maybe Later") {}
                    Button("Settings", role: .cancel) {
                        vm.openSettings()
                    }
                } message: {
                    Text("\(Constants.name) needs access to your location to show where you are on the map. Please go to Settings > \(Constants.name) > Location and allow access while using the app.")
                }
            Text("")
                .alert("Import Failed", isPresented: $vm.showFailedAlert) {
                    Button("OK", role: .cancel) {}
                    if let fileType = vm.geoError.fileType {
                        Button("Open Help Website") {
                            UIApplication.shared.open(fileType.helpUrl)
                        }
                    }
                } message: {
                    Text(vm.geoError.message)
                }
        }
        .background {
            Text("")
                .sheet(isPresented: $showWelcomeView) {
                    InfoView(isPresented: $showWelcomeView, welcome: true)
                }
        }
        .environmentObject(vm)
    }
}
