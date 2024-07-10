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
    @FocusState var focused: Bool
    
    @Bindable var folder: Folder
    @Query var files: [File]
    
    var body: some View {
        NavigationLink(value: folder) {
            VStack(alignment: .leading) {
                Rectangle()
                    .fill(.fill)
                    .overlay {
                        Image(systemName: "folder.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                    }
                    .aspectRatio(1, contentMode: .fit)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(.fill))
                
                TextField("Name", text: $folder.name, axis: .vertical)
                    .focused($focused)
                    .submitLabel(.done)
                    .textInputAutocapitalization(.words)
                    .multilineTextAlignment(.leading)
                    .onChange(of: folder.name) { _, name in
                        if folder.name.last == "\n" {
                            focused = false
                            folder.name = folder.name.trimmingCharacters(in: .whitespacesAndNewlines)
                            if folder.name.isEmpty {
                                folder.name = "Folder"
                            }
                        }
                    }
            }
            .padding(8)
            .background(.background)
        }
        .foregroundStyle(.primary)
        .contextMenu {
            Button {
                focused = true
            } label: {
                Label("Rename", systemImage: "pencil")
            }
            Button(role: .destructive) {
                modelContext.delete(folder)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .dropDestination(for: String.self) { ids, point in
            let folderFiles: [File] = ids.compactMap { id in
                files.first { $0.id.uuidString == id }
            }
            guard folderFiles.isNotEmpty else { return false }
            folder.files.append(contentsOf: folderFiles)
            return true
        }
    }
}
