//
//  CopyView.swift
//  Trails
//
//  Created by Jack Finnis on 19/04/2023.
//

import SwiftUI



struct CarbonCopy: UIViewRepresentable {
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView()
        let effect = UIBlurEffect(style: .regular)
        
        let animator = UIViewPropertyAnimator()
        animator.addAnimations { view.effect = effect }
        animator.fractionComplete = 0
        animator.stopAnimation(true)
        animator.finishAnimation(at: .start)
        
        return view
    }
    
    func updateUIView(_ view: UIVisualEffectView, context: Context) {}
}
