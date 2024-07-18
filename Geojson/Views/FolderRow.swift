//
//  FileRow.swift
//  Geojson
//
//  Created by Jack Finnis on 07/07/2024.
//

import SwiftUI
import SwiftData

struct FolderRow: View {
    @Environment(\.modelContext) var modelContext
    
    @Bindable var folder: Folder
    @Query var files: [File]
    
    var body: some View {
        NavigationLink(value: folder) {
            HStack {
                Image(systemName: "folder.fill")
                    .font(.title)
                    .foregroundStyle(.secondary)
                Text(folder.name)
                Spacer(minLength: 0)
            }
            .padding(8)
            .background(.background)
        }
        .foregroundStyle(.primary)
        .contextMenu {
            Button(role: .destructive) {
                modelContext.delete(folder)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .dropDestination(for: String.self, action: addToThisFolder)
    }
    
    func addToThisFolder(ids: [String], point: CGPoint) -> Bool {
        let folderFiles: [File] = ids.compactMap { id in
            files.first { $0.id.uuidString == id }
        }
        guard folderFiles.isNotEmpty else { return false }
        folder.files.append(contentsOf: folderFiles)
        return true
    }
}
