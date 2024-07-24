//
//  FolderView.swift
//  Geojson
//
//  Created by Jack Finnis on 10/07/2024.
//

import SwiftUI

struct FolderView: View {
    @AppStorage("sortBy") var sortBy = SortBy.name
    @State var searchText = ""
    
    @Bindable var folder: Folder
    let loadFile: (File) -> Void
    let deleteFile: (File) -> Void
    let importFile: (URL, URL?, Folder?) -> Void
    let fetchFile: (URL, Folder?) async -> Void
    
    var body: some View {
        let filteredFiles = folder.files.filter { file in
            searchText.isEmpty || file.name.localizedStandardContains(searchText)
        }.sorted(using: sortBy.fileDescriptor)
        
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 0, alignment: .top)], spacing: 0) {
                ForEach(filteredFiles) { file in
                    FileRow(file: file, loadFile: loadFile, deleteFile: deleteFile, fetchFile: fetchFile)
                }
            }
            .padding(.horizontal, 8)
        }
        .overlay {
            if folder.files.isEmpty {
                ContentUnavailableView("No Files Yet", systemImage: "mappin.and.ellipse", description: Text("Drag and drop files into this folder."))
                    .allowsHitTesting(false)
            } else if filteredFiles.isEmpty && searchText.isNotEmpty {
                ContentUnavailableView.search(text: searchText)
                    .allowsHitTesting(false)
            }
        }
        .animation(.default, value: filteredFiles)
        .searchable(text: $searchText)
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
