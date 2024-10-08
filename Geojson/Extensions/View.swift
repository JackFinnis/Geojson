//
//  View.swift
//  Geojson
//
//  Created by Jack Finnis on 07/07/2024.
//

import SwiftUI

extension View {
    func mapBox() -> some View {
        frame(width: size, height: size)
    }
    
    func mapButton() -> some View {
        self
            .foregroundStyle(Color.accentColor)
            .buttonStyle(.plain)
            .font(.system(size: 19))
            .background(.ultraThickMaterial)
            .clipShape(.rect(cornerRadius: 8))
            .shadow(color: Color.black.opacity(0.1), radius: 5)
    }
}
