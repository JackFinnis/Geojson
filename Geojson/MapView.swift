//
//  MapView.swift
//  Paddle
//
//  Created by Jack Finnis on 11/09/2022.
//

import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @EnvironmentObject var vm: ViewModel
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = vm
        vm.mapView = mapView
        
        mapView.showsUserLocation = true
        mapView.showsScale = true
        mapView.showsCompass = true
        mapView.isPitchEnabled = false
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.mapType = vm.mapType
        if mapView.userTrackingMode != vm.trackingMode {
            mapView.setUserTrackingMode(vm.trackingMode, animated: true)
        }
        
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotations(vm.points)
        
        mapView.removeOverlays(mapView.overlays)
        mapView.addOverlays(vm.polylines, level: .aboveRoads)
        mapView.addOverlays(vm.polygons, level: .aboveRoads)
    }
}
