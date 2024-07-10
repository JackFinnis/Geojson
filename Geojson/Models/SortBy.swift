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
    
    var fileDescriptor: any SortComparator<File> {
        switch self {
        case .name:
            return SortDescriptor(\File.name)
        case .date:
            return SortDescriptor(\File.date, order: .reverse)
        }
    }
    
    var folderDescriptor: any SortComparator<Folder> {
        switch self {
        case .name:
            return SortDescriptor(\Folder.name)
        case .date:
            return SortDescriptor(\Folder.date, order: .reverse)
        }
    }
}
