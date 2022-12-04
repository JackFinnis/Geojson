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
                
                if vm.recentURLs.isEmpty {
                    Button {
                        showFileImporterTapped()
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                            .frame(width: SIZE, height: SIZE)
                    }
                } else {
                    Menu {
                        Button {
                            showFileImporterTapped()
                        } label: {
                           Label("Import GeoJSON File", systemImage: "doc.badge.plus")
                        }
                        Divider()
                        ForEach(vm.recentURLs, id: \.self) { url in
                            Button(url.lastPathComponent.replacingOccurrences(of: "%20", with: " ")) {
                                vm.importData(from: url, allowAlert: true)
                            }
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                            .frame(width: SIZE, height: SIZE)
                    }
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
                        .scaleEffect(vm.scale)
                }
                
                Divider().frame(width: SIZE)
                
                Button {
                    updateMapType()
                } label: {
                    Image(systemName: mapTypeImage)
                        .frame(width: SIZE, height: SIZE)
                        .rotation3DEffect(.degrees(vm.mapType == .standard ? 0 : 180), axis: (x: 0, y: 1, z: 0))
                        .rotation3DEffect(.degrees(vm.degrees), axis: (x: 0, y: 1, z: 0))
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
    
    func showFileImporterTapped() {
        if #available(iOS 16, *) {
            showFileImporter = true
        } else if vm.showedExtensionAlert {
            showFileImporter = true
        } else {
            vm.showExtensionAlert = true
            vm.showedExtensionAlert = true
        }
    }
    
    func updateTrackingMode() {
        if !vm.authorized {
            vm.showAuthAlert = true
        } else {
            let nextTrackingMode: MKUserTrackingMode = {
                switch vm.mapView?.userTrackingMode ?? .none {
                case .none:
                    return .follow
                case .follow:
                    return .followWithHeading
                default:
                    return .none
                }
            }()
            vm.updateTrackingMode(nextTrackingMode)
        }
    }
    
    func updateMapType() {
        let nextMapType: MKMapType = {
            switch vm.mapView?.mapType ?? .standard {
            case .standard:
                return .hybrid
            default:
                return .standard
            }
        }()
        vm.updateMapType(nextMapType)
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
