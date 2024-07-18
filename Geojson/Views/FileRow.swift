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
                
                Text(file.name)
                    .multilineTextAlignment(.leading)
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
                        await fetchFile(url, file.folder)
                    }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
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
