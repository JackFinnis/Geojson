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
    @State var selectedAnnotation: MKAnnotation?
    @State var droppedPoint: Point?
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                MapView(selectedAnnotation: $selectedAnnotation, trackingMode: $trackingMode, data: data, mapStandard: mapStandard, preview: false, fail: fail)
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
                    .confirmationDialog(selectedAnnotation?.name ?? "", isPresented: Binding(get: {
                        selectedAnnotation != nil
                    }, set: { isPresented in
                        withAnimation {
                            if !isPresented {
                                selectedAnnotation = nil
                            }
                        }
                    }), titleVisibility: selectedAnnotation?.name == nil ? .hidden : .visible) {
                        if let selectedAnnotation {
                            let user = selectedAnnotation is MKUserLocation
                            Button(user ? "Open in Maps" : "Get Directions") {
                                Task {
                                    try? await getDirections(to: selectedAnnotation)
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
    
    nonisolated func getDirections(to annotation: MKAnnotation) async throws {
        if let point = annotation as? Point {
            guard let placemark = try await CLGeocoder().reverseGeocodeLocation(point.coordinate.location).first else { return }
            let mapItem = MKMapItem(placemark: MKPlacemark(placemark: placemark))
            mapItem.name = point.title ?? mapItem.name
            mapItem.openInMaps()
        } else if let feature = annotation as? MKMapFeatureAnnotation {
            let request = MKMapItemRequest(mapFeatureAnnotation: feature)
            let mapItem = try await request.mapItem
            mapItem.openInMaps()
        } else if let _ = annotation as? MKUserLocation {
            MKMapItem.forCurrentLocation().openInMaps()
        }
    }
}
