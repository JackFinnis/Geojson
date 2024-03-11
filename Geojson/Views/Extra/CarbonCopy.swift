//
//  CarbonCopy.swift
//  Cycle
//
//  Created by Jack Finnis on 17/02/2024.
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
