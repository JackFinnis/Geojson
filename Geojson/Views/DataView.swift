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
    @Environment(\.openURL) var openURL
    @State var trackingMode = MKUserTrackingMode.none
    @State var mapType = MKMapType.standard
    @State var selectedAnnotation: MKAnnotation?
    @State var droppedPoint: Point?
    @AppState("visitedCoords") var visitedCoords = Set<CLLocationCoordinate2D>()
    
    let data: GeoData
    let scenePhase: ScenePhase
    
    var body: some View {
        ZStack {
            MapView(selectedAnnotation: $selectedAnnotation, trackingMode: $trackingMode, data: data, mapType: mapType, preview: false)
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
                if let point = selectedAnnotation as? Point {
                    if visitedCoords.contains(point.coordinate) {
                        Button("Undo Visited", role: .destructive) {
                            visitedCoords.remove(point.coordinate)
                        }
                    } else {
                        Button("Mark as Visited") {
                            visitedCoords.insert(point.coordinate)
                        }
                    }
                    if let url = point.googleURL,
                       UIApplication.shared.canOpenURL(url) {
                        Button("Search Google") {
                            openURL(url)
                        }
                    }
                }
                let user = selectedAnnotation is MKUserLocation
                Button(user ? "Open in Maps" : "Directions") {
                    Task {
                        await openInMaps(selectedAnnotation)
                    }
                }
            }
        }
        .onAppear {
            CLLocationManager().requestWhenInUseAuthorization()
        }
    }
    
    func openInMaps(_ annotation: MKAnnotation) async {
        if let point = annotation as? Point {
            guard let placemark = try? await CLGeocoder().reverseGeocodeLocation(point.coordinate.location).first else { return }
            let mapItem = MKMapItem(placemark: MKPlacemark(placemark: placemark))
            mapItem.name = point.title ?? mapItem.name
            mapItem.openInMaps()
        } else if let feature = annotation as? MKMapFeatureAnnotation {
            guard let mapItem = try? await MKMapItemRequest(mapFeatureAnnotation: feature).mapItem else { return }
            mapItem.openInMaps()
        } else if let _ = annotation as? MKUserLocation {
            MKMapItem.forCurrentLocation().openInMaps()
        }
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
    DataView(data: .empty, scenePhase: .active)
}
