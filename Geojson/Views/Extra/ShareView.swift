//
//  ShareView.swift
//  Change
//
//  Created by Jack Finnis on 16/10/2022.
//

import SwiftUI

struct ShareView: UIViewControllerRepresentable {
    let items: [Any]
    let completion: (Bool) -> Void
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let vc = UIActivityViewController(activityItems: items, applicationActivities: nil)
        vc.completionWithItemsHandler = { activity, completed, items, error in
            completion(completed)
        }
        return vc
    }
    
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

extension View {
    func sharePopover(_ items: [Any], showsSharedAlert: Bool, isPresented: Binding<Bool>) -> some View {
        modifier(ShareModifier(items: items, showsSharedAlert: showsSharedAlert, isPresented: isPresented))
    }
}

struct ShareModifier: ViewModifier {
    @State var showSharedAlert = false
    
    let items: [Any]
    let showsSharedAlert: Bool
    @Binding var isPresented: Bool
    
    func body(content: Content) -> some View {
        content
            .popover(isPresented: $isPresented) {
                let view = ShareView(items: items) { shared in
                    showSharedAlert = showsSharedAlert && shared
                }
                .ignoresSafeArea()
                if #available(iOS 16, *) {
                    view.presentationDetents([.medium, .large])
                } else {
                    view
                }
            }
            .alert("Thanks for sharing \(Constants.name)!", isPresented: $showSharedAlert) {
                Button("OK", role: .cancel) {}
            }
    }
}
