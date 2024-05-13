//
//  FilesView.swift
//  Geojson
//
//  Created by Jack Finnis on 10/03/2024.
//

import SwiftUI
import StoreKit

struct FilesView: View {
    @Environment(\.requestReview) var requestReview
    @Environment(\.openURL) var openURL
    @EnvironmentObject var app: AppState
    @AppStorage("sortBy") var sortBy = SortBy.date
    @State var searchText = ""
    @State var showFileImporter = false
    
    var filteredURLs: [URL] {
        let urls: [URL]
        switch sortBy {
        case .name:
            urls = app.recentURLs.sorted(using: SortDescriptor(\.absoluteString))
        case .date:
            urls = app.recentURLs.reversed()
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
                    Button(url.lastPathComponent) {
                        app.importFile(url: url)
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            app.deleteBookmark(url: url)
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
                if app.recentURLs.isEmpty {
                    ContentUnavailableView("No Files Yet", systemImage: "mappin.and.ellipse", description: Text("Tap + to import a file"))
                        .allowsHitTesting(false)
                } else if filteredURLs.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                        .allowsHitTesting(false)
                }
            }
            .searchable(text: $searchText.animation())
            .navigationDestination(item: $app.selectedGeoData) { data in
                FileView(data: data)
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
                app.importFile(url: url)
            case .failure(let error):
                debugPrint(error)
            }
        }
        .alert("Import Failed", isPresented: $app.showError) {
            Button("OK", role: .cancel) {}
            if let fileType = app.error?.fileType {
                Button("Help") {
                    UIApplication.shared.open(fileType.helpURL)
                }
            }
        } message: {
            if let error = app.error {
                Text(error.message)
            }
        }
    }
}

#Preview {
    FilesView()
        .environmentObject(AppState.shared)
}
