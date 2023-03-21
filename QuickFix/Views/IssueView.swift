//
//  IssueView.swift
//  QuickFix
//
//  Created by christian on 3/20/23.
//

import SwiftUI

struct IssueView: View {
    @EnvironmentObject var dataController: DataController
    @ObservedObject var issue: Issue
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading) {
                    TextField("Title", text: $issue.issueTitle, prompt: Text("Enter the issue title here"))
                        .font(.title)
                    
                    Text("**Modified:** \(issue.issueModificationDate.formatted(date: .long, time: .shortened))")
                        .foregroundStyle(.secondary)
                    
                    Text("**Status:** \(issue.issueStatus)")
                        .foregroundStyle(.secondary)
                }
                
                Picker("Priority", selection: $issue.priority) {
                    Text("Low").tag(Int16(0))
                    Text("Medium").tag(Int16(1))
                    Text("High").tag(Int16(2))
                }
                
                Menu {
                    // Show selected tags first
                    ForEach(issue.issueTags) { tag in
                        Button {
                            issue.removeFromTags(tag)
                        } label: {
                            Label(tag.tagName, systemImage: "checkmark")
                        }
                    }
                    
                    // Show other tags if available
                    let otherTags = dataController.missingTags(from: issue)
                    
                    if otherTags.isEmpty == false {
                        Divider()
                        
                        Section("Add Tags") {
                            ForEach(otherTags) { tag in
                                Button(tag.tagName) {
                                    issue.addToTags(tag)
                                }
                            }
                        }
                    }
                } label: {
                    // Menu label
                    Text(issue.issueTagsList)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .animation(nil, value: issue.issueTagsList)
                }
                
                Section {
                    VStack(alignment: .leading) {
                        Text("Description")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        
                        TextField("Description", text: $issue.issueContent, prompt: Text("Enter the issue description here"), axis: .vertical)
                    }
                }
            }
        }
        .disabled(issue.isDeleted)
        // When issue property changes are published
        .onReceive(issue.objectWillChange) { _ in
            // Queue changes for saving
            dataController.queueSave()
        }
    }
}
    struct IssueView_Previews: PreviewProvider {
        static var previews: some View {
            IssueView(issue: .example)
        }
    }
