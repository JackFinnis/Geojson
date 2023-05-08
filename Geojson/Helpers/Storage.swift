//
//  Defaults.swift
//  Change
//
//  Created by Jack Finnis on 07/11/2022.
//

import Foundation

@propertyWrapper
struct Storage<T> {
    let key: String
    let defaultValue: T
    
    init(wrappedValue defaultValue: T, _ key: String) {
        self.key = key
        self.defaultValue = defaultValue
    }
    
    let defaults = UserDefaults.standard
    var wrappedValue: T {
        get {
            defaults.object(forKey: key) as? T ?? defaultValue
        }
        set {
            defaults.set(newValue, forKey: key)
        }
    }
}
