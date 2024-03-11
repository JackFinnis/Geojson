//
//  DismissCross.swift
//  Change
//
//  Created by Jack Finnis on 20/10/2022.
//

import SwiftUI

struct DismissButton: UIViewRepresentable {
    let action: () -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UIButton {
        let button = UIButton(type: .close)
        button.addTarget(context.coordinator, action: #selector(Coordinator.performAction), for: .primaryActionTriggered)
        return button
    }
    
    func updateUIView(_ view: UIButton, context: Context) {}
    
    class Coordinator {
        let parent: DismissButton
        
        init(_ parent: DismissButton) {
            self.parent = parent
        }
        
        @objc func performAction() {
            parent.action()
        }
    }
}
