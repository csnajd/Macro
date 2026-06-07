//
//  MacroApp.swift
//  Macro
//
//  Created by Ghida Abdullah al-Mughamer on 25/05/2026.
//

import SwiftUI
import SwiftData

@main
struct MacroApp: App {
    // The ONE and only AppStore for the whole app.
    @State private var store = AppStore()
    // App-wide language manager (Arabic by default, persisted).
    @State private var lang = LanguageManager()
    // Apple sign-in state (guests can browse; adding stocks requires sign-in).
    @State private var auth = AuthManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .environment(lang)
                .environment(auth)
        }
        // Persisted store: transactions + value snapshots.
        .modelContainer(for: [Transaction.self, PortfolioSnapshot.self])
    }
}
