//
//  DataController.swift
//  PortfolioApp
//
//  Created by christian on 3/13/23.
//

import CoreData

class DataController: ObservableObject {
    // The container that holds the Core Data stack
    let container: NSPersistentCloudKitContainer
    
    // Announces changes for the currently selected filter
    @Published var selectedFilter: Filter? = Filter.all
    // Announces changes for the selected issue in ContentView
    @Published var selectedIssue: Issue?
    
    // A static instance of the DataController that can be used for previews
    static var preview: DataController = {
        let dataController = DataController(inMemory: true)
        dataController.createSampleData()
        return dataController
    }()
    
    // Initializes the Core Data stack
    init(inMemory: Bool = false ) {
        container = NSPersistentCloudKitContainer(name: "Main")
        
        // Configure the persistent store for in-memory usage
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(filePath: "/dev/null")
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        // Prioritize newer data
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        // Announce when remote changers occur
        container.persistentStoreDescriptions.first?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        // When changes occur, call remoteStoreChanged(_ notification:)
        NotificationCenter.default.addObserver(forName: .NSPersistentStoreRemoteChange, object: container.persistentStoreCoordinator, queue: .main, using: remoteStoreChanged)
        // Load the persistent stores and handle any errors
        container.loadPersistentStores { storeDescription, error in
            if let error = error {
                fatalError("Fatal error loading store: \(error.localizedDescription)")
            }
        }
    }
    
    func remoteStoreChanged(_ notification: Notification) {
        objectWillChange.send()
    }
    
    // Creates sample data and saves it to the persistent store
    func createSampleData() {
        // Get the managed object context from the container
        let viewContext = container.viewContext
        
        // Create some sample tags and issues
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
        
        // Save the sample data to the persistent store
        try? viewContext.save()
    }
    
    // Saves changes to the managed object context
    func save() {
        // Only save if there are changes in the managed object context
        if container.viewContext.hasChanges {
            try? container.viewContext.save()
        }
    }
    
    // Deletes a managed object from the managed object context
    func delete(_ object: NSManagedObject) {
        // Notify observers that the object is about to be deleted
        objectWillChange.send()
        
        // Delete the object from the managed object context and save changes
        container.viewContext.delete(object)
        save()
    }
    
    // Deletes all managed objects that match a fetch request
    private func delete(_ fetchRequest: NSFetchRequest<NSFetchRequestResult>) {
        // Create a batch delete request with the specified fetch request
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        // Specify that we want to receive object IDs as the result type
        batchDeleteRequest.resultType = .resultTypeObjectIDs
        
        // Execute the batch delete request and handle any errors
        if let delete = try? container.viewContext.execute(batchDeleteRequest) as? NSBatchDeleteResult {
            // Create a dictionary that maps deleted objects to their object IDs
            let changes = [NSDeletedObjectsKey: delete.result as? [NSManagedObjectID] ?? []]
            
            // Merge the changes into the managed object context
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [container.viewContext])
        }
    }
    
    // Deletes all tags and issues from the persistent store.
    func deleteAll() {
        // Fetch all tags
        let request1: NSFetchRequest<NSFetchRequestResult> = Tag.fetchRequest()
        delete(request1)
        
        // Fetch all issues
        let request2: NSFetchRequest<NSFetchRequestResult> = Issue.fetchRequest()
        delete(request2)
        
        // Save changes
        save()
    }
    
    func missingTags(from issue: Issue) -> [Tag] {
        let request = Tag.fetchRequest()
        // Fetch all tags
        let allTags = (try? container.viewContext.fetch(request)) ?? []
        // Create a set of fetched tags
        let allTagsSet = Set(allTags)
        // Evaluate which tags are missing
        let difference = allTagsSet.symmetricDifference(issue.issueTags)
        // Return missing tags
        return difference.sorted()
    }
}
