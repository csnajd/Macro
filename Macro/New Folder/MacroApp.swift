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
    @State private var store = AppStore()
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
        .modelContainer(for: [Transaction.self, PortfolioSnapshot.self])
    }
}
