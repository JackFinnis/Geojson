//
//  GeoData.swift
//  Geojson
//
//  Created by Jack Finnis on 10/03/2024.
//

import Foundation
import MapKit

struct GeoData: Hashable {
    let points: [Point]
    let multiPolylines: [MultiPolyline]
    let multiPolygons: [MultiPolygon]
    
    var rect: MKMapRect { multiPolygons.rect.union(multiPolylines.rect).union(points.rect) }
    var empty: Bool { points.isEmpty && multiPolylines.isEmpty && multiPolygons.isEmpty }
    
    @MainActor
    static let empty = GeoData(points: [], multiPolylines: [], multiPolygons: [])
    
    func closestOverlay(to targetCoord: CLLocationCoordinate2D) -> Annotation? {
        var closestOverlay: Annotation?
        var closestDistance: Double = .greatestFiniteMagnitude
        
        for polygon in multiPolygons.flatMap(\.polygons) where polygon.mkPolygon.boundingMapRect.padding().contains(targetCoord.point) {
            let render = MKPolygonRenderer(polygon: polygon.mkPolygon)
            let point = render.point(for: targetCoord.point)
            if render.path.contains(point) {
                return polygon
            }
        }
        
        for polyline in multiPolylines.flatMap(\.polylines) where polyline.mkPolyline.boundingMapRect.padding().contains(targetCoord.point) {
            for coord in polyline.mkPolyline.coordinates {
                let delta = coord.distance(to: targetCoord)
                if delta < closestDistance && delta < 10000 {
                    closestOverlay = polyline
                    closestDistance = delta
                }
            }
        }
        
        return closestOverlay
    }
}
