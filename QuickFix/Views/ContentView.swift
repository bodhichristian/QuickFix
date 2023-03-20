//
//  ContentView.swift
//  PortfolioApp
//
//  Created by christian on 3/13/23.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataController: DataController
    
    // An array of Issues, sorted by tags if present
    var issues: [Issue] {
        // Determine the filter to use based on the selected filter in the data controller.
        let filter = dataController.selectedFilter ?? .all
        var allIssues: [Issue]
        
        // If the filter specifies a tag, fetch all issues associated with that tag.
        if let tag = filter.tag {
            allIssues = tag.issues?.allObjects as? [Issue] ?? []
        } else {
            // Otherwise, fetch all issues from the view context.
            let request = Issue.fetchRequest()
            // Only match issues modified since the minimumModificationDate filter (7 day window, or all time)
            request.predicate = NSPredicate(format: "modificationDate > %@", filter.minModificationDate as NSDate)
            allIssues = (try? dataController.container.viewContext.fetch(request)) ?? []
        }
        
        // Return the sorted array of issues.
        return allIssues.sorted()
    }

    var body: some View {
        List(selection: $dataController.selectedIssue) {
            ForEach(issues) { issue in
                IssueRow(issue: issue)
            }
            .onDelete(perform: delete)
        }
        .navigationTitle("Issues")
    }
    
    func delete(_ offsets: IndexSet) {
        for offset in offsets {
            let item = issues[offset]
            dataController.delete(item)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
