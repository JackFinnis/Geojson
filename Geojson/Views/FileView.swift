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
    let fail: (GeoError) -> Void
    
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
                }
                if let url = selectedAnnotation.googleURL,
                   UIApplication.shared.canOpenURL(url) {
                    Button("Info") {
                        openURL(url)
                    }
                }
                Button("Look Around") {
                    Task {
                        await lookAround(coord: selectedAnnotation.coordinate)
                    }
                }
                let user = selectedAnnotation is MKUserLocation
                Button(user ? "Open in Maps" : "Get Directions") {
                    Task {
                        await openInMaps(annotation: selectedAnnotation)
                    }
                }
            }
        }
        .fullScreenCover(item: $lookAroundScene) { scene in
            LookAroundPreview(initialScene: scene)
                .ignoresSafeArea()
        }
        .onAppear {
            CLLocationManager().requestWhenInUseAuthorization()
        }
    }
    
    func lookAround(coord: CLLocationCoordinate2D) async {
        do {
            lookAroundScene = try await MKLookAroundSceneRequest(coordinate: coord).scene
            guard lookAroundScene != nil else { throw GeoError.lookAround }
        } catch {
            print(error)
            fail(.lookAround)
        }
    }
    
    func openInMaps(annotation: MKAnnotation) async {
        do {
            let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
            if let point = annotation as? Point {
                guard let placemark = try await CLGeocoder().reverseGeocodeLocation(point.coordinate.location).first else { return }
                let mapItem = MKMapItem(placemark: MKPlacemark(placemark: placemark))
                mapItem.name = point.title ?? mapItem.name
                mapItem.openInMaps(launchOptions: launchOptions)
            } else if let feature = annotation as? MKMapFeatureAnnotation {
                let mapItem = try await MKMapItemRequest(mapFeatureAnnotation: feature).mapItem
                mapItem.openInMaps(launchOptions: launchOptions)
            } else if let _ = annotation as? MKUserLocation {
                MKMapItem.forCurrentLocation().openInMaps()
            }
        } catch {
            print(error)
            fail(.lookAround)
        }
    }
}

extension MKLookAroundScene: @retroactive Identifiable {
    public var id: UUID { UUID() }
}
