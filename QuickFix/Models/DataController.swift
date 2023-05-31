//
//  DataController.swift
//  PortfolioApp
//
//  Created by christian on 3/13/23.
//

import CoreData

enum SortType: String {
    case dateCreated = "creationDate"
    case dateModified = "modificationDate"
}

enum Status {
    case all, open, closed
}


class DataController: ObservableObject {
    // The container that holds the Core Data stack
    let container: NSPersistentCloudKitContainer
    
    // Announces changes for the currently selected filter
    @Published var selectedFilter: Filter? = Filter.all
    // Announces changes for the selected issue in ContentView
    @Published var selectedIssue: Issue?
    // Announces changes for user's search query
    @Published var filterText = ""
    // Initializes an empty array for filter tokens to be added
    @Published var filterTokens = [Tag]()
    
    // Filter options
    @Published var filterEnabled = false
    @Published var filterPriority = -1
    @Published var filterStatus = Status.all
    @Published var sortType = SortType.dateCreated
    @Published var sortNewestFirst = true
    
    private var saveTask: Task<Void, Error>?
    
    // A static instance of the DataController that can be used for previews
    static var preview: DataController = {
        let dataController = DataController(inMemory: true)
        dataController.createSampleData()
        return dataController
    }()
    
    var suggestedFilterTokens: [Tag] {
        guard filterText.starts(with: "#") else {
            return []
        }
        
        let trimmedFilterText = String(filterText.dropFirst()).trimmingCharacters(in: .whitespaces)
        let request = Tag.fetchRequest()
        
        if trimmedFilterText.isEmpty == false {
            request.predicate = NSPredicate(format: "name CONTAINS[c] %@", trimmedFilterText)
        }
        
        return (try? container.viewContext.fetch(request).sorted()) ?? []
    }
    
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
    
    func queueSave() {
        // Cancel current task if it exists
        saveTask?.cancel()
        // MainActor Task: Wait three seconds, then save
        saveTask = Task { @MainActor in
            print("Queueing changes...")
            try await Task.sleep(for: .seconds(3))
            save()
            print("Changes saved.")
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
    
    // Return an array of Issues, sorted by tags if present
    func issuesForSelectedFilter() -> [Issue] {
        let filter = selectedFilter ?? .all // The selected filter in the data controller
        var predicates = [NSPredicate]() // An array of predicates for use in the fetch request
        
        // If the filter specifies a tag, create a predicate to fetch all issues associated with that tag
        if let tag = filter.tag {
            let tagPredicate = NSPredicate(format: "tags CONTAINS %@", tag)
            predicates.append(tagPredicate)
        } else {
            // If the filter doesn't specify a tag, create a predicate to fetch issues that have been modified since the minimum modification date filter
            let datePredicate = NSPredicate(format: "modificationDate > %@", filter.minModificationDate as NSDate)
            predicates.append(datePredicate)
        }
        
        let trimmedFilterText = filterText.trimmingCharacters(in: .whitespaces)
        
        if trimmedFilterText.isEmpty == false {
            // Create a case-insensitive title predicate
            let titlePredicate = NSPredicate(format: "title CONTAINS[c] %@", trimmedFilterText)
            // Create a case-insensitive content predicate
            let contentPredicate = NSPredicate(format: "content CONTAINS[c] %@", trimmedFilterText)
            // Create a compound OR predicate with titlePredicate and contentPredicate
            let combinedPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [titlePredicate, contentPredicate])
            predicates.append(combinedPredicate)
        }
        
        // If filter tokens exist, append selected tokens to predicate
        if filterTokens.isEmpty == false {
            for filterToken in filterTokens {
                let tokenPredicate = NSPredicate(format: "tags CONTAINS %@", filterToken)
                predicates.append(tokenPredicate)
            }

        }
        
        // If filtering
        if filterEnabled {
            // If a priorty is the filter
            if filterPriority >= 0 {
                // Create a predicate to filter tasks by priority
                let priorityFilter = NSPredicate(format: "priority = %d", filterPriority)
                // Append the priority predicate to the predicates array
                predicates.append(priorityFilter)
            }
            
            // If a filterStatus is set
            if filterStatus != .all {
                // Check if filter is looking for closed tasks (true if closed)
                let lookForClosed = filterStatus == .closed
                // Create a predicate to filter tasks by status
                let statusFilter = NSPredicate(format: "completed = %@", NSNumber(value: lookForClosed))
                // Append the status predicate to the predicates array
                predicates.append(statusFilter)
            }
        }
        
        // Fetch all issues that match the predicates from the view context
        let request = Issue.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.sortDescriptors = [NSSortDescriptor(key: sortType.rawValue, ascending: sortNewestFirst)]
        let allIssues = (try? container.viewContext.fetch(request)) ?? []
        
        // Return the sorted array of issues
        return allIssues.sorted()
    }
    
    func newTag() {
        let tag = Tag(context: container.viewContext)
        tag.id = UUID()
        tag.name = "New Tag"
        save()
    }
    
    func newIssue() {
        // Create a new issue object from the view context
        let issue = Issue(context: container.viewContext)
        
        // Assign initial values
        issue.title = "New Issue"
        issue.creationDate = .now
        issue.priority = 0
        
        // If user is viewing a partcitular tag
        if let tag = selectedFilter?.tag {
            // Add that tag to the issue object
            issue.addToTags(tag)
        }
        
        save()
        // Navigate to IssueView to edit newly created issue
        selectedIssue = issue
    }
    
    // Count items of a type for a given fetch request
    func count<T>(for fetchRequest: NSFetchRequest<T>) -> Int {
        (try? container.viewContext.count(for: fetchRequest)) ?? 0
    }
    
    func hasEarned(award: Award) -> Bool {
        switch award.criterion {
        case "issues":
            // Return true if they added a certain number of issues
            let fetchRequest = Issue.fetchRequest()
            let awardCount = count(for: fetchRequest)
            return awardCount >= award.value
            
        case "closed":
            // Return true if they closed a certain number of issues
            let fetchRequest = Issue.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "completed = true")
            let awardCount = count(for: fetchRequest)
            return awardCount >= award.value
            
        case "tags":
            // Return true if they created a certain number of tags
            let fetchRequest = Tag.fetchRequest()
            let awardCount = count(for: fetchRequest)
            return awardCount >= award.value
            
        default:
            // An unknown award criterion--this should never be allowed
            // fatalError("Unkown award criterion: \(award.criterion)")
            return false
        }
    }
    

}
