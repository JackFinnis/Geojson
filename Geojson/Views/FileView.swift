//
//  DataView.swift
//  Geojson
//
//  Created by Jack Finnis on 24/05/2024.
//

import SwiftUI
import MapKit

struct FileView: View {
    @Bindable var file: File
    let data: GeoData
    let fail: (GeoError) -> Void
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.openURL) var openURL
    @State var trackingMode = MKUserTrackingMode.none
    @State var mapStandard = true
    @State var selectedPoint: Point?
    @State var droppedPoint: Point?
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                MapView(selectedPoint: $selectedPoint, trackingMode: $trackingMode, data: data, mapStandard: mapStandard, preview: false, fail: fail)
                    .ignoresSafeArea()
                
                Button {
                    mapStandard.toggle()
                } label: {
                    Image(systemName: mapStandard ? "map" : "globe.europe.africa.fill")
                        .contentTransition(.symbolEffect(.replace))
                        .mapBox()
                }
                .mapButton()
                .position(x: geo.size.width - 32, y: -22)
                
                Color.clear.mapBox()
                    .confirmationDialog(selectedPoint?.name ?? "", isPresented: Binding(get: {
                        selectedPoint != nil
                    }, set: { isPresented in
                        withAnimation {
                            if !isPresented {
                                selectedPoint = nil
                            }
                        }
                    }), titleVisibility: selectedPoint?.name == nil ? .hidden : .visible) {
                        if let selectedPoint {
                            Button("Get Directions") {
                                Task {
                                    try? await getDirections(to: selectedPoint)
                                }
                            }
                        }
                    }
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
            }
        }
        .navigationTitle($file.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            CLLocationManager().requestWhenInUseAuthorization()
        }
    }
    
    nonisolated func getDirections(to point: Point) async throws {
        guard let placemark = try await CLGeocoder().reverseGeocodeLocation(point.coordinate.location).first else { return }
        let mapItem = MKMapItem(placemark: MKPlacemark(placemark: placemark))
        mapItem.name = point.title ?? mapItem.name
        mapItem.openInMaps()
    }
}
