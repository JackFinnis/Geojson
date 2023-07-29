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
import AEXML

@MainActor
class ViewModel: NSObject, ObservableObject {
    static let shared = ViewModel()
    
    // MARK: - Properties
    // Geometry
    var points = [Point]()
    var polylines = [MKPolyline]()
    var polygons = [MKPolygon]()
    var multiPolyline: MKMultiPolyline?
    var multiPolygon: MKMultiPolygon?
    
    var empty: Bool { points.isEmpty && polylines.isEmpty && polygons.isEmpty }
    var multipleTypes: Bool { [points.isNotEmpty, polylines.isNotEmpty, polygons.isNotEmpty].filter { $0 }.count > 1 }
    @Published var selectedShapeType: GeoShapeType? { didSet {
        refreshFeatures()
        zoom()
    }}
    
    // Storage
    @Storage("recentUrlsData") var recentUrlsData = [Data]()
    @Published var recentUrls = [URL]()
    
    // Alerts
    @Published var showFailedAlert = false
    var geoError = GeoError.fileMoved { didSet {
        showFailedAlert = true
    }}
    
    // Animations
    @Published var degrees = 0.0
    @Published var scale = 1.0
    
    // MapView
    var mapView: MKMapView?
    @Published var trackingMode = MKUserTrackingMode.none
    @Published var mapType = MKMapType.standard
    
    // CLLocationManager
    let locationManager = CLLocationManager()
    var authStatus = CLAuthorizationStatus.notDetermined
    @Published var showAuthAlert = false
    
    // MARK: - Initialiser
    override init() {
        super.init()
        locationManager.delegate = self
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
            if canShowAlert {
                self.geoError = error
                Haptics.error()
            }
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
            throw GeoError.fileType
        }
        
        let data: Data
        do {
            data = try Data(contentsOf: url)
            url.stopAccessingSecurityScopedResource()
        } catch {
            throw GeoError.fileCurrupted
        }
        
        removeFeatures()
        emptyData()
        
        switch type {
        case .geojson:
            try parseGeoJSON(data: data)
        case .gpx:
            try parseGPX(data: data)
        case .kml:
            try parseKML(data: data, type: url.pathExtension)
        }
        guard !empty else {
            throw GeoError.fileEmpty
        }
        
        multiPolyline = MKMultiPolyline(polylines)
        multiPolygon = MKMultiPolygon(polygons)
        selectedShapeType = nil
        recentUrls.append(url)
        recentUrlsData.append(urlData)
        Haptics.tap()
        Analytics.log(.importFile)
    }
    
    func emptyData() {
        points = []
        polylines = []
        polygons = []
        multiPolygon = nil
        multiPolyline = nil
    }
    
    func clearRecentUrls() {
        recentUrlsData = []
        recentUrls = []
    }
    
    // MARK: - Map
    func refreshFeatures() {
        removeFeatures()
        addFeatures()
    }
    
    func removeFeatures() {
        mapView?.removeAnnotations(points)
        if let multiPolygon {
            mapView?.removeOverlay(multiPolygon)
        }
        if let multiPolyline {
            mapView?.removeOverlay(multiPolyline)
        }
    }
    
    func addFeatures() {
        if selectedShapeType == nil || selectedShapeType == .point {
            mapView?.addAnnotations(points)
        }
        if let multiPolygon, selectedShapeType == nil || selectedShapeType == .polygon {
            mapView?.addOverlay(multiPolygon, level: .aboveRoads)
        }
        if let multiPolyline, selectedShapeType == nil || selectedShapeType == .polyline {
            mapView?.addOverlay(multiPolyline, level: .aboveRoads)
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
    
    func reverseGeocode(coord: CLLocationCoordinate2D, completion: @escaping (CLPlacemark) -> Void) {
        CLGeocoder().reverseGeocodeLocation(coord.location) { placemarks, error in
            guard let placemark = placemarks?.first else { return }
            completion(placemark)
        }
    }
    
    func getMapItem(coord: CLLocationCoordinate2D, name: String?, completion: @escaping (MKMapItem) -> Void) {
        reverseGeocode(coord: coord) { placemark in
            let mapItem = MKMapItem(placemark: MKPlacemark(placemark: placemark))
            mapItem.name = name ?? placemark.name
            completion(mapItem)
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
        refreshFeatures()
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
            throw GeoError.geoJSON
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
            polylines.append(polyline)
        } else if let multiPolyline = object as? MKMultiPolyline {
            polylines.append(contentsOf: multiPolyline.polylines)
        } else if let polygon = object as? MKPolygon {
            polygons.append(polygon)
        } else if let multiPolygon = object as? MKMultiPolygon {
            polygons.append(contentsOf: multiPolygon.polygons)
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
            throw GeoError.gpx(error)
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
                MKPolyline(coords: segment.points.compactMap(\.coord))
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
    func parseKML(data: Data, type: String) throws {
        let document: KMLDocument
        do {
            if type == "kml" {
                document = try KMLDocument(data)
            } else {
                document = try KMLDocument(kmzData: data)
            }
        } catch let error as KMLError {
            throw GeoError.kml(error)
        } catch let error as AEXMLError {
            throw GeoError.aexml(error)
        } catch let error as NSError {
            throw GeoError.nsxml(XMLParser.ErrorCode(rawValue: error.code))
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
            polylines.append(MKPolyline(coords: lineString.coordinates.map(\.coord)))
        } else if let polygon = geometry as? KMLPolygon {
            polygons.append(MKPolygon(exteriorCoords: polygon.outerBoundaryIs.coordinates.map(\.coord), interiorCoords: polygon.innerBoundaryIs?.map { points in
                points.coordinates.map(\.coord)
            }))
        }
    }
}

// MARK: - MKMapViewDelegate
extension ViewModel: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let darkMode = UITraitCollection.current.userInterfaceStyle == .dark || mapView.mapType == .hybrid
        if let multiPolyline = overlay as? MKMultiPolyline {
            let renderer = MKMultiPolylineRenderer(multiPolyline: multiPolyline)
            renderer.lineWidth = 2
            renderer.strokeColor = darkMode ? UIColor(.cyan) : .link
            return renderer
        } else if let multiPolygon = overlay as? MKMultiPolygon {
            let renderer = MKMultiPolygonRenderer(multiPolygon: multiPolygon)
            renderer.lineWidth = 2
            renderer.strokeColor = .systemOrange
            renderer.fillColor = .systemOrange.withAlphaComponent(0.1)
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    
    func getButton(systemName: String) -> UIButton {
        let config = UIImage.SymbolConfiguration(font: .systemFont(ofSize: Constants.size/2))
        let image = UIImage(systemName: systemName, withConfiguration: config)
        let button = UIButton()
        button.setImage(image, for: .normal)
        button.frame.size = CGSize(width: Constants.size, height: Constants.size)
        return button
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let point = annotation as? Point {
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: MKMarkerAnnotationView.id, for: point) as? MKMarkerAnnotationView
            view?.canShowCallout = true
            view?.animatesWhenAdded = true
            view?.displayPriority = .required
            view?.glyphText = point.index == nil ? nil : String(point.index!)
            view?.rightCalloutAccessoryView = getButton(systemName: "arrow.triangle.turn.up.right.circle")
            return view
        } else if #available(iOS 16, *), let feature = annotation as? MKMapFeatureAnnotation {
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: MKMarkerAnnotationView.id, for: feature) as? MKMarkerAnnotationView
            view?.canShowCallout = true
            view?.markerTintColor = feature.iconStyle?.backgroundColor
            view?.rightCalloutAccessoryView = getButton(systemName: "arrow.triangle.turn.up.right.circle")
            return view
        } else if let mapItem = annotation as? MKMapItem {
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: MKMarkerAnnotationView.id, for: mapItem) as? MKMarkerAnnotationView
            view?.canShowCallout = true
            view?.animatesWhenAdded = true
            view?.rightCalloutAccessoryView = getButton(systemName: "arrow.triangle.turn.up.right.circle")
            return view
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        let view = mapView.view(for: mapView.userLocation)
        view?.rightCalloutAccessoryView = getButton(systemName: "map")
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if #available(iOS 16, *), let feature = view.annotation as? MKMapFeatureAnnotation {
            let request = MKMapItemRequest(mapFeatureAnnotation: feature)
            request.getMapItem { mapItem, error in
                mapItem?.openInMaps()
            }
        } else if let mapItem = view.annotation as? MKMapItem {
            mapItem.openInMaps()
        } else if let point = view.annotation as? Point {
            getMapItem(coord: point.coordinate, name: point.title) { mapItem in
                mapItem.openInMaps()
            }
        } else if let user = view.annotation as? MKUserLocation {
            MKMapItem.forCurrentLocation().openInMaps()
        }
    }
    
    func mapView(_ mapView: MKMapView, didDeselect annotation: MKAnnotation) {
        if let mapItem = annotation as? MKMapItem {
            mapView.removeAnnotation(mapItem)
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
    func requestLocationAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func locationManagerDidChangeAuthorization(_ locationManager: CLLocationManager) {
        authStatus = locationManager.authorizationStatus
        validateAuth()
    }
    
    @discardableResult func validateAuth() -> Bool {
        showAuthAlert = authStatus == .denied
        return !showAuthAlert
    }
}

// MARK: - UIGestureRecognizer
extension ViewModel: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool { true }
    
    func getCoord(from gesture: UIGestureRecognizer) -> CLLocationCoordinate2D? {
        guard let mapView = mapView else { return nil }
        let point = gesture.location(in: mapView)
        return mapView.convert(point, toCoordinateFrom: mapView)
    }
    
    @objc
    func handlePress(_ press: UILongPressGestureRecognizer) {
        guard press.state == .began, let coord = getCoord(from: press) else { return }
        Haptics.tap()
        getMapItem(coord: coord, name: nil) { mapItem in
            self.mapView?.addAnnotation(mapItem)
            self.mapView?.selectAnnotation(mapItem, animated: true)
        }
    }
}
