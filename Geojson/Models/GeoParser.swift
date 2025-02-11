//
//  GeoParser.swift
//  Geojson
//
//  Created by Jack Finnis on 10/03/2024.
//

import MapKit
import CoreGPX
import RCKML
import AEXML
import SwiftUI
import UniformTypeIdentifiers

class GeoParser {
    var geoData: GeoData {
        GeoData(points: points, polylines: polylines, polygons: polygons)
    }
    
    private var points = [Point]()
    private var polylines = [Polyline]()
    private var polygons = [Polygon]()
    
    private let decoder = JSONDecoder()
    
    // MARK: - Parse File
    func parse(url: URL) throws -> GeoData {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            print(error)
            throw GeoError.readFile
        }
        
        switch url.pathExtension {
        case "json", "geojson":
            try parseGeoJSON(data: data)
        case "gpx":
            try parseGPX(data: data)
        case "kml", "kmz":
            try parseKML(data: data, fileExtension: url.pathExtension)
        default:
            throw GeoError.unsupportedFileType
        }
        
        guard !geoData.empty else {
            throw GeoError.fileEmpty
        }
        
        return geoData
    }
    
    // MARK: - Parse GeoJSON
    func parseGeoJSON(data: Data) throws {
        let objects: [MKGeoJSONObject]
        do {
            objects = try MKGeoJSONDecoder().decode(data)
        } catch {
            print(error)
            throw GeoError.invalidGeoJSON
        }
        
        objects.forEach { handleGeoJSONObject($0, properties: nil) }
    }
    
    func handleGeoJSONObject(_ object: MKGeoJSONObject, properties: Properties?) {
        if let feature = object as? MKGeoJSONFeature {
            let properties = try? decoder.decode(Properties.self, from: feature.properties ?? .init())
            feature.geometry.forEach { handleGeoJSONObject($0, properties: properties) }
        } else if let point = object as? MKPointAnnotation {
            points.append(Point(coordinate: point.coordinate, properties: properties))
        } else if let mkPolyline = object as? MKPolyline {
            polylines.append(Polyline(mkPolyline: mkPolyline, properties: properties))
        } else if let multiPolyline = object as? MKMultiPolyline {
            polylines.append(contentsOf: multiPolyline.polylines.map { Polyline(mkPolyline: $0, properties: properties) })
        } else if let mkPolygon = object as? MKPolygon {
            polygons.append(Polygon(mkPolygon: mkPolygon, properties: properties))
        } else if let multiPolygon = object as? MKMultiPolygon {
            polygons.append(contentsOf: multiPolygon.polygons.map { Polygon(mkPolygon: $0, properties: properties) })
        } else if let multiPoint = object as? MKMultiPoint {
            points.append(contentsOf: multiPoint.coordinates.map { Point(coordinate: $0, properties: properties) })
        }
    }
    
    // MARK: - Parse GPX
    func parseGPX(data: Data) throws {
        let parser = GPXParser(withData: data)
        guard let root = parser.parsedData() else {
            throw GeoError.invalidGPX
        }
        guard root.waypoints.isNotEmpty || root.routes.isNotEmpty || root.tracks.isNotEmpty else {
            throw GeoError.fileEmpty
        }
        
        points.append(contentsOf: root.waypoints.compactMap { waypoint in
            Point(waypoint: waypoint)
        })
        polylines.append(contentsOf: root.routes.map(\.points).map { points in
            let mkPolyline = MKPolyline(coords: points.compactMap(\.coord))
            return .init(mkPolyline: mkPolyline, properties: nil)
        })
        polylines.append(contentsOf: root.tracks.flatMap(\.segments).map { segment in
            let mkPolyline = MKPolyline(coords: segment.points.compactMap(\.coord))
            return .init(mkPolyline: mkPolyline, properties: nil)
        })
    }
    
    // MARK: - Parse KML
    func parseKML(data: Data, fileExtension: String) throws {
        let document: KMLDocument
        do {
            if fileExtension == "kml" {
                document = try KMLDocument(data)
            } else {
                document = try KMLDocument(kmzData: data)
            }
        } catch {
            print(error)
            throw GeoError.invalidKML
        }
        
        document.features.forEach(handleKMLFeature)
    }
    
    func handleKMLFeature(_ feature: KMLFeature) {
        if let folder = feature as? KMLContainer {
            folder.features.forEach(handleKMLFeature)
        } else if let placemark = feature as? KMLPlacemark {
            handleKMLGeometry(placemark.geometry, placemark: placemark)
        }
    }
    
    func handleKMLGeometry(_ geometry: KMLGeometry, placemark: KMLPlacemark) {
        if let multiGeometry = geometry as? KMLMultiGeometry {
            multiGeometry.geometries.forEach { handleKMLGeometry($0, placemark: placemark) }
        } else if let point = geometry as? KMLPoint {
            points.append(Point(point: point, placemark: placemark))
        } else if let lineString = geometry as? KMLLineString {
            let mkPolyline = MKPolyline(coords: lineString.coordinates.map(\.coord))
            let polyline = Polyline(mkPolyline: mkPolyline, properties: nil)
            polylines.append(polyline)
        } else if let polygon = geometry as? KMLPolygon {
            let exteriorCoords = polygon.outerBoundaryIs.coordinates.map(\.coord)
            let interiorCoords = polygon.innerBoundaryIs?.map { $0.coordinates.map(\.coord) }
            let mkPolygon = MKPolygon(exteriorCoords: exteriorCoords, interiorCoords: interiorCoords)
            let polygon = Polygon(mkPolygon: mkPolygon, properties: nil)
            polygons.append(polygon)
        }
    }
}

struct Properties: Codable {
    let name: String?
    let title: String?
    let address: String?
    let description: String?
    let color: String?
    let colour: String?
}
