//
//  WebFile.swift
//  Geojson
//
//  Created by Jack Finnis on 05/07/2024.
//

import Foundation
import SwiftData

@Model
class WebFile {
    let name: String
    let url: URL
    
    init(name: String, url: URL) {
        self.name = name
        self.url = url
    }
}
