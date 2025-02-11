//
//  GeoParser.swift
//  Geojson
//
//  Created by Jack Finnis on 10/03/2024.
//

import MapKit
import CoreGPX
import SwiftUI
import GoogleMapsUtils
import UniformTypeIdentifiers

class GeoParser {
    var geoData: GeoData {
        GeoData(
            points: points,
            multiPolylines: Dictionary(grouping: polylines, by: \.color).map { uiColor, polylines in
                MultiPolyline(mkMultiPolyline: MKMultiPolyline(polylines.map(\.mkPolyline)), uiColor: uiColor)
            },
            multiPolygons: Dictionary(grouping: polygons, by: \.color).map { color, polygons in
                MultiPolygon(mkMultiPolygon: MKMultiPolygon(polygons.map(\.mkPolygon)), color: color)
            }
        )
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
        
        points.append(contentsOf: root.waypoints.compactMap(Point.init))
        polylines.append(contentsOf: root.routes.map(\.points).map { points in
            let mkPolyline = MKPolyline(coords: points.compactMap(\.coord))
            return .init(mkPolyline: mkPolyline)
        })
        polylines.append(contentsOf: root.tracks.flatMap(\.segments).map { segment in
            let mkPolyline = MKPolyline(coords: segment.points.compactMap(\.coord))
            return .init(mkPolyline: mkPolyline)
        })
    }
    
    // MARK: - Parse KML
    func parseKML(data: Data, fileExtension: String) throws {
        let parser = GMUKMLParser(data: data)
        parser.parse()
        
        let placemarks = parser.placemarks.compactMap { $0 as? GMUPlacemark }
        placemarks.forEach { placemark in
            let style = parser.styles.first { $0.styleID.removingStyleVariant == placemark.styleUrl }
            if let point = placemark.geometry as? GMUPoint {
                points.append(Point(point: point, placemark: placemark, style: style))
            } else if let line = placemark.geometry as? GMULineString {
                let mkPolyline = MKPolyline(coords: line.path.coords)
                let polyline = Polyline(mkPolyline: mkPolyline, style: style)
                polylines.append(polyline)
            } else if let polygon = placemark.geometry as? GMUPolygon {
                let exteriorCoords = polygon.paths.first?.coords ?? []
                let interiorCoords = polygon.paths.dropFirst().map(\.coords)
                let mkPolygon = MKPolygon(exteriorCoords: exteriorCoords, interiorCoords: interiorCoords)
                let polygon = Polygon(mkPolygon: mkPolygon, style: style)
                polygons.append(polygon)
            }
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
