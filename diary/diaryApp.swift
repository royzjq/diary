//
//  diaryApp.swift
//  diary
//
//  Created by tfj on 31/12/24.
//

import SwiftUI

@main
struct diaryApp: App {
    let persistenceController = PersistenceController.shared
    @AppStorage("hasSelectedStyle") private var hasSelectedStyle = false
    @State private var showingStyleSelection = false
    
    var body: some Scene {
        WindowGroup {
            if !hasSelectedStyle {
                NavigationView {
                    StyleSelectionView(onComplete: {
                        hasSelectedStyle = true
                    })
                }
            } else {
                HomeView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            }
        }
    }
}
