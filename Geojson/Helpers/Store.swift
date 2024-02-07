//
//  Store.swift
//  Change
//
//  Created by Jack Finnis on 21/10/2022.
//

import UIKit
import StoreKit

struct Store {
    static func requestRating() {
        let scene = UIApplication.shared.connectedScenes.first { $0.activationState == .foregroundActive }
        guard let scene = scene as? UIWindowScene else { return }
        SKStoreReviewController.requestReview(in: scene)
    }
    
    static func writeReview() {
        var components = URLComponents(url: Constants.appURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "action", value: "write-review")]
        guard let url = components?.url else { return }
        UIApplication.shared.open(url)
    }
}
