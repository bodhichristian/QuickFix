//
//  Filter.swift
//  PortfolioApp
//
//  Created by christian on 3/14/23.
//

import Foundation

struct Filter: Identifiable, Hashable {
    var id: UUID
    var name: String
    var icon: String
    var minModificationDate = Date.distantPast
    var tag: Tag?
    
    var activeIssuesCount: Int {
        filter.tag?.tagActiveIssues.count ?? 0
    }
    
    static var all = Filter(id: UUID(), name: "All Issues", icon: "tray")
    // minModificationDate is set to 7 days prior to now
    static var recent = Filter(id: UUID(), name: "Recent Issues", icon: "clock", minModificationDate: .now.addingTimeInterval(86400 * -7))
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    // Compares two filters
    static func ==(lhs: Filter, rhs: Filter) -> Bool {
        lhs.id == rhs.id
    }
}
