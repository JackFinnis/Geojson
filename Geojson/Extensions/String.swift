//
//  String.swift
//  Change
//
//  Created by Jack Finnis on 16/07/2022.
//

import Foundation

extension String {
    var replaceSpaces: String {
        replacingOccurrences(of: " ", with: "%20")
    }
}
