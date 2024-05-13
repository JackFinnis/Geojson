//
//  View.swift
//  Cycle
//
//  Created by Jack Finnis on 17/02/2024.
//

import SwiftUI

extension View {
    func box() -> some View {
        frame(width: 44, height: 44)
    }
    
    func mapButton() -> some View {
        self
            .font(.system(size: 19))
            .background(.ultraThickMaterial)
            .clipShape(.rect(cornerRadius: 8))
            .shadow(color: Color.black.opacity(0.1), radius: 5)
    }
}
