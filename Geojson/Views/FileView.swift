//
//  DataView.swift
//  Geojson
//
//  Created by Jack Finnis on 24/05/2024.
//

import SwiftUI
import MapKit

struct FileView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.openURL) var openURL
    @State var trackingMode = MKUserTrackingMode.none
    @State var mapStandard = true
    @State var selectedAnnotation: MKAnnotation?
    @State var droppedPoint: Point?
    @State var lookAroundScene: MKLookAroundScene?
    @AppState("visitedCoords") var visitedCoords = Set<CLLocationCoordinate2D>()
    
    @Bindable var file: File
    let data: GeoData
    let scenePhase: ScenePhase
    let fail: (GeoError) -> Void
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                MapView(trackingMode: $trackingMode, lookAroundScene: $lookAroundScene, data: data, mapStandard: mapStandard, preview: false, fail: fail)
                    .ignoresSafeArea()
                
                #if os(iOS)
                VStack(spacing: 0) {
                    CarbonCopy()
                        .frame(height: geo.safeAreaInsets.top + 20)
                        .id(scenePhase)
                        .blur(radius: 5, opaque: true)
                        .mask {
                            LinearGradient(colors: [.white, .white, .white, .clear], startPoint: .top, endPoint: .bottom)
                        }
                    Spacer()
                }
                .ignoresSafeArea()
                #endif
                
                Button {
                    mapStandard.toggle()
                } label: {
                    Image(systemName: mapStandard ? "map" : "globe.europe.africa.fill")
                        .contentTransition(.symbolEffect(.replace))
                        .mapBox()
                }
                .mapButton()
                .padding(10)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    mapStandard.toggle()
                } label: {
                    Image(systemName: "map")
                        .foregroundStyle(.clear)
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle($file.name)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $lookAroundScene) { scene in
            LookAroundPreview(initialScene: scene)
                .ignoresSafeArea()
        }
        .onAppear {
            CLLocationManager().requestWhenInUseAuthorization()
        }
    }
}

extension MKLookAroundScene: Identifiable {
    public var id: UUID { UUID() }
}
