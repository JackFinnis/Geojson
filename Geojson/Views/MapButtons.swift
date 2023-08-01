//
//  FloatingButtons.swift
//  Paddle
//
//  Created by Jack Finnis on 11/09/2022.
//

import SwiftUI
import MapKit

struct MapButtons: View {
    @EnvironmentObject var vm: ViewModel
    @State var showInfoView = false
    
    var body: some View {
        VStack(spacing: 10) {
            VStack(spacing: 0) {
                Button {
                    showInfoView.toggle()
                } label: {
                    Image(systemName: "info.circle")
                        .squareButton()
                }
                
                Divider().frame(width: Constants.size)
                Button {
                    updateMapType()
                } label: {
                    Image(systemName: mapTypeImage)
                        .squareButton()
                        .rotation3DEffect(.degrees(vm.mapType == .standard ? 0 : 180), axis: (x: 0, y: 1, z: 0))
                        .rotation3DEffect(.degrees(vm.degrees), axis: (x: 0, y: 1, z: 0))
                }
                
                Divider().frame(width: Constants.size)
                Button {
                    updateTrackingMode()
                } label: {
                    Image(systemName: trackingModeImage)
                        .scaleEffect(vm.scale)
                        .squareButton()
                }
            }
            .blurBackground()
            
            if vm.multipleTypes {
                Menu {
                    Picker("", selection: $vm.selectedShapeType) {
                        Text("No Filter")
                            .tag(nil as GeoShapeType?)
                        ForEach(GeoShapeType.allCases, id: \.self) { type in
                            let text = Text(type.rawValue).tag(type as GeoShapeType?)
                            switch type {
                            case .point:
                                if vm.points.isNotEmpty { text }
                            case .polygon:
                                if vm.polygons.isNotEmpty { text }
                            case .polyline:
                                if vm.polylines.isNotEmpty { text }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle\(vm.selectedShapeType == nil ? "" : ".fill")")
                        .squareButton()
                }
                .blurBackground()
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.default, value: vm.multipleTypes)
        .padding(10)
        .sheet(isPresented: $showInfoView) {
            InfoView(isPresented: $showInfoView, welcome: false)
        }
        .alert("Access Denied", isPresented: $vm.showAuthAlert) {
            Button("Maybe Later") {}
            Button("Settings", role: .cancel) {
                vm.openSettings()
            }
        } message: {
            Text("\(Constants.name) needs access to your location to show where you are on the map. Please go to Settings > \(Constants.name) > Location and allow access while using the app.")
        }
    }
    
    func updateTrackingMode() {
        var mode: MKUserTrackingMode {
            switch vm.trackingMode {
            case .none:
                return .follow
            case .follow:
                return .followWithHeading
            default:
                return .none
            }
        }
        vm.updateTrackingMode(mode)
    }
    
    func updateMapType() {
        var type: MKMapType {
            switch vm.mapType {
            case .standard:
                return .hybrid
            default:
                return .standard
            }
        }
        vm.updateMapType(type)
    }
    
    var trackingModeImage: String {
        switch vm.trackingMode {
        case .none:
            return "location"
        case .follow:
            return "location.fill"
        default:
            return "location.north.line.fill"
        }
    }
    
    var mapTypeImage: String {
        switch vm.mapType {
        case .standard:
            return "globe.europe.africa.fill"
        default:
            return "map"
        }
    }
}
