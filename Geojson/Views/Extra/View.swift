//
//  View.swift
//  Geojson
//
//  Created by Jack Finnis on 19/11/2022.
//

import SwiftUI

extension View {
    func horizontallyCentred() -> some View {
        HStack {
            Spacer(minLength: 0)
            self
            Spacer(minLength: 0)
        }
    }
    
    func squareButton() -> some View {
        self.font(.system(size: Constants.size/2))
            .frame(width: Constants.size, height: Constants.size)
    }
    
    func addShadow() -> some View {
        self.compositingGroup()
            .shadow(color: Color.black.opacity(0.2), radius: 5)
    }
    
    func blurBackground() -> some View {
        self.background(.thickMaterial)
            .continuousRadius(10)
            .addShadow()
    }
    
    func continuousRadius(_ cornerRadius: CGFloat) -> some View {
        clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
    
    func bigButton() -> some View {
        self.font(.headline)
            .padding()
            .horizontallyCentred()
            .foregroundColor(.white)
            .background(Color.accentColor)
            .continuousRadius(16)
    }
    
    @ViewBuilder
    func `if`<Content: View>(_ applyModifier: Bool = true, @ViewBuilder content: (Self) -> Content) -> some View {
        if applyModifier {
            content(self)
        } else {
            self
        }
    }
}
