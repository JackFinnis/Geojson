//
//  Blur.swift
//  Cycle
//
//  Created by Jack Finnis on 08/10/2022.
//

import SwiftUI

struct Blur: UIViewRepresentable {
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: .regular))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
