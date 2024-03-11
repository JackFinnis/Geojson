//
//  ViewModel.swift
//  Paddle
//
//  Created by Jack Finnis on 11/09/2022.
//

import Foundation
import MapKit
import SwiftUI
import CoreGPX
import RCKML
import AEXML

@MainActor
class AppState: NSObject, ObservableObject {
    static let shared = AppState()
    
    // MARK: - Properties
    @Published var selectedFile: File?
    
    // Storage
    @Store("recentUrlsData") var recentUrlsData = [Data]()
    @Published var recentUrls = [URL]()
    
    // Alerts
    @Published var error: GeoError?
    @Published var showError = false
    
    // MARK: - Initialiser
    private override init() {
        super.init()
        updateBookmarks()
    }
    
    func updateBookmarks() {
        recentUrls = []
        var newUrlsData = [Data]()
        for data in recentUrlsData {
            var stale = false
            guard let url = try? URL(resolvingBookmarkData: data, bookmarkDataIsStale: &stale),
                  !recentUrls.contains(url)
            else { continue }
            recentUrls.append(url)
            if stale {
                guard let newData = try? url.bookmarkData(options: .suitableForBookmarkFile, includingResourceValuesForKeys: [.fileSecurityKey], relativeTo: nil) else { continue }
                newUrlsData.append(newData)
            } else {
                newUrlsData.append(data)
            }
        }
        recentUrlsData = newUrlsData
    }
    
    // MARK: - Import Data
    func importFile(url: URL) {
        do {
            guard url.startAccessingSecurityScopedResource(),
                  let urlData = try? url.bookmarkData(options: .suitableForBookmarkFile, includingResourceValuesForKeys: [.fileSecurityKey], relativeTo: nil) else {
                throw GeoError.fileMoved
            }
            recentUrls.removeAll(url)
            recentUrlsData.removeAll(urlData)
            
            guard let type = GeoFileType(fileExtension: url.pathExtension) else {
                throw GeoError.fileType
            }
            
            let data: Data
            do {
                data = try Data(contentsOf: url)
                url.stopAccessingSecurityScopedResource()
            } catch {
                throw GeoError.fileCurrupted
            }
            
            let parser = GeoParser()
            switch type {
            case .geojson:
                try parser.parseGeoJSON(data: data)
            case .gpx:
                try parser.parseGPX(data: data)
            case .kml:
                try parser.parseKML(data: data, fileExtension: url.pathExtension)
            }
            guard !parser.file.empty else {
                throw GeoError.fileEmpty
            }
            recentUrls.append(url)
            recentUrlsData.append(urlData)
            
            selectedFile = parser.file
            Haptics.tap()
            Analytics.log(.importFile)
        } catch let error as GeoError {
            self.error = error
            showError = true
            Haptics.error()
        } catch {}
    }
}
