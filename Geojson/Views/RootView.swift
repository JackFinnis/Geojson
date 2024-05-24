//
//  FilesView.swift
//  Geojson
//
//  Created by Jack Finnis on 10/03/2024.
//

import SwiftUI
import StoreKit

struct RootView: View {
    @Environment(\.scenePhase) var scenePhase
    @AppStorage("sortBy") var sortBy = SortBy.date
    @AppState("recentURLsData") var recentURLsData = [Data]()
    @State var searchText = ""
    @State var showFileImporter = false
    @State var selectedGeoData: GeoData?
    @State var recentURLs = [URL]()
    @State var error: GeoError?
    @State var showError = false
    
    var filteredURLs: [URL] {
        let urls: [URL]
        switch sortBy {
        case .name:
            urls = recentURLs.sorted(using: SortDescriptor(\.absoluteString))
        case .date:
            urls = recentURLs.reversed()
        }
        if searchText.isEmpty {
            return urls
        } else {
            return urls.filter { $0.lastPathComponent.localizedStandardContains(searchText) }
        }
    }
    
    var body: some View {
        let filteredURLs = filteredURLs
        NavigationStack {
            List {
                ForEach(filteredURLs, id: \.self) { url in
                    NavigationLink(url.lastPathComponent, value: true)
                        .overlay {
                            Button("") {
                                importFile(url: url)
                            }
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                deleteBookmark(url: url)
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                }
                Section {
                    Spacer().listRowBackground(Color.clear)
                }
            }
            .contentMargins(.vertical, 0)
            .overlay {
                if recentURLs.isEmpty {
                    ContentUnavailableView("No Files Yet", systemImage: "mappin.and.ellipse", description: Text("Tap + to import a file"))
                        .allowsHitTesting(false)
                } else if filteredURLs.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                        .allowsHitTesting(false)
                }
            }
            .searchable(text: $searchText.animation())
            .navigationDestination(item: $selectedGeoData) { data in
                DataView(data: data, scenePhase: scenePhase)
            }
            .navigationTitle("Geodata Viewer")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("Sort Icons", selection: $sortBy.animation()) {
                            ForEach(SortBy.allCases, id: \.self) { sortBy in
                                Text(sortBy.rawValue)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                    .menuStyle(.button)
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.circle)
                    .font(.headline)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showFileImporter = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.circle)
                    .font(.headline)
                }
            }
        }
        .animation(.default, value: filteredURLs)
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: GeoFileType.allUTTypes) { result in
            switch result {
            case .success(let url):
                importFile(url: url)
            case .failure(let error):
                debugPrint(error)
            }
        }
        .alert("Import Failed", isPresented: $showError) {
            Button("Cancel", role: .cancel) {}
            if let fileType = error?.fileType {
                Button("Open") {
                    UIApplication.shared.open(fileType.helpURL)
                }
            }
        } message: {
            if let error = error, let fileType = error.fileType {
                Text("\(error.message)\n\(fileType.helpURLName) can help spot the problem.")
            }
        }
        .onChange(of: scenePhase) { _, scenePhase in
            if scenePhase == .active {
                updateBookmarks()
            }
        }
        .onOpenURL { url in
            importFile(url: url)
        }
        .onAppear {
            updateBookmarks()
        }
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
        } catch let error as GeoError {
            self.error = error
            showError = true
            Haptics.error()
        } catch {}
    }
}

#Preview {
    RootView()
}
