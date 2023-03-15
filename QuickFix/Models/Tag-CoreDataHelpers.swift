//
//  Tag-CoreDataHelpers.swift
//  QuickFix
//
//  Created by christian on 3/15/23.
//

import Foundation

// Extension on Tag
// Handles Core Data's optional values
extension Tag {
    var tagID: UUID {
        id ?? UUID()
    }
    
    var tagName: String {
        name ?? ""
    }
    // Create an array of Active Issues related to a tag
    var tagActiveIssues: [Issue] {
        let result = issues?.allObjects as? [Issue] ?? []
        // Filter out completed Issues.
        return result.filter { $0.completed == false }
    }
    
    static var example: Tag {
        let controller = DataController(inMemory: true)
        let viewContext = controller.container.viewContext
        
        let tag = Tag(context: viewContext)
        tag.id = UUID()
        tag.name = "Example Tag"
        return tag
    }
}

extension Tag: Comparable {
    public static func <(lhs: Tag, rhs: Tag) -> Bool {
        let left = lhs.tagName.localizedLowercase
        let right = rhs.tagName.localizedLowercase
        
        // If Tag Names are equal
        if left == right {
            // Sort by UUID
            return lhs.tagID.uuidString < rhs.tagID.uuidString
        } else {
            // Otherwise, sort by Tag
            return left < right 
        }
    }
}
