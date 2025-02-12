//
//  FilesView.swift
//  Geojson
//
//  Created by Jack Finnis on 10/03/2024.
//

import SwiftUI
import SwiftData
import MapKit

struct FoldersView: View {
    @Environment(\.modelContext) var modelContext
    @State var path = NavigationPath()
    @State var urls: [URL] = []
    @State var isSearching = false
    @State var searchText = ""
    @Query var files: [File]
    @Query var folders: [Folder]
    @State var error: GeoError?
    
    var body: some View {
        let filteredFiles = files.filter { file in
            isSearching ? file.name.localizedStandardContains(searchText) : file.folder == nil
        }
        
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
                            FileRow(file: file, loadFile: loadFile, fetchFile: fetchFile)
                        }
                    }
                }
                .padding(.horizontal, 8)
            }
            .scrollDismissesKeyboard(.immediately)
            .searchable(text: $searchText, isPresented: $isSearching)
            .navigationTitle("Geodata Viewer")
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        let folder = Folder()
                        modelContext.insert(folder)
                    } label: {
                        Label("New Folder", systemImage: "folder.badge.plus")
                    }
                }
                ToolbarItem(placement: .status) {
                    Text(files.count.formatted(singular: "file"))
                        .font(.subheadline)
                }
                ToolbarItem(placement: .bottomBar) {
                    ImportButton(folder: nil, importFile: importFile, fetchFile: fetchFile)
                }
            }
            .navigationDestination(for: Folder.self) { folder in
                FolderView(folder: folder, loadFile: loadFile, importFile: importFile, fetchFile: fetchFile)
            }
            .navigationDestination(for: FileData.self) { fileData in
                FileView(file: fileData.file, data: fileData.data, fail: fail)
            }
        }
        .overlay {
            if files.isEmpty && folders.isEmpty {
                ContentUnavailableView("No Files Yet", systemImage: "mappin.and.ellipse", description: Text("Files you import will appear here.\nTap + to import a file."))
                    .allowsHitTesting(false)
            } else if filteredFiles.isEmpty && searchText.isNotEmpty {
                ContentUnavailableView.search(text: searchText)
                    .allowsHitTesting(false)
            }
        }
        .alert("Import Failed", isPresented: .init(get: {
            error != nil
        }, set: { isPresented in
            if !isPresented {
                error = nil
            }
        })) {
            // no actions
        } message: {
            if let error {
                Text(error.description)
            }
        }
        .onOpenURL { url in
            importFile(url: url, webURL: nil, folder: nil)
        }
    }
    
    func fail(error: GeoError) {
        self.error = error
        Haptics.error()
    }
    
    func fetchFile(url: URL, folder: Folder?) async {
        guard UIApplication.shared.canOpenURL(url) else {
            fail(error: .invalidURL)
            return
        }
        
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(from: url)
        } catch {
            print(error)
            fail(error: .noInternet)
            return
        }
        
        guard let filename = response.suggestedFilename else {
            fail(error: .unsupportedFileType)
            return
        }
        
        do {
            let temp = URL.temporaryDirectory.appending(path: filename)
            try data.write(to: temp)
            importFile(url: temp, webURL: url, folder: folder)
        } catch {
            print(error)
            fail(error: .writeFile)
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
            fail(error: .writeFile)
        }
    }
    
    func loadFile(file: File) {
        do {
            let geoData = try GeoParser().parse(url: file.url)
            file.date = .now
            path.append(FileData(file: file, data: geoData))
            modelContext.insert(file)
            Haptics.tap()
        } catch {
            fail(error: error)
        }
    }
}

struct FileData: Hashable {
    let file: File
    let data: GeoData
}

#Preview {
    FoldersView()
}

struct ImportButton: View {
    let folder: Folder?
    let importFile: (URL, URL?, Folder?) -> Void
    let fetchFile: (URL, Folder?) async -> Void
    
    @State var showFileImporter = false
    
    var body: some View {
        Menu {
            Section("Import File") {
                Button {
                    showFileImporter = true
                } label: {
                    Label("Choose File...", systemImage: "folder")
                }
                Button {
                    guard let string = UIPasteboard.general.string,
                          let url = URL(string: string)
                    else { return }
                    let folder = folder
                    Task {
                        await fetchFile(url, folder)
                    }
                } label: {
                    Label("Paste File URL", systemImage: "document.on.clipboard")
                }
            }
        } label: {
            Label("Import File", systemImage: "plus")
        }
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: GeoFileType.allCases.map(\.type)) { result in
            switch result {
            case .failure(let error):
                print(error)
            case .success(let url):
                importFile(url, nil, folder)
            }
        }
    }
}
