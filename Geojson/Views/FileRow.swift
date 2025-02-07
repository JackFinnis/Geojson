//
//  FileRow.swift
//  Geojson
//
//  Created by Jack Finnis on 07/07/2024.
//

import SwiftUI
import SwiftData

struct FileRow: View {
    @Bindable var file: File
    @Query var folders: [Folder]
    let loadFile: (File) -> Void
    let fetchFile: (URL, Folder?) async -> Void
    
    @State var geoData: GeoData?
    
    var body: some View {
        Button {
            loadFile(file)
        } label: {
            VStack(alignment: .leading) {
                ZStack {
                    if let geoData {
                        MapView(selectedPoint: .constant(.none), trackingMode: .constant(.none), data: geoData, mapStandard: true, preview: true, fail: { _ in })
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
        }
        .buttonStyle(.plain)
        .contextMenu {
            if let url = file.webURL {
                let folder = file.folder
                Button {
                    Task {
                        file.delete()
                        await fetchFile(url, folder)
                    }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
            if folders.isNotEmpty {
                Menu {
                    Picker("Move...", selection: $file.folder) {
                        Text("No Folder")
                            .tag(nil as Folder?)
                        ForEach(folders.sorted(using: SortBy.name.folderComparator)) { folder in
                            Text(folder.name)
                                .tag(folder as Folder?)
                        }
                    }
                } label: {
                    Label("Move...", systemImage: "folder")
                }
            }
            Button(role: .destructive) {
                file.delete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
