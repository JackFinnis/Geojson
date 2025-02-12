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
    let namespace: Namespace.ID
    
    @State var mapStandard = true
    @State var selectedAnnotation: Annotation?
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                MapView(selectedAnnotation: $selectedAnnotation, data: data, mapStandard: mapStandard, preview: false)
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
                
                Color.clear
                    .mapBox()
                    .confirmationDialog(selectedAnnotation?.properties.string ?? "", isPresented: Binding(get: {
                        selectedAnnotation is Point || selectedAnnotation?.properties.dict.isNotEmpty ?? false
                    }, set: { isPresented in
                        if !isPresented {
                            selectedAnnotation = nil
                        }
                    }), titleVisibility: (selectedAnnotation?.properties.dict.isEmpty ?? true) ? .hidden : .visible) {
                        Button("Close", role: .cancel) {}
                        if let selectedAnnotation {
                            if let url = selectedAnnotation.properties.urls.first(where: UIApplication.shared.canOpenURL) {
                                Button("Open URL") {
                                    UIApplication.shared.open(url)
                                }
                            }
                            if selectedAnnotation.properties.dict.isNotEmpty {
                                Button("Copy Details") {
                                    UIPasteboard.general.string = selectedAnnotation.properties.string
                                    Haptics.tap()
                                }
                            }
                            if let point = selectedAnnotation as? Point {
                                Button("Get Directions") {
                                    Task {
                                        try? await point.openInMaps()
                                    }
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
        .zoomChild(id: file.id, in: namespace)
    }
}
