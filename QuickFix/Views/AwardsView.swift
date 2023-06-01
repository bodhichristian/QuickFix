//
//  AwardsView.swift
//  QuickFix
//
//  Created by christian on 4/7/23.
//

import SwiftUI

struct AwardsView: View {
    @EnvironmentObject var dataController: DataController
    
    @State private var selectedAward = Award.example // example as placeholder instead of optional
    @State private var showingAwardDetails = false
    
    var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 100, maximum: 100))]
    }
    
    var awardTitle: String {
        if dataController.hasEarned(award: selectedAward) {
            return "Unlocked: \(selectedAward.name)"
        } else {
            return "Locked"
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns) {
                    ForEach(Award.allAwards) { award in
                        Button {
                            selectedAward = award
                            showingAwardDetails = true
                        } label: {
                            Image(systemName: award.image)
                                .resizable()
                                .scaledToFit()
                                .padding()
                                .frame(width: 100, height: 100)
                                .foregroundColor(dataController.hasEarned(award: award)
                                                 ? Color(award.color)
                                                 : .secondary.opacity(0.5))
                        }
                        .accessibilityLabel(dataController.hasEarned(award: award)
                                            ? "Unlocked: \(award.name)"
                                            : "Locked")
                        .accessibilityHint(award.description)
                    }
                }
            }
            .navigationTitle("Awards")
        }
        .alert(awardTitle, isPresented: $showingAwardDetails) {
            // Empty for default OK
        } message: {
            Text(selectedAward.description)
        }
    }
}

struct AwardsView_Previews: PreviewProvider {
    static var previews: some View {
        AwardsView()
    }
}
