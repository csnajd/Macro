//
//  MacroApp.swift
//  Macro
//
//  Created by Ghida Abdullah al-Mughamer on 26/05/2026.
//

import SwiftUI

@main
struct MacroApp: App {
    // Instantiate your dynamic tracking state single source of truth at launch
    @State private var store = AppStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store) // Injects store globally so all views can look it up safely
        }
    }
}
