//
//  Array.swift
//  Geojson
//
//  Created by Jack Finnis on 11/05/2023.
//

import Foundation
import MapKit

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var seen = Set<Element>()
        return self.filter { seen.insert($0).inserted }
    }
}

extension Array where Element: MKOverlay {
    var rect: MKMapRect {
        reduce(MKMapRect.null) { $0.union($1.boundingMapRect) }
    }
}

extension Array where Element: MKAnnotation {
    var rect: MKMapRect {
        let coords = map(\.coordinate)
        return MKPolyline(coords: coords).boundingMapRect
    }
}

extension Array where Element == String {
    var lines: String {
        joined(separator: "\n")
    }
}
