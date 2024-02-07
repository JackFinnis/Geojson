//
//  WelcomeView.swift
//  Location
//
//  Created by Jack Finnis on 27/07/2022.
//

import SwiftUI
import MessageUI

struct InfoView: View {
    @EnvironmentObject var vm: ViewModel
    @State var showShareSheet = false
    @State var showEmailSheet = false
    
    @Binding var isPresented: Bool
    let welcome: Bool
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(spacing: 10) {
                        Image("logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 70, height: 70)
                            .continuousRadius(70 * 0.2237)
                            .shadow()
                        Text(Constants.name)
                            .font(.largeTitle.bold())
                            .multilineTextAlignment(.center)
                    }
                    .horizontallyCentred()
                    .padding(.bottom, 30)
                    
                    VStack(alignment: .leading, spacing: 20) {
                        InfoRow(systemName: "map", title: "Import GPX, KML and GeoJSON", description: "Browse your geodata on a satellite or standard map.")
                        InfoRow(systemName: "location.north.line.fill", title: "Track Your Location", description: "Watch you location and heading update live on the map.")
                        InfoRow(systemName: "clock.arrow.circlepath", title: "Quickly Open Recent Files", description: "Open files that you have recently imported in just 2 taps.")
                    }
                }
                .padding(.horizontal)
                .frame(maxWidth: 450)
                .horizontallyCentred()
            }
            .safeAreaInset(edge: .bottom) {
                Group {
                    if welcome {
                        VStack {
                            Text("Supports .geojson .json .gpx .kml .kmz")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            ImportButton(showInfoView: $isPresented, infoView: true)
                        }
                    } else {
                        Menu {
                            if MFMailComposeViewController.canSendMail() {
                                Button {
                                    showEmailSheet.toggle()
                                } label: {
                                    Label("Send us Feedback", systemImage: "envelope")
                                }
                            } else if let url = Emails.mailtoUrl(subject: "\(Constants.name) Feedback"), UIApplication.shared.canOpenURL(url) {
                                Button {
                                    UIApplication.shared.open(url)
                                } label: {
                                    Label("Send us Feedback", systemImage: "envelope")
                                }
                            }
                            Button {
                                Store.writeReview()
                            } label: {
                                Label("Write a Review", systemImage: "quote.bubble")
                            }
                            Button {
                                Store.requestRating()
                            } label: {
                                Label("Rate \(Constants.name)", systemImage: "star")
                            }
                            Button {
                                showShareSheet.toggle()
                            } label: {
                                Label("Share \(Constants.name)", systemImage: "square.and.arrow.up")
                            }
                        } label: {
                            Text("Contribute...")
                                .bigButton()
                        }
                        .sharePopover([Constants.appURL], showsSharedAlert: true, isPresented: $showShareSheet)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .frame(maxWidth: 450)
                .horizontallyCentred()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    if welcome {
                        Text("")
                    } else {
                        DraggableTitle()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    if !welcome {
                        Button {
                            isPresented = false
                        } label: {
                            DismissCross()
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .emailSheet(recipient: Constants.email, subject: "\(Constants.name) Feedback", isPresented: $showEmailSheet)
        .interactiveDismissDisabled(welcome)
    }
}

struct InfoView_Previews: PreviewProvider {
    static var previews: some View {
        Text("")
            .sheet(isPresented: .constant(true)) {
                InfoView(isPresented: .constant(true), welcome: true)
            }
    }
}

struct InfoRow: View {
    let systemName: String
    let title: String
    let description: String
    
    var body: some View {
        HStack {
            Image(systemName: systemName)
                .font(.title)
                .foregroundColor(.accentColor)
                .frame(width: 50, height: 50)
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(description)
                    .foregroundColor(.secondary)
            }
        }
    }
}
