//
//  ShareView.swift
//  Change
//
//  Created by Jack Finnis on 16/10/2022.
//

import SwiftUI

struct ShareView: UIViewControllerRepresentable {
    let url: URL
    let completion: (Bool) -> Void
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        vc.completionWithItemsHandler = { activity, completed, items, error in
            completion(completed)
        }
        return vc
    }
    
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

extension View {
    func shareSheet(url: URL, showsSharedAlert: Bool = false, isPresented: Binding<Bool>) -> some View {
        modifier(ShareModifier(url: url, showsSharedAlert: showsSharedAlert, isPresented: isPresented))
    }
}

struct ShareModifier: ViewModifier {
    @State var showSharedAlert = false
    
    let url: URL
    let showsSharedAlert: Bool
    @Binding var isPresented: Bool
    
    func body(content: Content) -> some View {
        content
            .popover(isPresented: $isPresented) {
                let view = ShareView(url: url) { shared in
                    showSharedAlert = showsSharedAlert && shared
                }
                .ignoresSafeArea()
                if #available(iOS 16, *) {
                    view.presentationDetents([.medium, .large])
                } else {
                    view
                }
            }
            .alert("Sharing Complete", isPresented: $showSharedAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Thanks for sharing \(NAME)!")
            }
    }
}
