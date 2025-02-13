//
//  AnnotationView.swift
//  Geojson
//
//  Created by Jack Finnis on 13/02/2025.
//

import SwiftUI

struct AnnotationView: View {
    let annotation: Annotation
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL
    
    var body: some View {
        NavigationStack {
            List(annotation.properties.dict.sorted(using: SortDescriptor(\.key)), id: \.key) { key, value in
                let string = "\(value)"
                Button(key) {
                    if let url = URL(string: string), UIApplication.shared.canOpenURL(url) {
                        openURL(url)
                    } else {
                        UIPasteboard.general.string = string
                        Haptics.tap()
                    }
                }
                .lineLimit(1)
                .badge(string)
                .tint(.primary)
            }
            .listStyle(.plain)
            .navigationTitle(annotation.properties.title ?? "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if let point = annotation as? Point {
                        Button {
                            Task {
                                try? await point.openInMaps()
                            }
                        } label: {
                            Image(systemName: "map")
                        }
                        .font(.headline)
                        .buttonBorderShape(.circle)
                        .buttonStyle(.bordered)
                        .foregroundStyle(.secondary)
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .font(.headline)
                    .buttonBorderShape(.circle)
                    .buttonStyle(.bordered)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
