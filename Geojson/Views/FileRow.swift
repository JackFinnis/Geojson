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
    @FocusState var focused: Bool
    @State var geoData: GeoData?
    
    @Bindable var file: File
    @Query var files: [File]
    let loadFile: (File) -> Void
    let deleteFile: (File) -> Void
    let fetchFile: (URL) async -> Void
    
    var body: some View {
        Button {
            loadFile(file)
        } label: {
            VStack(alignment: .leading) {
                ZStack {
                    if let geoData {
                        MapView(selectedAnnotation: .constant(nil), trackingMode: .constant(.none), data: geoData, mapStandard: true, preview: true)
                            .overlay(alignment: .bottomTrailing) {
                                if file.webURL != nil {
                                    Image(systemName: "safari.fill")
                                        .foregroundStyle(.white, Color.accentColor)
                                        .padding(5)
                                }
                            }
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
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(.fill))
                
                TextField("Name", text: $file.name, axis: .vertical)
                    .focused($focused)
                    .submitLabel(.done)
                    .textInputAutocapitalization(.words)
                    .multilineTextAlignment(.leading)
                    .onChange(of: file.name) { _, name in
                        if file.name.last == "\n" {
                            focused = false
                            file.name = file.name.trimmingCharacters(in: .whitespacesAndNewlines)
                            if file.name.isEmpty {
                                file.name = "File"
                            }
                        }
                    }
            }
            .padding(8)
            .background(.background)
        }
        .foregroundStyle(.primary)
        .contextMenu {
            if let url = file.webURL {
                Button {
                    Task {
                        deleteFile(file)
                        await fetchFile(url)
                    }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
            Button {
                focused = true
            } label: {
                Label("Rename", systemImage: "pencil")
            }
            Button(role: .destructive) {
                deleteFile(file)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .draggable(file.id.uuidString)
        .dropDestination(for: String.self) { ids, point in
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
}
