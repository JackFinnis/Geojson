//
//  FileView.swift
//  Geojson
//
//  Created by Jack Finnis on 11/03/2024.
//

import SwiftUI
import MapKit

struct MapView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State var mapStyle = MapStyle.standard
    @State var mapStandard = true
    @State var selectedPoint: Point?
    @State var droppedPoint: Point?
    @State var liveGesture = false
    @Namespace var mapScope
    
    let data: GeoData
    let scenePhase: ScenePhase
    
    var body: some View {
        MapReader { map in
            GeometryReader { geo in
                Map(initialPosition: .rect(data.rect), interactionModes: [.pan, .zoom, .rotate], selection: $selectedPoint.animation(), scope: mapScope) {
                    UserAnnotation()
                    ForEach(data.polylines, id: \.self) { polyline in
                        MapPolyline(polyline)
                            .stroke(colorScheme == .light && mapStandard ? .blue : .cyan, style: .init(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    }
                    ForEach(data.polygons, id: \.self) { polygon in
                        MapPolygon(polygon)
                            .foregroundStyle(.orange.opacity(0.1))
                            .stroke(.orange, style: .init(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    }
                    if let droppedPoint, droppedPoint == selectedPoint {
                        Marker("", coordinate: droppedPoint.coordinate)
                            .tag(droppedPoint)
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
                .onTapGesture { point in }
                .gesture(
                    LongPressGesture(minimumDuration: 1, maximumDistance: 0)
                        .simultaneously(with: DragGesture(minimumDistance: 0, coordinateSpace: .local))
                        .onEnded { value in
                            liveGesture = false
                        }
                        .onChanged { value in
                            guard let drag = value.second,
                                  let coord = map.convert(drag.location, from: .local),
                                  !liveGesture
                            else { return }
                            liveGesture = true
                            Haptics.tap()
                            dropPoint(coord: coord)
                        }
                )
                .overlay(alignment: .top) {
                    CarbonCopy()
                        .id(scenePhase)
                        .blur(radius: 5, opaque: true)
                        .frame(height: geo.safeAreaInsets.top)
                        .mask {
                            LinearGradient(colors: [.white, .white, .clear], startPoint: .top, endPoint: .bottom)
                        }
                        .ignoresSafeArea()
                }
                .overlay(alignment: .topLeading) {
                    HStack(alignment: .top, spacing: 20) {
                        Menu {
                            Button("Back") {
                                dismiss()
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                                .bold()
                                .mapBox()
                        } primaryAction: {
                            dismiss()
                        }
                        .mapButton()
                        
                        MapScaleView(scope: mapScope)
                    }
                    .padding(10)
                }
                .overlay(alignment: .topTrailing) {
                    VStack(spacing: 10) {
                        Button {
                            mapStyle = mapStandard ? .hybrid : .standard
                            mapStandard.toggle()
                        } label: {
                            Image(systemName: mapStandard ? "globe.americas.fill" : "map")
                                .contentTransition(.symbolEffect(.replace))
                                .mapBox()
                        }
                        .mapButton()
                        
                        MapUserLocationButton(scope: mapScope)
                            .buttonBorderShape(.roundedRectangle)
                        
                        MapCompass(scope: mapScope)
                    }
                    .padding(10)
                }
                .mapScope(mapScope)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .confirmationDialog("", isPresented: Binding(get: {
            selectedPoint != nil
        }, set: { isPresented in
            withAnimation {
                if !isPresented {
                    selectedPoint = nil
                }
            }
        })) {
            if let selectedPoint {
                Button("Directions") {
                    Task {
                        await openInMaps(point: selectedPoint)
                    }
                }
            }
        }
    }
    
    func dropPoint(coord: CLLocationCoordinate2D) {
        withAnimation {
            droppedPoint = Point(coordinate: coord)
            selectedPoint = droppedPoint
        }
    }
    
    func openInMaps(point: Point) async {
        guard let placemark = try? await CLGeocoder().reverseGeocodeLocation(point.coordinate.location).first else { return }
        let mapItem = MKMapItem(placemark: MKPlacemark(placemark: placemark))
        mapItem.name = point.title ?? mapItem.name
        mapItem.openInMaps()
    }
}

#Preview {
    MapView(data: .example, scenePhase: .active)
}
