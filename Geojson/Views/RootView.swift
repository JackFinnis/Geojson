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
    @Environment(\.modelContext) var modelContext
    @AppStorage("sortBy") var sortBy = SortBy.name
    @State var path = NavigationPath()
    @State var urls = [URL]()
    @State var isSearching = false
    @State var searchText = ""
    @Query var files: [File]
    @Query var folders: [Folder]
    @State var error: GeoError?
    @State var showErrorAlert = false
    
    var body: some View {
        let filteredFiles = files.filter { file in
            isSearching ? file.name.localizedStandardContains(searchText) : file.folder == nil
        }.sorted(using: sortBy.fileDescriptor)
        let folders = folders.sorted(using: sortBy.folderDescriptor)
        
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if !isSearching {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 0, alignment: .top)], spacing: 0) {
                            ForEach(folders) { folder in
                                FolderRow(folder: folder)
                            }
                        }
                    }
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 0, alignment: .top)], spacing: 0) {
                        ForEach(filteredFiles) { file in
                            FileRow(file: file, loadFile: loadFile, deleteFile: deleteFile, fetchFile: fetchFile)
                        }
                    }
                }
                .padding(.horizontal, 8)
            }
            .animation(.default, value: filteredFiles)
            .animation(.default, value: folders)
            .overlay {
                if files.isEmpty && folders.isEmpty {
                    ContentUnavailableView("No Files Yet", systemImage: "mappin.and.ellipse", description: Text("Files you import will appear here.\nTap + to import a file."))
                        .allowsHitTesting(false)
                } else if filteredFiles.isEmpty && searchText.isNotEmpty {
                    ContentUnavailableView.search(text: searchText)
                        .allowsHitTesting(false)
                }
            }
            .dropDestination(for: String.self, action: removeFromFolder)
            .navigationDestination(for: FileData.self) { fileData in
                FileView(file: fileData.file, data: fileData.data, fail: fail)
            }
            .scrollDismissesKeyboard(.immediately)
            .searchable(text: $searchText, isPresented: $isSearching)
            .navigationDestination(for: Folder.self) { folder in
                FolderView(folder: folder, loadFile: loadFile, deleteFile: deleteFile, importFile: importFile, fetchFile: fetchFile)
            }
            .navigationTitle("Geodata Viewer")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        let folder = Folder()
                        modelContext.insert(folder)
                    } label: {
                        Label("Add Folder", systemImage: "folder.fill.badge.plus")
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.circle)
                    .font(.headline)
                }
                ToolbarItemGroup(placement: .primaryAction) {
                    PrimaryActions(folder: nil, importFile: importFile, fetchFile: fetchFile)
                }
            }
        }
        .alert(error?.title ?? "", isPresented: $showErrorAlert) {} message: {
            if let error {
                Text(error.description)
            }
        }
        .onOpenURL { url in
            importFile(url: url, webURL: nil, folder: nil)
        }
    }
    
    func removeFromFolder(ids: [String], point: CGPoint) -> Bool {
        let folderFiles: [File] = ids.compactMap { id in
            files.first { $0.id.uuidString == id }
        }
        guard folderFiles.isNotEmpty else { return false }
        folderFiles.forEach { file in
            file.folder = nil
        }
        return true
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
    
    func fetchFile(url: URL, folder: Folder?) async {
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
            importFile(url: temp, webURL: url, folder: folder)
        } catch {
            print(error)
            fail(error: .fileManager)
        }
    }
    
    func importFile(url source: URL, webURL: URL?, folder: Folder?) {
        let fileExtension = source.pathExtension
        let name = String(source.lastPathComponent.dropLast(fileExtension.count + 1))
        let file = File(fileExtension: fileExtension, name: name, webURL: webURL, folder: folder)
        
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
            path.append(FileData(file: file, data: geoData))
            modelContext.insert(file)
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

struct FileData: Hashable {
    let file: File
    let data: GeoData
}

struct PrimaryActions: View {
    @AppStorage("sortBy") var sortBy = SortBy.name
    @State var showFileImporter = false
    
    let folder: Folder?
    let importFile: (URL, URL?, Folder?) -> Void
    let fetchFile: (URL, Folder?) async -> Void
    
    var body: some View {
        Menu {
            Picker("Sort Files", selection: $sortBy.animation()) {
                ForEach(SortBy.allCases, id: \.self) { sortBy in
                    Text(sortBy.rawValue)
                }
            }
        } label: {
            Label("Sort Files", systemImage: "arrow.up.arrow.down")
        }
        .menuStyle(.button)
        .buttonStyle(.bordered)
        .buttonBorderShape(.circle)
        .font(.headline)
        
        Menu {
            Section("Import File") {
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
                            await fetchFile(url, folder)
                        }
                    } label: {
                        Label("Paste File URL", systemImage: "doc.on.doc")
                    }
                }
            }
        } label: {
            Label("Import File", systemImage: "plus")
        }
        .menuStyle(.button)
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.circle)
        .font(.headline)
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.json, .geojson, .gpx, .kml, .kmz]) { result in
            switch result {
            case .failure(let error):
                print(error)
            case .success(let url):
                importFile(url, nil, folder)
            }
        }
    }
}
