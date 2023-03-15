//
//  DataController.swift
//  PortfolioApp
//
//  Created by christian on 3/13/23.
//

import CoreData

class DataController: ObservableObject {
    let container: NSPersistentCloudKitContainer
    
    @Published var selectedFilter: Filter? = Filter.all
    
    static var preview: DataController = {
        let dataController = DataController(inMemory: true)
        dataController.createSampleData()
        return dataController
    }()
    
    init(inMemory: Bool = false ) {
        container = NSPersistentCloudKitContainer(name: "Main")
        
        if inMemory {
            // If in memory, save nowhere
            container.persistentStoreDescriptions.first?.url = URL(filePath: "/dev/null")
        }
        
        container.loadPersistentStores { storeDescription, error in
            if let error {
                fatalError("Fatal error loading store: \(error.localizedDescription)")
            }
        }
    }
    
    func createSampleData() {
        // Current pool of data in RAM
        let viewContext = container.viewContext
        
        for i in 1...5 {
            let tag = Tag(context: viewContext)
            tag.id = UUID()
            tag.name = "Tag \(i)"
            
            for j in 1...10 {
                let issue = Issue(context: viewContext)
                issue.title = "Issue \(i)-\(j)"
                issue.content = "Description goes here"
                issue.creationDate = .now
                issue.completed = Bool.random()
                issue.priority = Int16.random(in: 0...2)
                tag.addToIssues(issue)
            }
        }
        // Write sample data to persistent storage
        try? viewContext.save()
    }
    
    func save() {
        // Saves only if viewContext has been changed
        if container.viewContext.hasChanges {
            try? container.viewContext.save()
        }
    }
    
    func delete(_ object: NSManagedObject) {
        objectWillChange.send()
        container.viewContext.delete(object)
        save()
    }
    
    private func delete(_ fetchRequest: NSFetchRequest<NSFetchRequestResult>) {
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        // Receive Object IDs as result type
        batchDeleteRequest.resultType = .resultTypeObjectIDs

        // Fetch request
        // .execute() takes any fetch request
        // Typecast as NSBatchDeleteResult
        if let delete = try? container.viewContext.execute(batchDeleteRequest) as? NSBatchDeleteResult {
            // Create a dictionary
            // Typecast result as an array of NSManagedObjectID
            // delete.result is of type Any?
            let changes = [NSDeletedObjectsKey: delete.result as? [NSManagedObjectID] ?? []]
            // Merge the changes to the view context
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [container.viewContext])
        }
    }
    
    func deleteAll() {
        let request1: NSFetchRequest<NSFetchRequestResult> = Tag.fetchRequest()
        delete(request1)
        
        let request2: NSFetchRequest<NSFetchRequestResult> = Issue.fetchRequest()
        delete(request2)
        
        save()
    }
}
