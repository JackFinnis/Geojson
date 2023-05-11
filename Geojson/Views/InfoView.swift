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
            VStack(alignment: .leading, spacing: 0) {
                VStack(spacing: 10) {
                    Image("logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 70, height: 70)
                        .continuousRadius(15)
                        .addShadow()
                    Text(NAME)
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                }
                .horizontallyCentred()
                .padding(.bottom, 30)
                
                VStack(alignment: .leading, spacing: 20) {
                    InfoRow(systemName: "mappin.and.ellipse", title: "GPX, KML, GeoJSON", description: "Import the most popular geodata file formats and browse your data on an interactive map.")
                    InfoRow(systemName: "line.3.horizontal.decrease.circle", title: "Filter Map Data", description: "Filter data by points, polylines and polygons.")
                    InfoRow(systemName: "clock.arrow.circlepath", title: "Save Your Recents", description: "Quickly switch between your recent files.")
                }
                
                Spacer()
                if welcome {
                    ImportButton(showInfoView: $isPresented, infoView: true)
                } else {
                    Menu {
                        if MFMailComposeViewController.canSendMail() {
                            Button {
                                showEmailSheet.toggle()
                            } label: {
                                Label("Send us Feedback", systemImage: "envelope")
                            }
                        } else if let url = Emails.mailtoUrl(subject: "\(NAME) Feedback"), UIApplication.shared.canOpenURL(url) {
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
                            Label("Rate \(NAME)", systemImage: "star")
                        }
                        Button {
                            showShareSheet.toggle()
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
            .interactiveDismissDisabled(welcome)
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
        .shareSheet(url: APP_URL, showsSharedAlert: true, isPresented: $showShareSheet)
        .emailSheet(recipient: EMAIL, subject: "\(NAME) Feedback", isPresented: $showEmailSheet)
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
    var link = ""
    
    var body: some View {
        HStack {
            Image(systemName: systemName)
                .font(.title)
                .foregroundColor(.accentColor)
                .frame(width: 50, height: 50)
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text(link)
                    .foregroundColor(.accentColor)
                    .underline() +
                Text(description)
                    .foregroundColor(.secondary)
            }
        }
    }
}
