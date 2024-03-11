//
//  Defaults.swift
//  MyMap
//
//  Created by Jack Finnis on 17/01/2023.
//

import Foundation

extension UserDefaults {
    static let shared = UserDefaults(suiteName: "group.com.jackfinnis.TubeStatus")!
}

protocol OptionalProtocol {
    var isNil: Bool { get }
}
extension Optional: OptionalProtocol {
    var isNil: Bool { self == nil }
}

protocol KeyValueStore {
    func object(forKey key: String) -> Any?
    func set(_ object: Any?, forKey key: String)
    func removeObject(forKey key: String)
}
extension UserDefaults: KeyValueStore {}
extension NSUbiquitousKeyValueStore: KeyValueStore {}

@propertyWrapper
struct Store<T> {
    let key: String
    let defaultValue: T
    let store: KeyValueStore
    
    init(wrappedValue defaultValue: T, _ key: String, iCloudSync: Bool = false) {
        self.key = key
        self.defaultValue = defaultValue
        self.store = iCloudSync ? NSUbiquitousKeyValueStore.default : UserDefaults.shared
    }
    
    var wrappedValue: T {
        get {
            store.object(forKey: key) as? T ?? defaultValue
        }
        set {
            if let optionalValue = newValue as? OptionalProtocol, optionalValue.isNil {
                store.removeObject(forKey: key)
            } else {
                store.set(newValue, forKey: key)
            }
        }
    }
}

@propertyWrapper
struct Encode<T: Codable> {
    let key: String
    let defaultValue: T
    let iCloudSync: Bool
    
    init(wrappedValue defaultValue: T, _ key: String, iCloudSync: Bool = false) {
        self.key = key
        self.defaultValue = defaultValue
        self.iCloudSync = iCloudSync
    }
    
    var wrappedValue: T {
        get {
            @Store(key, iCloudSync: iCloudSync) var store = Data()
            guard let value = try? JSONDecoder().decode(T.self, from: store) else { return defaultValue }
            return value
        }
        set {
            @Store(key, iCloudSync: iCloudSync) var store = Data()
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            store = data
        }
    }
}

@propertyWrapper
struct Archive<T: NSCoding & NSObject> {
    let key: String
    let defaultValue: T
    let iCloudSync: Bool
    
    init(wrappedValue defaultValue: T, _ key: String, iCloudSync: Bool = false) {
        self.key = key
        self.defaultValue = defaultValue
        self.iCloudSync = iCloudSync
    }
    
    var wrappedValue: T {
        get {
            @Store(key, iCloudSync: iCloudSync) var store = Data()
            guard let value = try? NSKeyedUnarchiver.unarchivedObject(ofClass: T.self, from: store) else { return defaultValue }
            return value
        }
        set {
            @Store(key, iCloudSync: iCloudSync) var store = Data()
            guard let data = try? NSKeyedArchiver.archivedData(withRootObject: newValue, requiringSecureCoding: false) else { return }
            store = data
        }
    }
}
