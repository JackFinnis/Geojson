//
//  FloatingButtons.swift
//  Paddle
//
//  Created by Jack Finnis on 11/09/2022.
//

import SwiftUI
import MapKit

struct FloatingButtons: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var vm: ViewModel
    @Binding var showFileImporter: Bool
    @Binding var showWelcomeView: Bool
    
    var background: Material { colorScheme == .light ? .regularMaterial : .thickMaterial }
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 0) {
                Button {
                    showWelcomeView = true
                } label: {
                    Image(systemName: "info.circle")
                        .frame(width: SIZE, height: SIZE)
                }
                
                Divider().frame(width: SIZE)
                
                Button {
                    showFileImporter = true
                } label: {
                    Image(systemName: "square.and.arrow.down")
                        .frame(width: SIZE, height: SIZE)
                }
            }
            .background(background)
            .cornerRadius(10)
            
            VStack(spacing: 0) {
                Button {
                    updateTrackingMode()
                } label: {
                    Image(systemName: trackingModeImage)
                        .frame(width: SIZE, height: SIZE)
                }
                
                Divider().frame(width: SIZE)
                
                Button {
                    updateMapType()
                } label: {
                    Image(systemName: mapTypeImage)
                        .frame(width: SIZE, height: SIZE)
                }
            }
            .background(background)
            .cornerRadius(10)
        }
        .font(.system(size: SIZE/2))
        .compositingGroup()
        .shadow(color: Color(.systemFill), radius: 5)
        .padding(10)
    }
    
    func updateTrackingMode() {
        if vm.authorized {
            vm.trackingMode = vm.trackingMode == .none ? .follow : .none
        } else {
            vm.showAuthAlert = true
        }
    }
    
    func updateMapType() {
        vm.mapType = vm.mapType == .standard ? .hybrid : .standard
    }
    
    var trackingModeImage: String {
        vm.trackingMode == .none ? "location" : "location.fill"
    }
    
    var mapTypeImage: String {
        vm.mapType == .standard ? "globe.europe.africa.fill" : "map"
    }
}
