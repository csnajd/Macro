//
//  ContentView.swift
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
    }
}

#Preview {
    ContentView()
        .modelContainer(for: TransactionItem.self, inMemory: true)
        .environment(AppStore())
}
