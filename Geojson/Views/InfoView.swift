//
//  WelcomeView.swift
//  Location
//
//  Created by Jack Finnis on 27/07/2022.
//

import SwiftUI
import MessageUI

struct InfoView: View {
    @Environment(\.dismiss) var dismiss
    @State var showShareSheet = false
    @State var showEmailSheet = false
    
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
                        .shadow(color: .black.opacity(0.2), radius: 5)
                    Text(NAME)
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                }
                .horizontallyCentred()
                .padding(.bottom, 30)
                
                VStack(alignment: .leading, spacing: 20) {
                    InfoRow(systemName: "mappin.and.ellipse", title: "Import and Browse GeoJSON", description: "Import a GeoJSON file containing polylines, polygons or points and browse the data on the map.")
                    Button {
                        UIApplication.shared.open(VALIDATE_URL)
                    } label: {
                        InfoRow(systemName: "questionmark.circle", title: "Having trouble importing data?", description: " is a helpful website for spotting syntax errors in GeoJSON.", link: VALIDATE_URL.absoluteString)
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
                if welcome {
                    Button {
                        dismiss()
                    } label: {
                        Text("Import GeoJSON")
                            .bigButton()
                    }
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
                            dismiss()
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
                InfoView(welcome: true)
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
