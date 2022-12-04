//
//  Storage.swift
//  Change
//
//  Created by Jack Finnis on 07/11/2022.
//

import Foundation

@propertyWrapper
struct Storage<ValueType> {
    let defaults = UserDefaults.standard
    
    let key: String
    let defaultValue: ValueType
    
    func reset() {
        defaults.set(defaultValue, forKey: key)
    }

    var wrappedValue: ValueType {
        get {
            defaults.object(forKey: key) as? ValueType ?? defaultValue
        }
        set {
            defaults.set(newValue, forKey: key)
        }
    }
}

@propertyWrapper
struct OptionalStorage<ValueType> {
    let defaults = UserDefaults.standard
    
    let key: String
    let defaultValue: ValueType?
    
    func reset() {
        setValue(defaultValue)
    }
    
    func setValue(_ value: ValueType?) {
        if let value {
            defaults.set(value, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }

    var wrappedValue: ValueType? {
        get {
            defaults.object(forKey: key) as? ValueType ?? defaultValue
        }
        set {
            setValue(newValue)
        }
    }
}
