//
//  ImportButton.swift
//  Geojson
//
//  Created by Jack Finnis on 23/04/2023.
//

import SwiftUI
import UniformTypeIdentifiers

struct ImportButton: View {
    @EnvironmentObject var vm: ViewModel
    @State var showFileImporter = false
    
    @Binding var showInfoView: Bool
    let infoView: Bool
    
    var body: some View {
        Group {
            if infoView {
                Button {
                    showFileImporter = true
                } label: {
                    Text("Import File")
                        .bigButton()
                }
            } else {
                Menu {
                    Button {
                        showFileImporter = true
                    } label: {
                        Label("Import GPX, KML or GeoJSON File", systemImage: "plus")
                    }
                    Section("Open Recent File") {
                        ForEach(vm.recentUrls.reversed(), id: \.self) { url in
                            Button(url.lastPathComponent.removingPercentEncoding ?? url.lastPathComponent) {
                                vm.importFile(url: url, canShowAlert: true)
                            }
                        }
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.title2.weight(.semibold))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.accentColor)
                        .clipShape(Circle())
                        .shadow()
                }
            }
        }
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: GeoFileType.allUTTypes) { result in
            switch result {
            case .success(let url):
                vm.importFile(url: url, canShowAlert: true)
                vm.requestLocationAuthorization()
                showInfoView = false
            case .failure(let error):
                debugPrint(error)
            }
        }
        .alert("Import Failed", isPresented: $vm.showFailedAlert) {
            Button("OK", role: .cancel) {}
            if let fileType = vm.geoError.fileType {
                Button("Open Help Website") {
                    UIApplication.shared.open(fileType.helpUrl)
                }
            }
        } message: {
            Text(vm.geoError.message)
        }
    }
}
