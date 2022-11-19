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
    @Published var trackingMode = MKUserTrackingMode.follow
    @Published var mapType = MKMapType.standard
    @Published var polylines = [MKPolyline]()
    
    @Published var showImportFailedAlert = false
    @Published var showAuthAlert = false
    
    var mapView: MKMapView?
    var manager = CLLocationManager()
    var status = CLAuthorizationStatus.notDetermined
    var authorized: Bool {
        status == .authorizedWhenInUse
    }
    
    override init() {
        super.init()
        manager.delegate = self
    }
    
    func importData(from url: URL) {
        guard let data = try? Data(contentsOf: url),
              let features = try? MKGeoJSONDecoder().decode(data) as? [MKGeoJSONFeature]
        else { showImportFailedAlert = true; return }
        
        var newPolylines = [MKPolyline]()
        for feature in features {
            guard let geometry = feature.geometry.first else { continue }
            if let polyline = geometry as? MKPolyline {
                newPolylines.append(polyline)
            } else if let multiPolyline = geometry as? MKMultiPolyline {
                newPolylines.append(contentsOf: multiPolyline.polylines)
            }
        }
        
        guard newPolylines.isNotEmpty else {
            showImportFailedAlert = true
            return
        }
        
        polylines.append(contentsOf: newPolylines)
        let padding = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        mapView?.setVisibleMapRect(MKMultiPolyline(newPolylines).boundingMapRect, edgePadding: padding, animated: true)
    }
    
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - MKMapViewDelegate
extension ViewModel: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.lineWidth = 2
            renderer.strokeColor = mapType == .standard ? .systemBlue : .blue
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    
    func mapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool) {
        if !animated {
            DispatchQueue.main.async {
                self.trackingMode = .none
            }
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
