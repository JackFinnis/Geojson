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
    @Published var selectedGeoData: GeoData?
    @Published var scenePhase: ScenePhase?
    
    // Storage
    @Store("recentUrlsData") var recentURLsData = [Data]()
    @Published var recentURLs = [URL]()
    
    // Alerts
    @Published var error: GeoError?
    @Published var showError = false
    
    // MARK: - Initialiser
    private override init() {
        super.init()
        updateBookmarks()
    }
    
    func updateBookmarks() {
        recentURLs = []
        recentURLsData = recentURLsData.compactMap { data in
            var stale = false
            guard let url = try? URL(resolvingBookmarkData: data, bookmarkDataIsStale: &stale), !recentURLs.contains(url) else { return nil }
            recentURLs.append(url)
            if stale {
                guard let newData = try? url.bookmarkData(options: .suitableForBookmarkFile, includingResourceValuesForKeys: [.fileSecurityKey], relativeTo: nil) else { return nil }
                return newData
            } else {
                return data
            }
        }
    }
    
    func deleteBookmark(url: URL) {
        recentURLs.removeAll(url)
        var stale = false
        recentURLsData.removeAll { data in
            (try? url == URL(resolvingBookmarkData: data, bookmarkDataIsStale: &stale)) ?? true
        }
    }
    
    func importFile(url: URL) {
        do {
            guard url.startAccessingSecurityScopedResource(),
                  let urlData = try? url.bookmarkData(options: .suitableForBookmarkFile, includingResourceValuesForKeys: [.fileSecurityKey], relativeTo: nil) else {
                throw GeoError.fileMoved
            }
            recentURLs.removeAll(url)
            recentURLsData.removeAll(urlData)
            
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
            guard !parser.geoData.empty else {
                throw GeoError.fileEmpty
            }
            recentURLs.append(url)
            recentURLsData.append(urlData)
            
            selectedGeoData = parser.geoData
            Haptics.tap()
        } catch let error as GeoError {
            self.error = error
            showError = true
            Haptics.error()
        } catch {}
    }
}
