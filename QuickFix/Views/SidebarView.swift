//
//  SidebarView.swift
//  PortfolioApp
//
//  Created by christian on 3/14/23.
//

import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var dataController: DataController
    let smartFilters: [Filter] = [.all, .recent]
    
    @FetchRequest(sortDescriptors: [SortDescriptor(\.name)]) var tags: FetchedResults<Tag>
    
    @State private var tagToRename: Tag?
    @State private var renamingTag = false
    @State private var tagName = ""
    
    var tagFilters: [Filter] {
        tags.map { tag in
            Filter(id: tag.tagID, name: tag.tagName, icon: "tag", tag: tag)
        }
    }
    
    var body: some View {
        List(selection: $dataController.selectedFilter) {
            Section("Smart Filters") {
                ForEach(smartFilters) { filter in
                    NavigationLink(value: filter) {
                        Label(filter.name, systemImage: filter.icon)
                    }
                }
            }
            
            Section("Tags") {
                ForEach(tagFilters) { filter in
                    NavigationLink(value: filter) {
                        Label(filter.name, systemImage: filter.icon)
                            .badge(filter.tag?.tagActiveIssues.count ?? 0)
                            .contextMenu {
                                Button {
                                    rename(filter)
                                } label: {
                                    Label("Rename", systemImage: "pencil")
                                }
                            }
                    }
                }
                .onDelete(perform: delete)
            }
        }
        .navigationTitle("QuickFix")
        .toolbar {
            Button(action: dataController.newTag) {
                Label("Add tag", systemImage: "plus")
            }

// Only visibile if running in Xcode.
//            #if DEBUG
//            Button {
//                dataController.deleteAll()
//                dataController.createSampleData()
//            } label: {
//                Label("Add Samples", systemImage: "dice")
//            }
//            #endif
        }
        .alert("Rename Tag", isPresented: $renamingTag) {
            Button("OK", action: completeRename)
            Button("Cancel", role: .cancel) { }
            TextField("New name", text: $tagName)
        }
    }
    
    // Delete tags
    func delete(_ offsets: IndexSet) {
        for offset in offsets {
            let item = tags[offset]
            dataController.delete(item)
        }
    }
    // Rename a tag in a Filter
    func rename(_ filter: Filter) {
        tagToRename = filter.tag
        tagName = filter.name
        renamingTag = true
    }
    // Update tag name property and save changes to datacontroller
    func completeRename() {
        tagToRename?.name = tagName
        dataController.save()
    }
}

struct SidebarView_Previews: PreviewProvider {
    static var previews: some View {
        SidebarView()
            .environmentObject(DataController.preview)
    }
}
