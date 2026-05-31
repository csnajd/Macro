//
//  ContentView.swift
//  Macro
//
//  Created by Ghida Abdullah al-Mughamer on 25/05/2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var store = AppStore()
    @State private var hasStartedApp: Bool = false

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
        .environment(store)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: TransactionItem.self, inMemory: true)
}
