//
//  FileView.swift
//  Geojson
//
//  Created by Jack Finnis on 11/03/2024.
//

import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @Binding var trackingMode: MKUserTrackingMode
    let data: GeoData
    let mapType: MKMapType
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        mapView.isPitchEnabled = false
        mapView.selectableMapFeatures = [.physicalFeatures, .pointsOfInterest]
        
        mapView.addAnnotations(data.points)
        mapView.addOverlay(MKMultiPolyline(data.polylines), level: .aboveRoads)
        mapView.addOverlay(MKMultiPolygon(data.polygons), level: .aboveRoads)
        mapView.setVisibleMapRect(data.rect, edgePadding: .init(top: 16, left: 16, bottom: 16, right: 16), animated: false)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.setUserTrackingMode(trackingMode, animated: true)
        mapView.mapType = mapType
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        let parent: MapView
        
        init(_ parent: MapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: any MKOverlay) -> MKOverlayRenderer {
            let color = UIColor(Color.orange)
            if let multiPolyline = overlay as? MKMultiPolyline {
                let renderer = MKMultiPolylineRenderer(multiPolyline: multiPolyline)
                renderer.lineWidth = 3
                renderer.strokeColor = color
                return renderer
            } else if let multiPolygon = overlay as? MKMultiPolygon {
                let renderer = MKMultiPolygonRenderer(multiPolygon: multiPolygon)
                renderer.lineWidth = 3
                renderer.strokeColor = color
                renderer.fillColor = color.withAlphaComponent(0.1)
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
            guard let point = annotation as? Point,
                  let marker = mapView.dequeueReusableAnnotationView(withIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier, for: annotation) as? MKMarkerAnnotationView
            else { return nil }
            marker.displayPriority = .required
            marker.glyphText = point.index.map(String.init)
            return marker
        }
        
        func mapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool) {
            if !animated {
                parent.trackingMode = .none
            }
        }
    }
}
