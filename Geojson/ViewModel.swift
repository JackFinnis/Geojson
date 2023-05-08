//
//  ViewModel.swift
//  Paddle
//
//  Created by Jack Finnis on 11/09/2022.
//

import Foundation
import MapKit
import SwiftUI
import GeoJSON

enum ImportError: String {
    case fileMoved = "This file has been moved or deleted. Please try importing it again."
    case fileCurrupted = "This file has been corrupted. Please try importing it again."
    case fileEmpty = "This file does not contain any points, polylines or polygons."
    case invalidGeojosn = "This file contains invalid geojson. https://geojson.io can help spot syntax errors in GeoJSON."
}

@MainActor
class ViewModel: NSObject, ObservableObject {
    static let shared = ViewModel()
    
    // MARK: - Properties
    // Geometry
    var points = [MKPointAnnotation]()
    var polylines = [MKPolyline]()
    var polygons = [MKPolygon]()
    
    // MapView
    var mapView: MKMapView?
    @Published var trackingMode = MKUserTrackingMode.none
    @Published var mapType = MKMapType.standard
    
    // Storage
    @Storage("recentUrlsData") var recentUrlsData = [Data]()
    var stale = false
    var recentUrls: [URL] {
        recentUrlsData.compactMap { try? URL(resolvingBookmarkData: $0, bookmarkDataIsStale: &stale) }
    }
    
    // Alerts
    @Published var importError = ImportError.fileMoved
    @Published var showFailedAlert = false
    
    // Animations
    @Published var degrees = 0.0
    @Published var scale = 1.0
    
    // CLLocationManager
    let manager = CLLocationManager()
    var authStatus = CLAuthorizationStatus.notDetermined
    @Published var showAuthAlert = false
    
    override init() {
        super.init()
        manager.delegate = self
    }
    
    func importFailed(error: ImportError, canShowAlert: Bool) {
        self.importError = error
        showFailedAlert = true
        Haptics.error()
    }
    
    func importFile(url: URL, canShowAlert: Bool = true) {
        guard url.startAccessingSecurityScopedResource(),
              let urlData = try? url.bookmarkData(options: .suitableForBookmarkFile, includingResourceValuesForKeys: [.fileSecurityKey], relativeTo: nil)
        else {
            importFailed(error: .fileMoved, canShowAlert: canShowAlert)
            return
        }
        
        let data: Data
        do {
            data = try Data(contentsOf: url)
            url.stopAccessingSecurityScopedResource()
        } catch {
            importFailed(error: .fileCurrupted, canShowAlert: canShowAlert)
            return
        }
        
        let features: [Feature]
        do {
            let document = try JSONDecoder().decode(GeoJSONDocument.self, from: data)
            switch document {
            case .feature(let feature):
                features = [feature]
            case .featureCollection(let featureCollection):
                features = featureCollection.features
            }
        } catch {
            importFailed(error: .invalidGeojosn, canShowAlert: canShowAlert)
            return
        }
        guard features.isNotEmpty else {
            importFailed(error: .fileEmpty, canShowAlert: canShowAlert)
            return
        }
        
        points = []
        polylines = []
        polygons = []
        features.compactMap(\.geometry).forEach(handleGeometry)
        
        mapView?.removeAnnotations(mapView?.annotations ?? [])
        mapView?.removeOverlays(mapView?.overlays ?? [])
        
        mapView?.addAnnotations(points)
        mapView?.addOverlays(polylines, level: .aboveRoads)
        mapView?.addOverlays(polygons, level: .aboveRoads)
        
        zoom()
        Haptics.tap()
        if !recentUrlsData.contains(urlData) {
            recentUrlsData.append(urlData)
        }
    }
    
    func handleGeometry(_ geometry: Geometry) {
        switch geometry {
        case .geometryCollection(let geometries):
            geometries.forEach(handleGeometry)
        case .point(let point):
            addPoint(point.coordinates)
        case .multiPoint(let multiPoint):
            multiPoint.coordinates.forEach(addPoint)
        case .lineString(let lineString):
            addPolyline(lineString)
        case .multiLineString(let multiLineString):
            multiLineString.coordinates.forEach(addPolyline)
        case .polygon(let polygon):
            addPolygon(polygon)
        case .multiPolygon(let multiPolygon):
            multiPolygon.coordinates.forEach(addPolygon)
        }
    }
    
    func addPoint(_ position: Position) {
        let point = MKPointAnnotation()
        point.coordinate = position.coordinate
        points.append(point)
    }
    
    func addPolyline(_ lineString: LineString) {
        let coords = lineString.coordinates.map(\.coordinate)
        polylines.append(MKPolyline(coordinates: coords, count: coords.count))
    }
    
    func addPolygon(_ polygon: Polygon) {
        guard let exterior = polygon.coordinates.first else { return }
        let exteriorCoords = exterior.coordinates.map(\.coordinate)
        let interiors = Array(polygon.coordinates.dropFirst())
        let interiorPolygons = interiors.map { positions in
            let coords = positions.coordinates.map(\.coordinate)
            return MKPolygon(coordinates: coords, count: coords.count)
        }
        polygons.append(MKPolygon(coordinates: exteriorCoords, count: exteriorCoords.count, interiorPolygons: interiorPolygons))
    }
    
    func refreshOverlays() {
        let overlays = mapView?.overlays(in: .aboveRoads) ?? []
        mapView?.removeOverlays(overlays)
        mapView?.addOverlays(overlays, level: .aboveRoads)
    }
    
    func zoom() {
        let coords = points.map { $0.coordinate }
        let pointsRect = MKPolyline(coordinates: coords, count: coords.count).boundingMapRect
        let polylinesRect = MKMultiPolyline(polylines).boundingMapRect
        let polygonsRect = MKMultiPolygon(polygons).boundingMapRect
        let rect = pointsRect.union(polylinesRect).union(polygonsRect)
        
        let padding = UIEdgeInsets(top: 40, left: 40, bottom: 40, right: 40)
        mapView?.setVisibleMapRect(rect, edgePadding: padding, animated: true)
    }
    
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    func updateTrackingMode(_ newMode: MKUserTrackingMode) {
        guard validateAuth() else { return }
        mapView?.setUserTrackingMode(newMode, animated: true)
        if trackingMode == .followWithHeading || newMode == .followWithHeading {
            withAnimation(.easeInOut(duration: 0.25)) {
                scale = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.trackingMode = newMode
                withAnimation(.easeInOut(duration: 0.25)) {
                    self.scale = 1
                }
            }
        } else {
            trackingMode = newMode
        }
    }
    
    func updateMapType(_ newType: MKMapType) {
        mapView?.mapType = newType
        refreshOverlays()
        withAnimation(.easeInOut(duration: 0.25)) {
            degrees += 90
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.mapType = newType
            withAnimation(.easeInOut(duration: 0.25)) {
                self.degrees += 90
            }
        }
    }
}

// MARK: - MKMapViewDelegate
extension ViewModel: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let darkMode = UITraitCollection.current.userInterfaceStyle == .dark || mapView.mapType == .hybrid
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.lineWidth = 2
            renderer.strokeColor = darkMode ? UIColor(.cyan) : .link
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
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let point = annotation as? MKPointAnnotation {
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: MKMarkerAnnotationView.id, for: point)
            view.displayPriority = .required
            return view
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        let view = mapView.view(for: mapView.userLocation)
        view?.leftCalloutAccessoryView = UIView()
        view?.rightCalloutAccessoryView = UIView()
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if view is MKMarkerAnnotationView {
            mapView.deselectAnnotation(view.annotation, animated: true)
        }
    }
    
    func mapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool) {
        if !animated {
            updateTrackingMode(.none)
        }
    }
    
    @objc
    func tappedCompass() {
        guard trackingMode == .followWithHeading else { return }
        updateTrackingMode(.follow)
    }
}

// MARK: - CLLocationManagerDelegate
extension ViewModel: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authStatus = manager.authorizationStatus
        if authStatus == .denied {
            showAuthAlert = true
            updateTrackingMode(.none)
        } else if authStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }
    
    func validateAuth() -> Bool {
        showAuthAlert = authStatus == .denied
        return !showAuthAlert
    }
}

// MARK: - UIGestureRecognizer
extension ViewModel: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool { true }
}
