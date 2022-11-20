//
//  WelcomeView.swift
//  Location
//
//  Created by Jack Finnis on 27/07/2022.
//

import SwiftUI

struct WelcomeView: View {
    @Environment(\.dismiss) var dismiss
    @State var showShareSheet = false
    
    @Binding var shouldShowFileImporter: Bool
    let firstLaunch: Bool
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                Image("logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 70, height: 70)
                    .cornerRadius(15)
                    .horizontallyCentred()
                    .padding(.bottom)
                Text((firstLaunch ? "Welcome to\n" : "") + NAME)
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                    .horizontallyCentred()
                    .padding(.bottom, 5)
                if !firstLaunch {
                    Text("Version " + (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""))
                        .foregroundColor(.secondary)
                        .horizontallyCentred()
                }
                
                Spacer()
                WelcomeRow("Import GeoJSON", description: "Import polylines, polygons and points from any GeoJSON file", systemName: "square.and.arrow.down")
                WelcomeRow("Browse Data", description: "Browse your GeoJSON data on an interactive satellite map", systemName: "map")
                WelcomeRow("Locate Yourself", description: "Easily find your current location and determine your heading", systemName: "location")
                Spacer()
                
                if firstLaunch {
                    Button {
                        dismiss()
                        shouldShowFileImporter = true
                    } label: {
                        Text("Import GeoJSON")
                            .bigButton()
                    }
                } else {
                    Menu {
                        Button {
                            Store.writeReview()
                        } label: {
                            Label("Write a Review", systemImage: "quote.bubble")
                        }
                        Button {
                            Store.requestRating()
                        } label: {
                            Label("Rate the App", systemImage: "star")
                        }
                        Button {
                            showShareSheet = true
                        } label: {
                            Label("Share with a Friend", systemImage: "person.badge.plus")
                        }
                    } label: {
                        Text("Contribute...")
                            .bigButton()
                    }
                }
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        dismiss()
                    } label: {
                        DismissCross()
                    }
                    .buttonStyle(.plain)
                }
                ToolbarItem(placement: .principal) {
                    DraggableBar()
                }
            }
        }
        .shareSheet(url: APP_URL, isPresented: $showShareSheet)
    }
}

struct WelcomeRow: View {
    let title: String
    let description: String
    let systemName: String
    
    init(_ title: String, description: String, systemName: String) {
        self.title = title
        self.systemName = systemName
        self.description = description
    }
    
    var body: some View {
        HStack {
            Image(systemName: systemName)
                .font(.title)
                .foregroundColor(.accentColor)
                .frame(width: 50, height: 50)
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical)
    }
}
