//
//  RootView.swift
//  Paddle
//
//  Created by Jack Finnis on 11/09/2022.
//

import SwiftUI

struct RootView: View {
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.colorScheme) var colorScheme
    @StateObject var vm = ViewModel.shared
    @AppStorage("launchedBefore") var launchedBefore = false
    @State var showWelcomeView = false
    
    var body: some View {
        ZStack(alignment: .trailing) {
            MapView()
                .ignoresSafeArea()
            
            VStack {
                CarbonCopy()
                    .id(scenePhase)
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
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                vm.updateBookmarks()
            }
        }
        .onChange(of: colorScheme) { newScheme in
            vm.refreshFeatures()
        }
        .onOpenURL { url in
            vm.importFile(url: url, canShowAlert: true)
        }
        .sheet(isPresented: $showWelcomeView) {
            InfoView(isPresented: $showWelcomeView, welcome: true)
        }
        .environmentObject(vm)
    }
}
