//
//  ImportButton.swift
//  Geojson
//
//  Created by Jack Finnis on 23/04/2023.
//

import SwiftUI

struct ImportButton: View {
    @EnvironmentObject var vm: ViewModel
    @State var showFileImporter = false
    
    @Binding var showInfoView: Bool
    let infoView: Bool
    
    var body: some View {
        Menu {
            ForEach(GeoFileType.allCases, id: \.self) { type in
                Button("Import \(type.rawValue)") {
                    showFileImporter = true
                }
            }
            Section("Recents") {
                ForEach(vm.recentUrls, id: \.self) { url in
                    Button(url.deletingPathExtension().lastPathComponent.removingPercentEncoding ?? url.absoluteString) {
                        vm.importFile(url: url, canShowAlert: true)
                    }
                }
            }
        } label: {
            if infoView {
                Text("Import GeoJSON")
                    .bigButton()
            } else {
                Image(systemName: "plus")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.accentColor)
                    .clipShape(Circle())
                    .addShadow()
            }
        }
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.item]) { result in
            switch result {
            case .success(let url):
                vm.importFile(url: url, canShowAlert: true)
                showInfoView = false
            case .failure(let error):
                debugPrint(error)
            }
        }
    }
}
