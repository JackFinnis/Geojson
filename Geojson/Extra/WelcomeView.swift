//
//  WelcomeView.swift
//  Location
//
//  Created by Jack Finnis on 27/07/2022.
//

import SwiftUI

struct WelcomeView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                Image("logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 70, height: 70)
                    .cornerRadius(15)
                    .horizontallyCentred()
                    .padding(.top, 50)
                    .padding(.bottom)
                Text("Welcome to\n\(NAME)")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                    .horizontallyCentred()
                    .padding(.bottom, 50)
                
                WelcomeRow("Import Geojson", description: "Import polylines, polygons and points from any Geojson file", systemName: "square.and.arrow.down")
                WelcomeRow("Browse Data", description: "Browse your Geojson data on an interactive satellite map", systemName: "map")
                WelcomeRow("Locate Yourself", description: "Easily find your current location and determine your heading", systemName: "location")
                
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Text("Import")
                        .bold()
                        .padding()
                        .horizontallyCentred()
                        .foregroundColor(.white)
                        .background(Color.accentColor)
                        .cornerRadius(15)
                }
            }
            .padding()
        }
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
