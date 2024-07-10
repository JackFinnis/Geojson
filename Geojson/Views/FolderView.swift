//
//  FolderView.swift
//  Geojson
//
//  Created by Jack Finnis on 10/07/2024.
//

import SwiftUI

struct FolderView: View {
    @Bindable var folder: Folder
    let loadFile: (File) -> Void
    let deleteFile: (File) -> Void
    let fetchFile: (URL) async -> Void
    
    var body: some View {
        let files = folder.files.sorted(using: SortDescriptor(\File.name))
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 0, alignment: .top)], spacing: 0) {
                ForEach(files) { file in
                    FileRow(file: file, loadFile: loadFile, deleteFile: deleteFile, fetchFile: fetchFile)
                }
            }
            .padding(.horizontal, 8)
        }
        .overlay {
            if files.isEmpty {
                ContentUnavailableView("No Files Yet", systemImage: "mappin.and.ellipse", description: Text("Drag and drop files into this folder."))
                    .allowsHitTesting(false)
            }
        }
        .navigationTitle($folder.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
