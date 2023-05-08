//
//  MapView.swift
//  Paddle
//
//  Created by Jack Finnis on 11/09/2022.
//

import SwiftUI
import MapKit

class _MKMapView: MKMapView {
    override func layoutSubviews() {
        super.layoutSubviews()
        if let compass = subviews.first(where: { type(of: $0).id == "MKCompassView" }) {
            compass.center = compass.center.applying(.init(translationX: -5, y: SIZE*3 + 25))
            if (compass.gestureRecognizers?.count ?? 0) < 2 {
                let tap = UITapGestureRecognizer(target: ViewModel.shared, action: #selector(ViewModel.tappedCompass))
                tap.delegate = ViewModel.shared
                compass.addGestureRecognizer(tap)
            }
        }
    }
}

struct MapView: UIViewRepresentable {
    @EnvironmentObject var vm: ViewModel
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = _MKMapView()
        mapView.delegate = vm
        vm.mapView = mapView
        
        mapView.showsUserLocation = true
        mapView.showsScale = true
        mapView.showsCompass = true
        mapView.isPitchEnabled = false
        
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMarkerAnnotationView.id)
        
        return mapView
    }
    
    func updateUIView(_ view: MKMapView, context: Context) {}
}
