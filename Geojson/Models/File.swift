//
//  File.swift
//  Geojson
//
//  Created by Jack Finnis on 07/07/2024.
//

import Foundation
import SwiftData
import SwiftUI

@Model
class File {
    var id = UUID()
    var fileExtension: String
    var name: String
    var date: Date
    var webURL: URL?
    var folder: Folder?
    
    init(fileExtension: String, name: String, date: Date = .now, webURL: URL? = nil, folder: Folder? = nil) {
        self.fileExtension = fileExtension
        self.name = name
        self.date = date
        self.webURL = webURL
        self.folder = folder
    }
    
    var url: URL {
        URL
            .documentsDirectory
            .appending(path: id.uuidString)
            .appendingPathExtension(fileExtension)
    }
    
    func removeFile() {
        try? FileManager.default.removeItem(at: url)
    }
}
