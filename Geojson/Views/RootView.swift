//
//  FilesView.swift
//  Geojson
//
//  Created by Jack Finnis on 10/03/2024.
//

import SwiftUI
import SwiftData
import MapKit

struct RootView: View {
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.modelContext) var modelContext
    @AppStorage("sortBy") var sortBy = SortBy.name
    @State var path = NavigationPath()
    @State var urls = [URL]()
    @State var searchText = ""
    @State var showFileImporter = false
    @Query var files: [File]
    @Query var folders: [Folder]
    
    @State var error: GeoError?
    @State var showErrorAlert = false
    
    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 0, alignment: .top)], spacing: 0) {
                    ForEach(folders.sorted(using: SortDescriptor(\Folder.name))) { folder in
                        FolderRow(folder: folder)
                    }
                    let files = files.filter { $0.folder == nil }.sorted(using: SortDescriptor(\File.name))
                    ForEach(files) { file in
                        FileRow(file: file, loadFile: loadFile, deleteFile: deleteFile, fetchFile: fetchFile)
                    }
                }
                .padding(.horizontal, 8)
            }
            .animation(.default, value: files)
            .animation(.default, value: folders)
            .overlay {
                if files.isEmpty && folders.isEmpty {
                    ContentUnavailableView("No Files Yet", systemImage: "mappin.and.ellipse", description: Text("Files you import will appear here.\nTap + to import a file."))
                        .allowsHitTesting(false)
                }
            }
            .dropDestination(for: String.self) { ids, point in
                let folderFiles: [File] = ids.compactMap { id in
                    files.first { $0.id.uuidString == id }
                }
                guard folderFiles.isNotEmpty else { return false }
                folderFiles.forEach { file in
                    file.folder = nil
                }
                return true
            }
            .navigationDestination(for: GeoData.self) { data in
                DataView(data: data, scenePhase: scenePhase, fail: fail)
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .navigationDestination(for: Folder.self) { folder in
                FolderView(folder: folder, loadFile: loadFile, deleteFile: deleteFile, fetchFile: fetchFile)
            }
            .navigationTitle("Geodata Viewer")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("Sort Files", selection: $sortBy.animation()) {
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
        .alert(error?.title ?? "", isPresented: $showErrorAlert) {} message: {
            if let error {
                Text(error.description)
            }
        }
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
    }
    
    func fail(error: GeoError) {
        self.error = error
        showErrorAlert = true
        Haptics.error()
    }
    
    func deleteFile(file: File) {
        try? FileManager.default.removeItem(at: file.url)
        modelContext.delete(file)
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
            fail(error: .fileType)
            return
        }
        
        do {
            let temp = URL.temporaryDirectory.appending(path: filename)
            try data.write(to: temp)
            importFile(url: temp, webURL: url)
        } catch {
            print(error)
            fail(error: .fileManager)
        }
    }
    
    func importFile(url source: URL, webURL: URL? = nil) {
        let fileExtension = source.pathExtension
        let name = String(source.lastPathComponent.dropLast(fileExtension.count + 1))
        let file = File(fileExtension: fileExtension, name: name, webURL: webURL)
        modelContext.insert(file)
        
        do {
            try? FileManager.default.removeItem(at: file.url)
            _ = source.startAccessingSecurityScopedResource()
            try FileManager.default.copyItem(at: source, to: file.url)
            source.stopAccessingSecurityScopedResource()
            
            loadFile(file: file)
        } catch {
            print(error)
            fail(error: .fileManager)
        }
    }
    
    func loadFile(file: File) {
        do {
            let geoData = try GeoParser().parse(url: file.url)
            file.date = .now
            path.append(geoData)
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
