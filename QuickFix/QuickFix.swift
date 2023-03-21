//
//  PortfolioAppApp.swift
//  PortfolioApp
//
//  Created by christian on 3/13/23.
//

import SwiftUI

@main
struct QuickFix: App {
    @StateObject var dataController = DataController()
    @Environment(\.scenePhase) var scenePhase
    
    var body: some Scene {
        WindowGroup {
            NavigationSplitView {
                SidebarView()
            } content: {
                ContentView()
            } detail: {
                DetailView()
            }
            .environment(\.managedObjectContext, dataController.container.viewContext)
            .environmentObject(dataController)
            // When scene changes
            .onChange(of: scenePhase) { phase in
                // If not in active phase
                if phase != .active {
                    // Save changes
                    dataController.save()
                }
            }
        }
    }
}







