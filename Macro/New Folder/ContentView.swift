//
//  ContentView.swift
//  Macro
//
//  Created by Ghida Abdullah al-Mughamer on 25/05/2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    // Reads the SINGLE store + language manager injected by MacroApp.
    @Environment(AppStore.self) private var store
    @Environment(LanguageManager.self) private var lang
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
        // Drive the whole app's layout direction from the language setting.
        // Arabic → right-to-left, English → left-to-right. Switching the
        // language flips the entire UI instantly.
        .environment(\.layoutDirection, lang.current.layoutDirection)
    }
}

#Preview {
    ContentView()
        .environment(AppStore())
        .environment(LanguageManager())
        .modelContainer(for: [Transaction.self, PortfolioSnapshot.self], inMemory: true)
}
