//
//  CopyView.swift
//  Trails
//
//  Created by Jack Finnis on 19/04/2023.
//

import SwiftUI

struct CarbonCopy: UIViewRepresentable {
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView()
    }
    
    func updateUIView(_ view: UIVisualEffectView, context: Context) {
        view.effect = nil
        let effect = UIBlurEffect(style: .regular)
        let animator = UIViewPropertyAnimator()
        animator.addAnimations { view.effect = effect }
        animator.startAnimation()
        animator.stopAnimation(true)
    }
}
