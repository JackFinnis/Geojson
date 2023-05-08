//
//  ImportButton.swift
//  Geojson
//
//  Created by Jack Finnis on 23/04/2023.
//

import SwiftUI

struct ImportButton: View {
    @EnvironmentObject var vm: ViewModel
    
    @Binding var showFileImporter: Bool
    
    var body: some View {
        VStack {
            Spacer()
            Menu {
                Button {
                    showFileImporter = true
                } label: {
                   Label("Import GeoJSON File", systemImage: "plus")
                }
                Section("Recents") {
                    ForEach(vm.recentUrls, id: \.self) { url in
                        Button(url.deletingPathExtension().lastPathComponent.removingPercentEncoding ?? url.absoluteString) {
                            vm.importFile(url: url, canShowAlert: true)
                        }
                    }
                }
            } label: {
                Image(systemName: "plus")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.accentColor)
                    .clipShape(Circle())
                    .addShadow()
            }
            .padding()
        }
    }
}
