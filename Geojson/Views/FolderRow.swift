//
//  FileRow.swift
//  Geojson
//
//  Created by Jack Finnis on 07/07/2024.
//

import SwiftUI
import SwiftData

struct FolderRow: View {
    @Bindable var folder: Folder
    
    @Environment(\.modelContext) var modelContext
    
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
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                modelContext.delete(folder)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
