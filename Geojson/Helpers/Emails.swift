//
//  Emails.swift
//  News
//
//  Created by Jack Finnis on 21/04/2023.
//

import SwiftUI
import MessageUI

struct Emails {
    static func url(subject: String) -> URL? {
        guard let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
        return URL(string: "mailto:\(Constants.email)?subject=\(encodedSubject)")
    }
}
