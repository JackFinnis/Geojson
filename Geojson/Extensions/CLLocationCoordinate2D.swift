//
//  CLLocationCoordinate2D.swift
//  Visited
//
//  Created by Jack Finnis on 07/05/2023.
//

import MapKit

extension CLLocationCoordinate2D {
    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
}

extension CLLocationCoordinate2D: @retroactive Encodable {
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(longitude)
        try container.encode(latitude)
    }
}

extension CLLocationCoordinate2D: @retroactive Decodable {
    public init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let longitude = try container.decode(CLLocationDegrees.self)
        let latitude = try container.decode(CLLocationDegrees.self)
        self.init(latitude: latitude, longitude: longitude)
    }
}

extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

extension CLLocationCoordinate2D: @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(latitude)
        hasher.combine(longitude)
    }
}
