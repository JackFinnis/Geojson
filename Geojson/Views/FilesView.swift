//
//  FilesView.swift
//  Geojson
//
//  Created by Jack Finnis on 10/03/2024.
//

import SwiftUI
import StoreKit

struct FilesView: View {
    @Environment(\.requestReview) var requestReview
    @Environment(\.openURL) var openURL
    @EnvironmentObject var app: AppState
    @State var searchText = ""
    @State var showFileImporter = false
    
    var filteredURLs: [URL] {
        if searchText.isEmpty {
            return app.recentUrls
        } else {
            return app.recentUrls.filter { $0.lastPathComponent.localizedStandardContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
            List(filteredURLs, id: \.self) { url in
                Button(url.lastPathComponent) {
                    app.importFile(url: url)
                }
            }
            .overlay {
                if app.recentUrls.isEmpty {
                    ContentUnavailableView("No Files Yet", systemImage: "mappin.and.ellipse", description: Text("Tap + to import a file"))
                        .allowsHitTesting(false)
                } else if filteredURLs.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                        .allowsHitTesting(false)
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .navigationDestination(item: $app.selectedFile) { file in
                FileView(file: file)
            }
            .navigationTitle(Constants.name)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDocument(Constants.appURL, preview: SharePreview(Constants.name, image: Image(.logo))).toolbarTitleMenu {
                Button {
                    requestReview()
                } label: {
                    Label("Rate \(Constants.name)", systemImage: "star")
                }
                Button {
                    AppStore.writeReview()
                } label: {
                    Label("Write a Review", systemImage: "quote.bubble")
                }
                if let url = Emails.url(subject: "\(Constants.name) Feedback"), UIApplication.shared.canOpenURL(url) {
                    Button {
                        openURL(url)
                    } label: {
                        Label("Send us Feedback", systemImage: "envelope")
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showFileImporter = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.circle)
                    .font(.headline)
                }
            }
        }
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: GeoFileType.allUTTypes) { result in
            switch result {
            case .success(let url):
                app.importFile(url: url)
            case .failure(let error):
                debugPrint(error)
            }
        }
        .alert("Import Failed", isPresented: $app.showError) {
            Button("OK", role: .cancel) {}
            if let fileType = app.error?.fileType {
                Button("Open Help Website") {
                    UIApplication.shared.open(fileType.helpUrl)
                }
            }
        } message: {
            if let error = app.error {
                Text(error.message)
            }
        }
    }
}

#Preview {
    FilesView()
}
