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
    
    var fileComparator: SortDescriptor<File> {
        switch self {
        case .name:
            return SortDescriptor(\.name)
        case .date:
            return SortDescriptor(\.date, order: .reverse)
        }
    }
    
    var folderComparator: SortDescriptor<Folder> {
        switch self {
        case .name:
            return SortDescriptor(\.name)
        case .date:
            return SortDescriptor(\.date, order: .reverse)
        }
    }
}
