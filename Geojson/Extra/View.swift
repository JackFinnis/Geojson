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
    
    func bigButton() -> some View {
        self
            .font(.body.bold())
            .padding()
            .horizontallyCentred()
            .foregroundColor(.white)
            .background(Color.accentColor)
            .cornerRadius(15)
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
