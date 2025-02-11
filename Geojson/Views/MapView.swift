//
//  FileView.swift
//  Geojson
//
//  Created by Jack Finnis on 11/03/2024.
//

import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @Binding var selectedPoint: Point?

    @Binding var trackingMode: MKUserTrackingMode
    let data: GeoData
    let mapStandard: Bool
    let preview: Bool
    let fail: (GeoError) -> Void
    
    let mapView = MKMapView()
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> MKMapView {
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = !preview
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        mapView.isPitchEnabled = true
        mapView.selectableMapFeatures = .pointsOfInterest
        mapView.layoutMargins = .init(length: preview ? -25 : 5)
        mapView.showsUserTrackingButton = !preview
        mapView.pitchButtonVisibility = preview ? .hidden : .visible
        
        mapView.addAnnotations(data.points)
        mapView.addOverlays(data.multiPolylines, level: .aboveRoads)
        mapView.addOverlays(data.multiPolygons, level: .aboveRoads)
        mapView.setVisibleMapRect(data.rect, edgePadding: .init(length: preview ? 35 : 10), animated: false)
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLongPress))
        mapView.addGestureRecognizer(longPressRecognizer)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.preferredConfiguration = mapStandard ? MKStandardMapConfiguration(elevationStyle: .realistic) : MKHybridMapConfiguration(elevationStyle: .realistic)
        mapView.setUserTrackingMode(trackingMode, animated: true)
        
        if selectedPoint == nil {
            mapView.selectedAnnotations.forEach { annotation in
                mapView.deselectAnnotation(annotation, animated: true)
                mapView.removeAnnotation(annotation)
                if let point = annotation as? Point, !point.isDroppedPin {
                    mapView.addAnnotation(annotation)
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
                parent.selectedPoint = point
            }
        }
        
        func mapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool) {
            parent.trackingMode = mode
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: any MKOverlay) -> MKOverlayRenderer {
            let defaultColor = UIColor(Color.orange)
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
                renderer.fillColor = color.withAlphaComponent(0.1)
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
                marker.markerTintColor = UIColor(.orange)
                return marker
            }
            return nil
        }
        
        @objc
        func handleLongPress(_ press: UILongPressGestureRecognizer) {
            let mapView = parent.mapView
            guard press.state == .began else { return }
            let location = press.location(in: mapView)
            let coord = mapView.convert(location, toCoordinateFrom: mapView)
            let point = Point(coordinate: coord, title: "Dropped Pin")
            mapView.addAnnotation(point)
            mapView.selectAnnotation(point, animated: true)
            Haptics.tap()
        }
    }
}
