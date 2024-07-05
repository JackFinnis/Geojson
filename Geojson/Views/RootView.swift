//
//  FilesView.swift
//  Geojson
//
//  Created by Jack Finnis on 10/03/2024.
//

import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.modelContext) var modelContext
    @State var urls = [URL]()
    @State var showFileImporter = false
    @State var selectedGeoData: GeoData?
    @Query var webFiles: [WebFile]
    
    @State var error: GeoError?
    @State var showErrorAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(urls, id: \.self) { url in
                    let webFile = webFiles.first { $0.name == url.lastPathComponent }
                    NavigationLink(value: true) {
                        HStack {
                            Text(url.lastPathComponent)
                            Spacer()
                            if webFile != nil {
                                Image(systemName: "safari.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .overlay {
                        Button("") {
                            loadFile(url: url)
                        }
                    }
                    .contextMenu {
                        if let webFile {
                            Button {
                                Task {
                                    await fetchFile(url: webFile.url)
                                }
                            } label: {
                                Label("Refresh", systemImage: "arrow.clockwise")
                            }
                        }
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            deleteFile(url: url)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                Section {
                    Spacer().listRowBackground(Color.clear)
                }
            }
            .animation(.default, value: urls)
            .overlay {
                if urls.isEmpty {
                    ContentUnavailableView("No Recents", systemImage: "mappin.and.ellipse", description: Text("Recently opened files will appear here.\nTap + to open a file."))
                        .allowsHitTesting(false)
                }
            }
            .navigationDestination(item: $selectedGeoData) { data in
                DataView(data: data, scenePhase: scenePhase)
            }
            .navigationTitle("Geodata Viewer")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showFileImporter = true
                        } label: {
                            Label("Choose File", systemImage: "folder")
                        }
                        if UIPasteboard.general.hasStrings {
                            Button {
                                guard let string = UIPasteboard.general.string,
                                      let url = URL(string: string)
                                else { return }
                                Task {
                                    await fetchFile(url: url)
                                }
                            } label: {
                                Label("Paste URL", systemImage: "doc.on.doc")
                            }
                        }
                    } label: {
                        Label("Import File", systemImage: "plus")
                    }
                    .menuStyle(.button)
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.circle)
                    .font(.headline)
                }
            }
        }
        .alert("Import Failed", isPresented: $showErrorAlert) {}
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.json, .geojson, .gpx, .kml, .kmz]) { result in
            switch result {
            case .failure(let error):
                print(error)
            case .success(let url):
                importFile(url: url)
            }
        }
        .onOpenURL { url in
            importFile(url: url)
        }
        .task {
            updateLocalFiles()
        }
        .onChange(of: scenePhase) { _, scenePhase in
            if scenePhase == .active {
                updateLocalFiles()
            }
        }
    }
    
    func fail(error: GeoError) {
        self.error = error
        showErrorAlert = true
        Haptics.error()
    }
    
    func updateLocalFiles() {
        do {
            urls = try FileManager.default.contentsOfDirectory(at: .documentsDirectory, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        } catch {
            print(error)
            fail(error: .fileManager)
        }
    }
    
    func deleteFile(url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            print(error)
            fail(error: .fileManager)
        }
    }
    
    func fetchFile(url: URL) async {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(from: url)
        } catch {
            print(error)
            fail(error: .internet)
            return
        }
        
        guard let filename = response.suggestedFilename else {
            fail(error: .download)
            return
        }
        
        let webFile = WebFile(name: filename, url: url)
        modelContext.insert(webFile)
        
        do {
            let temp = URL.temporaryDirectory.appending(path: filename)
            try data.write(to: temp)
            importFile(url: temp)
        } catch {
            print(error)
            fail(error: .fileManager)
        }
    }
    
    func importFile(url source: URL) {
        let destination = URL.documentsDirectory.appending(path: source.lastPathComponent)
        let temp = URL.temporaryDirectory.appending(path: UUID().uuidString)
        do {
            _ = source.startAccessingSecurityScopedResource()
            try FileManager.default.copyItem(at: source, to: temp)
            source.stopAccessingSecurityScopedResource()
            
            try? FileManager.default.removeItem(at: destination)
            try FileManager.default.copyItem(at: temp, to: destination)
            
            updateLocalFiles()
            loadFile(url: destination)
        } catch {
            print(error)
            fail(error: .fileManager)
        }
    }
    
    func loadFile(url: URL) {
        do {
            selectedGeoData = try GeoParser().parse(url: url)
            Haptics.tap()
        } catch let error as GeoError {
            fail(error: error)
        } catch {
            print(error)
            fail(error: .unknown)
        }
    }
}

#Preview {
    RootView()
}
