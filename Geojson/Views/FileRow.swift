//
//  FileRow.swift
//  Geojson
//
//  Created by Jack Finnis on 07/07/2024.
//

import SwiftUI
import SwiftData

struct FileRow: View {
    @Environment(\.modelContext) var modelContext
    @State var geoData: GeoData?
    
    @Bindable var file: File
    @Query var files: [File]
    @Query var folders: [Folder]
    let loadFile: (File) -> Void
    let deleteFile: (File) -> Void
    let fetchFile: (URL, Folder?) async -> Void
    
    var body: some View {
        Button {
            loadFile(file)
        } label: {
            VStack(alignment: .leading) {
                ZStack {
                    if let geoData {
                        MapView(selectedAnnotation: .constant(.none), trackingMode: .constant(.none), data: geoData, mapStandard: true, preview: true, fail: { _ in })
                    } else {
                        Rectangle()
                            .fill(.fill)
                            .overlay {
                                ProgressView()
                            }
                            .onAppear {
                                geoData = try? GeoParser().parse(url: file.url)
                            }
                    }
                }
                .aspectRatio(1, contentMode: .fit)
                .cornerRadius(10)
                .allowsHitTesting(false)
                .compositingGroup()
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(.separator))
                
                Text(file.name)
                    .multilineTextAlignment(.leading)
            }
            .padding(8)
            .background(.background)
            .contentShape(.rect(cornerRadius: 18))
            .hoverEffect()
        }
        .buttonStyle(.plain)
        .contextMenu {
            if let url = file.webURL {
                Button {
                    Task {
                        deleteFile(file)
                        await fetchFile(url, file.folder)
                    }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
            if folders.isNotEmpty {
                Menu {
                    Picker("Move", selection: $file.folder) {
                        Text("No Folder")
                            .tag(nil as Folder?)
                        ForEach(folders.sorted(using: SortBy.name.folderDescriptor)) { folder in
                            Text(folder.name)
                                .tag(folder as Folder?)
                        }
                    }
                } label: {
                    Label("Move", systemImage: "folder")
                }
            }
            Button(role: .destructive) {
                deleteFile(file)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .draggable(file.id.uuidString)
        .dropDestination(for: String.self, action: addToNewFolder)
    }
    
    func addToNewFolder(ids: [String], point: CGPoint) -> Bool {
        var folderFiles: [File] = ids.compactMap { id in
            files.first { $0.id.uuidString == id }
        }
        guard folderFiles.isNotEmpty,
              file.folder == nil
        else { return false }
        folderFiles.append(file)
        let folder = Folder()
        folder.files = folderFiles
        modelContext.insert(folder)
        return true
    }
}
