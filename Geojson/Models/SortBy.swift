//
//  SortBy.swift
//  AppIconMaker
//
//  Created by Jack Finnis on 07/02/2024.
//

import Foundation

enum SortBy: String, CaseIterable {
    case name = "Name"
    case date = "Recent"
    
    var descriptor: any SortComparator<File> {
        switch self {
        case .name:
            return SortDescriptor(\File.name)
        case .date:
            return SortDescriptor(\File.date, order: .reverse)
        }
    }
}
