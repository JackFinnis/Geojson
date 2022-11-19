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
    
    var mapView: MKMapView?
    
    func loadData(from url: URL) {
        guard let data = try? Data(contentsOf: url),
              let features = try? MKGeoJSONDecoder().decode(data) as? [MKGeoJSONFeature]
        else { return }
        
        for feature in features {
            guard let geometry = feature.geometry.first else { continue }
            if let polyline = geometry as? MKPolyline {
                polylines.append(polyline)
            } else if let multiPolyline = geometry as? MKMultiPolyline {
                polylines.append(contentsOf: multiPolyline.polylines)
            }
        }
        
        mapView?.addOverlays(polylines, level: .aboveRoads)
        let padding = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        mapView?.setVisibleMapRect(MKMultiPolyline(polylines).boundingMapRect, edgePadding: padding, animated: true)
    }
}

// MARK: - MKMapViewDelegate
extension ViewModel: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.lineWidth = 2
            renderer.strokeColor = .systemBlue
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
