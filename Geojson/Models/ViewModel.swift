//
//  ViewModel.swift
//  Paddle
//
//  Created by Jack Finnis on 11/09/2022.
//

import Foundation
import MapKit
import SwiftUI
import CoreGPX
import RCKML

@MainActor
class ViewModel: NSObject, ObservableObject {
    static let shared = ViewModel()
    
    // MARK: - Properties
    // Geometry
    var points = [Point]()
    var polylines = [Polyline]()
    var polygons = [Polygon]()
    var empty: Bool { points.isEmpty && polylines.isEmpty && polygons.isEmpty }
    var multipleTypes: Bool { [points.isNotEmpty, polylines.isNotEmpty, polygons.isNotEmpty].filter { $0 }.count > 1 }
    @Published var selectedShapeType: GeoShapeType? { didSet {
        refreshMap()
        zoom()
    }}
    
    // MapView
    var mapView: MKMapView?
    @Published var trackingMode = MKUserTrackingMode.none
    @Published var mapType = MKMapType.standard
    
    // Storage
    @Storage("recentUrlsData") var recentUrlsData = [Data]()
    @Published var recentUrls = [URL]()
    
    // Alerts
    @Published var geoError = GeoError.fileMoved
    @Published var showFailedAlert = false
    
    // Animations
    @Published var degrees = 0.0
    @Published var scale = 1.0
    
    // CLLocationManager
    let manager = CLLocationManager()
    var authStatus = CLAuthorizationStatus.notDetermined
    @Published var showAuthAlert = false
    
    // MARK: - Initialiser
    override init() {
        super.init()
        manager.delegate = self
        updateBookmarks()
    }
    
    func updateBookmarks() {
        recentUrls = []
        var newUrlsData = [Data]()
        for data in recentUrlsData {
            var stale = false
            guard let url = try? URL(resolvingBookmarkData: data, bookmarkDataIsStale: &stale),
                  !recentUrls.contains(url)
            else { continue }
            recentUrls.append(url)
            if stale {
                guard let newData = try? url.bookmarkData(options: .suitableForBookmarkFile, includingResourceValuesForKeys: [.fileSecurityKey], relativeTo: nil) else { continue }
                newUrlsData.append(newData)
            } else {
                newUrlsData.append(data)
            }
        }
        recentUrlsData = newUrlsData
    }
    
    // MARK: - Import Data
    func importFile(url: URL, canShowAlert: Bool) {
        do {
            try importFile(url: url)
        } catch let error as GeoError {
            self.geoError = error
            showFailedAlert = true
            Haptics.error()
        } catch {}
    }
    
    func importFile(url: URL) throws {
        guard url.startAccessingSecurityScopedResource(),
              let urlData = try? url.bookmarkData(options: .suitableForBookmarkFile, includingResourceValuesForKeys: [.fileSecurityKey], relativeTo: nil) else {
            throw GeoError.fileMoved
        }
        recentUrls.removeAll(url)
        recentUrlsData.removeAll(urlData)
        
        guard let type = GeoFileType(fileExtension: url.pathExtension) else {
            throw GeoError.unsupportedFileType
        }
        
        let data: Data
        do {
            data = try Data(contentsOf: url)
            url.stopAccessingSecurityScopedResource()
        } catch {
            throw GeoError.fileCurrupted
        }
        
        switch type {
        case .geojson:
            try parseGeoJSON(data: data)
        case .gpx:
            try parseGPX(data: data)
        case .kml:
            try parseKML(data: data)
        }
        guard !empty else {
            throw GeoError.fileEmpty
        }
        
        selectedShapeType = nil // Refreshes overlays & updates view
        zoom()
        Haptics.tap()
        recentUrls.append(url)
        recentUrlsData.append(urlData)
    }
    
    func emptyData() {
        points = []
        polylines = []
        polygons = []
    }
    
    // MARK: - Map
    func refreshMap() {
        mapView?.removeAnnotations(mapView?.annotations ?? [])
        mapView?.removeOverlays(mapView?.overlays ?? [])
        
        if selectedShapeType == nil || selectedShapeType == .point {
            mapView?.addAnnotations(points)
        }
        if selectedShapeType == nil || selectedShapeType == .polygon {
            mapView?.addOverlays(polygons, level: .aboveRoads)
        }
        if selectedShapeType == nil || selectedShapeType == .polyline {
            mapView?.addOverlays(polylines, level: .aboveRoads)
        }
    }
    
    func zoom() {
        let points = (selectedShapeType == nil || selectedShapeType == .point) ? points : []
        let rect = points.rect.union(mapView?.overlays.rect ?? .null)
        let padding = 30.0
        let insets = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        mapView?.setVisibleMapRect(rect, edgePadding: insets, animated: true)
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
        refreshMap()
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

// MARK: - Parse GeoJSON
extension ViewModel {
    func parseGeoJSON(data: Data) throws {
        let objects: [MKGeoJSONObject]
        do {
            objects = try MKGeoJSONDecoder().decode(data)
        } catch {
            throw GeoError.invalidGeoJSON
        }
        guard objects.isNotEmpty else {
            throw GeoError.fileEmpty
        }
        
        emptyData()
        objects.forEach(handleObject)
    }
    
    func handleObject(_ object: MKGeoJSONObject) {
        if let feature = object as? MKGeoJSONFeature {
            feature.geometry.forEach(handleObject)
        } else if let point = object as? MKPointAnnotation {
            points.append(Point(coordinate: point.coordinate))
        } else if let polyline = object as? MKPolyline {
            polylines.append(Polyline(mkPolyline: polyline))
        } else if let multiPolyline = object as? MKMultiPolyline {
            polylines.append(contentsOf: multiPolyline.polylines.map(Polyline.init))
        } else if let polygon = object as? MKPolygon {
            polygons.append(Polygon(mkPolygon: polygon))
        } else if let multiPolygon = object as? MKMultiPolygon {
            polygons.append(contentsOf: multiPolygon.polygons.map(Polygon.init))
        } else if let multiPoint = object as? MKMultiPoint {
            points.append(contentsOf: multiPoint.coordinates.map(Point.init))
        }
    }
}

// MARK: - Parse GPX
extension ViewModel {
    func parseGPX(data: Data) throws {
        let parser = GPXParser(withData: data)
        let root: GPXRoot?
        do {
            root = try parser.fallibleParsedData(forceContinue: false)
        } catch {
            throw GeoError.invalidGPX(error)
        }
        guard let root, root.waypoints.isNotEmpty || root.routes.isNotEmpty || root.tracks.isNotEmpty else {
            throw GeoError.fileEmpty
        }
        
        emptyData()
        handleWaypoints(root.waypoints)
        root.routes.forEach { route in
            handleWaypoints(route.points)
        }
        root.tracks.forEach { track in
            polylines.append(contentsOf: track.segments.map { segment in
                Polyline(coords: segment.points.compactMap(\.coord))
            })
        }
    }
    
    func handleWaypoints(_ waypoints: [GPXWaypoint]) {
        var i = 1
        waypoints.forEach { waypoint in
            if let point = Point(i: i, waypoint: waypoint) {
                points.append(point)
                i += 1
            }
        }
    }
}

// MARK: - Parse KML
extension ViewModel {
    func parseKML(data: Data) throws {
        let document: KMLDocument
        do {
            document = try KMLDocument(data)
        } catch let error as KMLError {
            throw GeoError.invalidKML(error)
        } catch {
            throw GeoError.fileEmpty
        }
        guard document.features.isNotEmpty else {
            throw GeoError.fileEmpty
        }
        
        emptyData()
        document.features.forEach(handleKMLFeature)
    }
    
    func handleKMLFeature(_ feature: KMLFeature) {
        if let folder = feature as? KMLFolder {
            folder.features.forEach(handleKMLFeature)
        } else if let placemark = feature as? KMLPlacemark {
            if let point = placemark.geometry as? KMLPoint {
                points.append(Point(point: point, placemark: placemark))
            } else {
                handleGeometry(placemark.geometry)
            }
        }
    }
    
    func handleGeometry(_ geometry: KMLGeometry) {
        if let multiGeometry = geometry as? KMLMultiGeometry {
            multiGeometry.geometries.forEach(handleGeometry)
        } else if let point = geometry as? KMLPoint {
            points.append(Point(coordinate: point.coordinate.coord))
        } else if let lineString = geometry as? KMLLineString {
            polylines.append(Polyline(coords: lineString.coordinates.map(\.coord)))
        } else if let polygon = geometry as? KMLPolygon {
            polygons.append(Polygon(exteriorCoords: polygon.outerBoundaryIs.coordinates.map(\.coord), interiorCoords: polygon.innerBoundaryIs?.map { points in
                points.coordinates.map(\.coord)
            }))
        }
    }
}

// MARK: - MKMapViewDelegate
extension ViewModel: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let darkMode = UITraitCollection.current.userInterfaceStyle == .dark || mapView.mapType == .hybrid
        if let polyline = overlay as? Polyline {
            let renderer = MKPolylineRenderer(polyline: polyline.mkPolyline)
            renderer.lineWidth = 2
            renderer.strokeColor = darkMode ? UIColor(.cyan) : .link
            return renderer
        } else if let polygon = overlay as? Polygon {
            let renderer = MKPolygonRenderer(polygon: polygon.mkPolygon)
            renderer.lineWidth = 2
            renderer.strokeColor = .systemOrange
            renderer.fillColor = .systemOrange.withAlphaComponent(0.1)
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let point = annotation as? Point {
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: MKMarkerAnnotationView.id, for: point) as? MKMarkerAnnotationView
            view?.displayPriority = .required
            view?.glyphText = point.index == nil ? nil : String(point.index!)
            return view
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        let view = mapView.view(for: mapView.userLocation)
        view?.leftCalloutAccessoryView = UIView()
        view?.rightCalloutAccessoryView = UIView()
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
