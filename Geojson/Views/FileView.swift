//
//  FileView.swift
//  Geojson
//
//  Created by Jack Finnis on 11/03/2024.
//

import SwiftUI
import MapKit

struct FileView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var app: AppState
    @State var mapStyle = MapStyle.standard(elevation: .realistic)
    @State var mapStandard = true
    @State var mapPosition: MapCameraPosition
    @State var selectedPoint: Point?
    @State var droppedPoint: Point?
    @State var mapRect: MKMapRect?
    @State var liveGesture = false
    @Namespace var mapScope
    
    let data: GeoData
    
    var body: some View {
        MapReader { map in
            GeometryReader { geo in
                Map(position: $mapPosition, selection: $selectedPoint.animation(), scope: mapScope) {
                    UserAnnotation()
                    ForEach(data.polylines, id: \.self) { polyline in
                        MapPolyline(polyline)
                            .stroke(colorScheme == .light ? .blue : .cyan, style: .init(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    }
                    ForEach(data.polygons, id: \.self) { polygon in
                        MapPolygon(polygon)
                            .foregroundStyle(.orange.opacity(0.1))
                            .stroke(.orange, style: .init(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    }
                    if let droppedPoint {
                        Marker("", coordinate: droppedPoint.coordinate)
                    }
                    ForEach(data.points, id: \.self) { point in
                        if let i = point.index {
                            Marker(point.title ?? "", monogram: Text(String(i)), coordinate: point.coordinate)
                        } else {
                            Marker(point.title ?? "", coordinate: point.coordinate)
                        }
                    }
                }
                .contentMargins(20)
                .mapStyle(mapStyle)
                .mapControls {}
                .onMapCameraChange { context in
                    mapRect = context.rect
                }
//                .gesture(
//                    LongPressGesture(minimumDuration: 1)
//                        .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .local))
//                        .onEnded { value in
//                            if case let .second(true, drag) = value {
//                                guard let point = drag?.location,
//                                      let coord = map.convert(point, from: .local)
//                                else { return }
//                                droppedPoint = Point(coordinate: coord)
//                                withAnimation {
//                                    selectedPoint = droppedPoint
//                                }
//                            }
//                            liveGesture = false
//                        }
//                        .onChanged { value in
//                            if case let .second(true, drag) = value, !liveGesture {
//                                liveGesture = true
//                                Haptics.tap()
//                            }
//                        }
//                )
                .overlay(alignment: .top) {
                    CarbonCopy()
                        .id(app.scenePhase)
                        .blur(radius: 5, opaque: true)
                        .frame(height: geo.safeAreaInsets.top)
                        .mask {
                            LinearGradient(colors: [.white, .white, .clear], startPoint: .top, endPoint: .bottom)
                        }
                        .ignoresSafeArea()
                }
                .overlay(alignment: .topLeading) {
                    HStack(alignment: .top, spacing: 20) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .bold()
                                .box()
                        }
                        .mapButton()
                        
                        MapScaleView(scope: mapScope)
                    }
                    .padding(10)
                }
                .overlay(alignment: .topTrailing) {
                    VStack(spacing: 10) {
                        MapUserLocationButton(scope: mapScope)
                            .buttonBorderShape(.roundedRectangle)
                        
                        Button {
                            mapStyle = mapStandard ? .hybrid(elevation: .realistic) : .standard(elevation: .realistic)
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
                        
                        if let selectedPoint {
                            Button {
                                Task {
                                    guard let placemark = try? await CLGeocoder().reverseGeocodeLocation(selectedPoint.coordinate.location).first else { return }
                                    let mapItem = MKMapItem(placemark: MKPlacemark(placemark: placemark))
                                    mapItem.openInMaps()
                                }
                            } label: {
                                Image(systemName: "arrow.triangle.turn.up.right.diamond")
                                    .box()
                            }
                            .mapButton()
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        MapCompass(scope: mapScope)
                    }
                    .padding(10)
                }
                .mapScope(mapScope)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview {
    FileView(mapPosition: .automatic, data: .example)
        .environmentObject(AppState.shared)
}
