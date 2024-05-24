//
//  DataView.swift
//  Geojson
//
//  Created by Jack Finnis on 24/05/2024.
//

import SwiftUI
import MapKit

struct DataView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State var trackingMode = MKUserTrackingMode.none
    @State var mapType = MKMapType.standard
    
    let data: GeoData
    let scenePhase: ScenePhase
    
    var body: some View {
        ZStack {
            MapView(trackingMode: $trackingMode, data: data, mapType: mapType)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                CarbonCopy()
                    .id(scenePhase)
                    .blur(radius: 5, opaque: true)
                    .mask {
                        LinearGradient(colors: [.white, .white, .clear], startPoint: .top, endPoint: .bottom)
                    }
                    .ignoresSafeArea()
                Spacer()
                    .layoutPriority(1)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 10) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .bold()
                            .mapBox()
                    }
                    .mapButton()
                    Button {
                        updateMapType()
                    } label: {
                        Image(systemName: mapTypeImage)
                            .contentTransition(.symbolEffect(.replace))
                            .mapBox()
                    }
                    .mapButton()
                    Button {
                        updateTrackingMode()
                    } label: {
                        Image(systemName: trackingModeImage)
                            .contentTransition(.symbolEffect(.replace))
                            .mapBox()
                    }
                    .mapButton()
                    Spacer()
                }
                Spacer()
            }
            .padding(10)
        }
        .toolbar(.hidden, for: .navigationBar)
    }
    
    func updateTrackingMode() {
        switch trackingMode {
        case .none:
            trackingMode = .follow
        case .follow:
            trackingMode = .followWithHeading
        default:
            trackingMode = .none
        }
    }
    
    func updateMapType() {
        switch mapType {
        case .standard:
            mapType = .hybrid
        default:
            mapType = .standard
        }
    }
    
    var trackingModeImage: String {
        switch trackingMode {
        case .none:
            return "location"
        case .follow:
            return "location.fill"
        default:
            return "location.north.line.fill"
        }
    }
    
    var mapTypeImage: String {
        switch mapType {
        case .standard:
            return "globe.europe.africa.fill"
        default:
            return "map"
        }
    }
}

#Preview {
    DataView(data: .example, scenePhase: .active)
}
