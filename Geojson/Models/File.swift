//
//  File.swift
//  Geojson
//
//  Created by Jack Finnis on 07/07/2024.
//

import Foundation
import SwiftData

@Model
class File {
    let id = UUID()
    let fileExtension: String
    var name: String
    var date: Date
    var webURL: URL?
    
    init(fileExtension: String, name: String, date: Date = .now, webURL: URL? = nil) {
        self.fileExtension = fileExtension
        self.name = name
        self.date = date
        self.webURL = webURL
    }
    
    var url: URL {
        URL.documentsDirectory
            .appending(path: id.uuidString)
            .appendingPathExtension(fileExtension)
    }
}
