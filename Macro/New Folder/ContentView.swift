//
//  ContentView.swift
//  Macro
//
//  Created by Ghida Abdullah al-Mughamer on 25/05/2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var hasStartedApp = false
    // CRITICAL FIX: Instantiate the global store here at the root level!
    @State private var store = AppStore()
    
    var body: some View {
        Group {
            if hasStartedApp {
                MainContainerView()
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else {
                WelcomView(hasStartedApp: $hasStartedApp)
                    .transition(.opacity)
            }
        }
        // CRITICAL FIX: Inject the environment globally down into the view hierarchy
        .environment(store)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: TransactionItem.self, inMemory: true)
}
