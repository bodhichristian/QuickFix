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
        
        Button("New Issue") {
            // make a new issue
        }
    }
}

struct NoIssueView_Previews: PreviewProvider {
    static var previews: some View {
        NoIssueView()
    }
}
