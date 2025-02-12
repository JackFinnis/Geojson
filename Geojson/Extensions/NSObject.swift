//
//  NSObject.swift
//  Geojson
//
//  Created by Jack Finnis on 12/02/2025.
//

import Foundation

extension NSObject {
    static var className: String {
        String(describing: self)
    }
}
