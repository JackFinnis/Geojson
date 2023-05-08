//
//  Emails.swift
//  News
//
//  Created by Jack Finnis on 21/04/2023.
//

import SwiftUI

struct Emails {
    static func mailtoUrl(subject: String) -> URL? {
        URL(string: "mailto:\(EMAIL)?subject=\(subject.replaceSpaces)")
    }
}

extension String {
    var replaceSpaces: String {
        replacingOccurrences(of: " ", with: "%20")
    }
}
