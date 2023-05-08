//
//  ViewModel.swift
//  Paddle
//
//  Created by Jack Finnis on 11/09/2022.
//

import Foundation
import MapKit
import SwiftUI
import GeoJSONPackage
import CoreGPX
import RCKML

@MainActor
class ViewModel: NSObject, ObservableObject {
    static let shared = ViewModel()
    
    // MARK: - Properties
    // Geometry
    @Published var points = [MKPointAnnotation]()
    @Published var polylines = [MKPolyline]()
    @Published var polygons = [MKPolygon]()
    var empty: Bool { points.isEmpty && polylines.isEmpty && polygons.isEmpty }
    var multipleTypes: Bool { [points.isNotEmpty, polylines.isNotEmpty, polygons.isNotEmpty].filter { $0 }.count > 1 }
    @Published var selectedShapeType: GeoShapeType? { didSet {
        refreshMap()
    }}
    
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
    @Published var geoError = GeoError.fileMoved
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
        guard let type = GeoFileType(fileExtension: url.pathExtension) else {
            throw GeoError.unsupportedFileType
        }
        
        guard url.startAccessingSecurityScopedResource(),
              let urlData = try? url.bookmarkData(options: .suitableForBookmarkFile, includingResourceValuesForKeys: [.fileSecurityKey], relativeTo: nil)
        else {
            throw GeoError.fileMoved
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
        case .shp:
            try parseShapefile()
        }
        
        selectedShapeType = nil
        refreshMap()
        zoom()
        Haptics.tap()
        if !recentUrlsData.contains(urlData) {
            recentUrlsData.append(urlData)
        }
    }
    
    func emptyData() {
        points = []
        polylines = []
        polygons = []
    }
    
    func refreshMap() {
        mapView?.removeAnnotations(mapView?.annotations ?? [])
        mapView?.removeOverlays(mapView?.overlays ?? [])
        
        if selectedShapeType == nil || selectedShapeType == .point {
            mapView?.addAnnotations(points)
        } else if selectedShapeType == nil || selectedShapeType == .polygon {
            mapView?.addOverlays(polygons, level: .aboveRoads)
        } else if selectedShapeType == nil || selectedShapeType == .polyline {
            mapView?.addOverlays(polylines, level: .aboveRoads)
        }
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
            throw GeoError.invalidGeoJSON
        }
        guard features.isNotEmpty else {
            throw GeoError.fileEmpty
        }
        
        emptyData()
        features.compactMap(\.geometry).forEach(handleGeometry)
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
        guard let root else {
            throw GeoError.fileEmpty
        }
        
        points = root.waypoints.compactMap { waypoint in
            guard let lat = waypoint.latitude, let long = waypoint.longitude else { return nil }
            let point = MKPointAnnotation()
            point.coordinate = CLLocationCoordinate2DMake(lat, long)
            return point
        }
        polylines.append(contentsOf: root.routes.compactMap { route in
            let coords = route.points.compactMap { point -> CLLocationCoordinate2D? in
                guard let lat = point.latitude, let long = point.longitude else { return nil }
                return CLLocationCoordinate2DMake(lat, long)
            }
            guard coords.isNotEmpty else { return nil }
            return MKPolyline(coordinates: coords, count: coords.count)
        })
        polylines.append(contentsOf: root.tracks.map { track in
            track.segments.compactMap { segment -> MKPolyline? in
                let coords = segment.points.compactMap { point -> CLLocationCoordinate2D? in
                    guard let lat = point.latitude, let long = point.longitude else { return nil }
                    return CLLocationCoordinate2DMake(lat, long)
                }
                guard coords.isNotEmpty else { return nil }
                return MKPolyline(coordinates: coords, count: coords.count)
            }
        }.joined())
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
        } catch { return }
        
        document.features.forEach(handleKMLFeature)
    }
    
    func handleKMLFeature(_ feature: KMLFeature) {
        if let folder = feature as? KMLFolder {
            folder.features.forEach(handleKMLFeature)
        } else if let placemark = feature as? KMLPlacemark {
            handleGeometry(placemark.geometry)
        }
    }
    
    func handleGeometry(_ geometry: KMLGeometry) {
        if let lineString = geometry as? KMLLineString {
            let coords = lineString.coordinates.map(\.coord)
            polylines.append(MKPolyline(coordinates: coords, count: coords.count))
        } else if let multiGeometry = geometry as? KMLMultiGeometry {
            multiGeometry.geometries.forEach(handleGeometry)
        } else if let kmlPoint = geometry as? KMLPoint {
            let point = MKPointAnnotation()
            point.coordinate = kmlPoint.coordinate.coord
            points.append(point)
        } else if let polygon = geometry as? KMLPolygon {
            let exteriorCoords = polygon.outerBoundaryIs.coordinates.map(\.coord)
            let interiorPolygons = polygon.innerBoundaryIs?.map { positions in
                let coords = positions.coordinates.map(\.coord)
                return MKPolygon(coordinates: coords, count: coords.count)
            }
            polygons.append(MKPolygon(coordinates: exteriorCoords, count: exteriorCoords.count, interiorPolygons: interiorPolygons))
        }
    }
}

// MARK: - Parse Shapefile
extension ViewModel {
    func parseShapefile() throws {
        let reader: ShapefileReader
        do {
            reader = try ShapefileReader(path: "hello.shp") //todo
        } catch {
            throw GeoError.invalidShapefile
        }
        
        reader.shapeAndRecordGenerator().forEach { shape, record in
            switch shape.shapeType {
            case .nullShape: break
            case .point, .pointM, .pointZ, .multipoint, .multipointM, .multipointZ:
                shape.partPointsGenerator().forEach { points in
                    points.forEach { point in
                        let annotation = MKPointAnnotation()
                        annotation.coordinate = point.coord
                        self.points.append(annotation)
                    }
                }
            case .polyLine, .polylineM, .polylineZ:
                shape.partPointsGenerator().forEach { points in
                    let coords = points.map(\.coord)
                    polylines.append(MKPolyline(coordinates: coords, count: coords.count))
                }
            case .polygon, .polygonZ, .polygonM, .multipatch:
                let generator = shape.partPointsGenerator()
                guard let exterior = generator.next() else { return }
                let exteriorCoords = exterior.map(\.coord)
                var interiorPolygons = [MKPolygon]()
                var interior = generator.next()
                while interior != nil {
                    let coords = interior!.map(\.coord)
                    interiorPolygons.append(MKPolygon(coordinates: coords, count: coords.count))
                }
                polygons.append(MKPolygon(coordinates: exteriorCoords, count: exteriorCoords.count, interiorPolygons: interiorPolygons))
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
