//
//  NSObject.swift
//  Trails
//
//  Created by Jack Finnis on 18/02/2023.
//

import Foundation

extension NSObject {
    class var id: String { String(describing: self) }
}
