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
    let importFile: (URL, URL?, Folder?) -> Void
    let fetchFile: (URL, Folder?) async -> Void
    
    @AppStorage("sortBy") var sortBy = SortBy.name
    
    var body: some View {
        let files = folder.files.sorted(using: sortBy.fileComparator)
        
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 0, alignment: .top)], spacing: 0) {
                ForEach(files) { file in
                    FileRow(file: file, loadFile: loadFile, fetchFile: fetchFile)
                }
            }
            .padding(.horizontal, 8)
        }
        .overlay {
            if files.isEmpty {
                ContentUnavailableView("No Files Yet", systemImage: "mappin.and.ellipse", description: Text("Long press on a file to move it into this folder.\nOr tap + to import a new file."))
                    .allowsHitTesting(false)
            }
        }
        .scrollDismissesKeyboard(.immediately)
        .navigationTitle($folder.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                PrimaryActions(folder: folder, importFile: importFile, fetchFile: fetchFile)
            }
        }
    }
}
