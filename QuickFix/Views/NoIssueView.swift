//
//  NoIssueView.swift
//  QuickFix
//
//  Created by christian on 3/20/23.
//

import SwiftUI

struct NoIssueView: View {
    @EnvironmentObject var dataController: DataController
    
    var body: some View {
        Text("No Issue Selected")
            .font(.title)
            .foregroundColor(.secondary)
        
        // Create a new 'issue' using the context
        Button("New Issue", action: dataController.newIssue)
    }
}

struct NoIssueView_Previews: PreviewProvider {
    static var previews: some View {
        NoIssueView()
    }
}
