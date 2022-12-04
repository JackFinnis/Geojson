//
//  Emails.swift
//  Fourier
//
//  Created by Jack Finnis on 04/12/2022.
//

import SwiftUI

struct Emails {
    static func compose(subject: String) {
        if let url = URL(string: EMAIL + "?subject=" + subject.replaceSpaces) {
            UIApplication.shared.open(url)
        }
    }
}
