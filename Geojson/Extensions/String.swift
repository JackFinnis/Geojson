//
//  String.swift
//  Geojson
//
//  Created by Jack Finnis on 20/05/2023.
//

import Foundation

extension String {
    var urlEncoded: String? {
        addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    }
}
