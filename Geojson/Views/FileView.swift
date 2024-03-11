//
//  FileView.swift
//  Geojson
//
//  Created by Jack Finnis on 11/03/2024.
//

import SwiftUI
import MapKit

struct FileView: View {
    @State var mapStyle = MapStyle.standard(elevation: .realistic, showsTraffic: true)
    @State var mapStandard = true
    @State var mapPosition = MapCameraPosition.userLocation(fallback: .automatic)
    @State var selectedPoint: Point?
    @State var mapRect: MKMapRect?
    @State var liveGesture = false
    @Namespace var mapScope
    
    let file: File
    
    var body: some View {
        MapReader { map in
            GeometryReader { geo in
                Map(position: $mapPosition, selection: $selectedPoint.animation(), scope: mapScope) {
                    UserAnnotation()
                    ForEach(file.polylines, id: \.self) { polyline in
                        MapPolyline(polyline)
                            .stroke(.cyan, style: .init(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    }
                    ForEach(file.polygons, id: \.self) { polygon in
                        MapPolygon(polygon)
                            .stroke(.orange, style: .init(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    }
                    ForEach(file.points, id: \.self) { point in
                        if let title = point.title {
                            if let i = point.index {
                                Marker(title, monogram: Text(String(i)), coordinate: point.coordinate)
                            } else {
                                Marker(title, coordinate: point.coordinate)
                            }
                        }
                    }
                }
                .mapStyle(mapStyle)
                .mapControls {}
                .onMapCameraChange { context in
                    mapRect = context.rect
                }
                .overlay(alignment: .top) {
                    CarbonCopy()
                        .blur(radius: 5, opaque: true)
                        .frame(height: geo.safeAreaInsets.top)
                        .mask {
                            LinearGradient(colors: [.white, .white, .clear], startPoint: .top, endPoint: .bottom)
                        }
                        .ignoresSafeArea()
                }
                .overlay(alignment: .topLeading) {
                    MapScaleView(scope: mapScope)
                        .padding(16)
                }
                .overlay(alignment: .topTrailing) {
                    VStack(spacing: 10) {
                        MapUserLocationButton(scope: mapScope)
                            .buttonBorderShape(.roundedRectangle)
                        
                        Button {
                            mapStyle = mapStandard ? .hybrid(elevation: .realistic, showsTraffic: true) : .standard(elevation: .realistic, showsTraffic: true)
                            mapStandard.toggle()
                        } label: {
                            Image(systemName: mapStandard ? "globe" : "map")
                                .box()
                                .rotation3DEffect(mapStandard ? .degrees(180) : .zero, axis: (0, 1, 0))
                        }
                        .mapButton()
                        
                        MapPitchToggle(scope: mapScope)
                            .buttonBorderShape(.roundedRectangle)
                            .mapControlVisibility(.visible)
                        
                        MapCompass(scope: mapScope)
                    }
                    .padding(10)
                }
                .mapScope(mapScope)
            }
        }
    }
}
