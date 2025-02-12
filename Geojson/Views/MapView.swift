//
//  FileView.swift
//  Geojson
//
//  Created by Jack Finnis on 11/03/2024.
//

import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @Binding var selectedAnnotation: Annotation?

    let data: GeoData
    let mapStandard: Bool
    let preview: Bool
    
    let mapView = MKMapView()
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> MKMapView {
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = !preview
        mapView.isPitchEnabled = true
        mapView.selectableMapFeatures = .pointsOfInterest
        mapView.layoutMargins = .init(length: preview ? -25 : 5)
        mapView.showsUserTrackingButton = !preview
        mapView.pitchButtonVisibility = preview ? .hidden : .visible
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        
        mapView.addAnnotations(data.points)
        mapView.addOverlays(data.multiPolylines, level: .aboveRoads)
        mapView.addOverlays(data.multiPolygons, level: .aboveRoads)
        mapView.setVisibleMapRect(data.rect, edgePadding: .init(length: preview ? 35 : 10), animated: false)
        
        let tapRecognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap))
        mapView.addGestureRecognizer(tapRecognizer)
        let longPressRecognizer = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLongPress))
        mapView.addGestureRecognizer(longPressRecognizer)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.preferredConfiguration = mapStandard ? MKStandardMapConfiguration(elevationStyle: .realistic) : MKHybridMapConfiguration(elevationStyle: .realistic)
        
        if selectedAnnotation == nil {
            mapView.selectedAnnotations.forEach { annotation in
                if let point = annotation as? Point {
                    mapView.deselectAnnotation(point, animated: true)
                    if point.isDroppedPin {
                        mapView.removeAnnotation(point)
                    }
                }
            }
        }
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        let parent: MapView
        
        init(_ parent: MapView) {
            self.parent = parent
        }
        
        @available(iOS 18.0, *)
        func mapView(_ mapView: MKMapView, selectionAccessoryFor annotation: any MKAnnotation) -> MKSelectionAccessory? {
            .mapItemDetail(.openInMaps)
        }
        
        func mapView(_ mapView: MKMapView, didSelect annotation: any MKAnnotation) {
            if let point = annotation as? Point {
                parent.selectedAnnotation = point
            }
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: any MKOverlay) -> MKOverlayRenderer {
            let defaultColor = UIColor(.orange)
            let lineWidth = parent.preview ? 2.0 : 3.0
            if let multiPolyline = overlay as? MultiPolyline {
                let color = multiPolyline.color ?? defaultColor
                let renderer = MKMultiPolylineRenderer(multiPolyline: multiPolyline.mkMultiPolyline)
                renderer.lineWidth = lineWidth
                renderer.strokeColor = color
                return renderer
            } else if let multiPolygon = overlay as? MultiPolygon {
                let color = multiPolygon.color ?? defaultColor
                let renderer = MKMultiPolygonRenderer(multiPolygon: multiPolygon.mkMultiPolygon)
                renderer.lineWidth = lineWidth
                renderer.strokeColor = color
                renderer.fillColor = color.withAlphaComponent(0.2)
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
            if let point = annotation as? Point,
               let marker = mapView.dequeueReusableAnnotationView(withIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier, for: annotation) as? MKMarkerAnnotationView {
                marker.titleVisibility = parent.preview ? .hidden : .adaptive
                marker.displayPriority = .required
                marker.glyphText = point.index.map(String.init)
                marker.markerTintColor = point.color ?? UIColor(.orange)
                return marker
            }
            return nil
        }
        
        @objc
        func handleTap(_ tap: UITapGestureRecognizer) {
            guard parent.mapView.selectedAnnotations.isEmpty else { return }
            let mapView = parent.mapView
            let location = tap.location(in: mapView)
            let coord = mapView.convert(location, toCoordinateFrom: mapView)
            parent.selectedAnnotation = parent.data.closestOverlay(to: coord)
        }
        
        @objc
        func handleLongPress(_ press: UILongPressGestureRecognizer) {
            let mapView = parent.mapView
            guard press.state == .began else { return }
            let location = press.location(in: mapView)
            let coord = mapView.convert(location, toCoordinateFrom: mapView)
            let point = Point.droppedPin(coordindate: coord)
            mapView.addAnnotation(point)
            mapView.selectAnnotation(point, animated: true)
            Haptics.tap()
        }
    }
}
