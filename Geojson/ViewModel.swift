//
//  ViewModel.swift
//  Paddle
//
//  Created by Jack Finnis on 11/09/2022.
//

import Foundation
import MapKit
import SwiftUI

class ViewModel: NSObject, ObservableObject {
    // Geometry
    @Published var points = [MKPointAnnotation]()
    @Published var polylines = [MKPolyline]()
    @Published var polygons = [MKPolygon]()
    
    // Map
    var mapView: MKMapView?
    @Published var trackingMode = MKUserTrackingMode.follow
    @Published var mapType = MKMapType.standard { didSet {
        mapTypeStorage = mapType.rawValue
    }}
    
    // Storage
    @OptionalStorage(key: "recentURL", defaultValue: nil) var recentURL: String?
    @Storage(key: "recentURLs", defaultValue: [String]()) var recentURLs
    @Storage(key: "mapTypeStorage", defaultValue: UInt.zero) var mapTypeStorage
    
    // Alerts
    @Published var showImportFailedAlert = false
    @Published var showAuthAlert = false
    
    // Animations
    @Published var degrees = 0.0
    @Published var scale = 1.0
    
    // Location Manager
    var manager = CLLocationManager()
    var status = CLAuthorizationStatus.notDetermined
    var authorized: Bool {
        status == .authorizedWhenInUse
    }
    
    override init() {
        super.init()
        manager.delegate = self
        mapType = MKMapType(rawValue: mapTypeStorage) ?? .standard
    }
    
    func importData(from url: URL) {
        func failed() {
            showImportFailedAlert = true
            recentURL = nil
            recentURLs.removeAll { $0 == url.absoluteString }
        }
        
        guard let data = try? Data(contentsOf: url),
              let features = try? MKGeoJSONDecoder().decode(data) as? [MKGeoJSONFeature]
        else { failed(); return }
        
        points = []
        polylines = []
        polygons = []
        
        for feature in features {
            for geometry in feature.geometry {
                handleGeometry(geometry)
            }
        }
        
        guard points.isNotEmpty || polylines.isNotEmpty || polygons.isNotEmpty else {
            failed()
            return
        }
        
        zoom()
        
        let urlString = url.absoluteString
        recentURL = urlString
        if !recentURLs.contains(urlString) {
            recentURLs.append(urlString)
        }
    }
    
    func zoom() {
        let coords = points.map { $0.coordinate }
        let pointsRect = MKPolyline(coordinates: coords, count: coords.count).boundingMapRect
        let polylinesRect = MKMultiPolyline(polylines).boundingMapRect
        let polygonsRect = MKMultiPolygon(polygons).boundingMapRect
        let rect = pointsRect.union(polylinesRect).union(polygonsRect)
        
        let padding = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        mapView?.setVisibleMapRect(rect, edgePadding: padding, animated: true)
    }
    
    func handleGeometry(_ geometry: MKShape & MKGeoJSONObject) {
        if let point = geometry as? MKPointAnnotation {
            points.append(point)
        } else if let polyline = geometry as? MKPolyline {
            polylines.append(polyline)
        } else if let multiPolyline = geometry as? MKMultiPolyline {
            polylines.append(contentsOf: multiPolyline.polylines)
        } else if let polygon = geometry as? MKPolygon {
            polygons.append(polygon)
        } else if let multiPolygon = geometry as? MKMultiPolygon {
            polygons.append(contentsOf: multiPolygon.polygons)
        }
    }
    
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    func updateTrackingMode(_ newMode: MKUserTrackingMode) {
        mapView?.setUserTrackingMode(newMode, animated: true)
        if trackingMode == .followWithHeading || newMode == .followWithHeading {
            withAnimation(.easeInOut(duration: 0.25)) {
                scale = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.trackingMode = newMode
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.scale = 1
                }
            }
        } else {
            DispatchQueue.main.async {
                self.trackingMode = newMode
            }
        }
    }
    
    func updateMapType(_ newType: MKMapType) {
        mapView?.mapType = newType
        withAnimation(.easeInOut(duration: 0.25)) {
            degrees += 90
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.mapType = newType
            withAnimation(.easeInOut(duration: 0.3)) {
                self.degrees += 90
            }
        }
    }
}

// MARK: - MKMapViewDelegate
extension ViewModel: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.lineWidth = 2
            renderer.strokeColor = UIColor(.accentColor)
            return renderer
        } else if let polygon = overlay as? MKPolygon {
            let renderer = MKPolygonRenderer(polygon: polygon)
            renderer.lineWidth = 2
            renderer.strokeColor = .systemOrange
            renderer.fillColor = .systemOrange.withAlphaComponent(0.1)
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    
    func mapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool) {
        if !animated {
            updateTrackingMode(.none)
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension ViewModel: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        status = manager.authorizationStatus
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            manager.startUpdatingLocation()
        case .denied:
            showAuthAlert = true
        default:
            break
        }
    }
}
