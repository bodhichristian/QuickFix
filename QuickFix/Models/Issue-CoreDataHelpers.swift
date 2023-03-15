//
//  Issue-CoreDataHelpers.swift
//  QuickFix
//
//  Created by christian on 3/15/23.
//

import Foundation

// Extension on Issue
// Handles Core Data's optional values
extension Issue {
    var issueTitle: String {
        get { title ?? "" }
        set { title =  newValue }
    }
    
    var issueContent: String {
        get { content ?? "" }
        set { content = newValue }
    }
    
    var issueCreationDate: Date {
        creationDate ?? .now
    }
    
    var issueModificationDate: Date {
        modificationDate ?? .now
    }
    
    var issueTags: [Tag] {
        let result = tags?.allObjects as? [Tag] ?? []
        // Keep tag order consistent with .sorted()
        return result.sorted()
    }
    
    // Example for Previews
    static var example: Issue {
        let controller = DataController(inMemory: true)
        let viewcontext = controller.container.viewContext
        
        let issue = Issue(context: viewcontext)
        issue.title = "Example Issue"
        issue.content = "This is an example issue."
        issue.priority = 2
        issue.creationDate = .now
        return issue
    }
}

extension Issue: Comparable {
    public static func <(lhs: Issue, rhs: Issue) -> Bool {
        let left = lhs.issueTitle.localizedLowercase
        let right = rhs.issueTitle.localizedLowercase
        
        // If issue titles are equal
        if left == right {
            // Sort by Creation Date
            return lhs.issueCreationDate < rhs.issueCreationDate
        } else {
            // Otherwise, sort by Issue Title
            return left < right
        }
    }
}
