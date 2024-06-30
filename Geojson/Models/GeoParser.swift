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

class GeoParser {
    var points = [Point]()
    var polylines = [MKPolyline]()
    var polygons = [MKPolygon]()
    
    var geoData: GeoData {
        GeoData(points: points, polylines: polylines, polygons: polygons)
    }
    
    // MARK: - Parse GeoJSON
    func parseGeoJSON(data: Data) throws {
        let objects: [MKGeoJSONObject]
        do {
            objects = try MKGeoJSONDecoder().decode(data)
        } catch {
            throw GeoError.geoJSON
        }
        
        objects.forEach(handleGeoJSONObject)
    }
    
    func handleGeoJSONObject(_ object: MKGeoJSONObject) {
        if let feature = object as? MKGeoJSONFeature {
            feature.geometry.forEach(handleGeoJSONObject)
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
            points.append(contentsOf: multiPoint.coordinates.map { Point(coordinate: $0) })
        }
    }
    
    // MARK: - Parse GPX
    func parseGPX(data: Data) throws {
        let parser = GPXParser(withData: data)
        let root: GPXRoot?
        do {
            root = try parser.fallibleParsedData(forceContinue: true)
        } catch {
            throw GeoError.gpx(error)
        }
        guard let root, root.waypoints.isNotEmpty || root.routes.isNotEmpty || root.tracks.isNotEmpty else {
            throw GeoError.fileEmpty
        }
        
        handleGPXWaypoints(root.waypoints)
        root.routes.map(\.points).forEach(handleGPXWaypoints)
        polylines = root.tracks.flatMap(\.segments).map { segment in
            MKPolyline(coords: segment.points.compactMap(\.coord))
        }
    }
    
    func handleGPXWaypoints(_ waypoints: [GPXWaypoint]) {
        let points = waypoints.enumerated().compactMap { i, waypoint in
            Point(i: i + 1, waypoint: waypoint)
        }
        self.points.append(contentsOf: points)
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
        
        document.features.forEach(handleKMLFeature)
    }
    
    func handleKMLFeature(_ feature: KMLFeature) {
        if let folder = feature as? KMLContainer {
            folder.features.forEach(handleKMLFeature)
        } else if let placemark = feature as? KMLPlacemark {
            if let point = placemark.geometry as? KMLPoint {
                points.append(Point(point: point, placemark: placemark))
            } else {
                handleKMLGeometry(placemark.geometry)
            }
        }
    }
    
    func handleKMLGeometry(_ geometry: KMLGeometry) {
        if let multiGeometry = geometry as? KMLMultiGeometry {
            multiGeometry.geometries.forEach(handleKMLGeometry)
        } else if let point = geometry as? KMLPoint {
            points.append(Point(coordinate: point.coordinate.coord))
        } else if let lineString = geometry as? KMLLineString {
            polylines.append(MKPolyline(coords: lineString.coordinates.map(\.coord)))
        } else if let polygon = geometry as? KMLPolygon {
            let exteriorCoords = polygon.outerBoundaryIs.coordinates.map(\.coord)
            let interiorCoords = polygon.innerBoundaryIs?.map { $0.coordinates.map(\.coord) }
            polygons.append(MKPolygon(exteriorCoords: exteriorCoords, interiorCoords: interiorCoords))
        }
    }
}
