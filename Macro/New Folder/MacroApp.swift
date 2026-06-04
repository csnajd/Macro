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
    // ✅ Initialized as an AppStore subclass wrapper instance to satisfy ancestral lookups
    @StateObject private var store = AppStore()
    @State private var lang = LanguageManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                // ✅ Satisfies all subview lookups searching for either AppStore or GhinahAppStore
                .environmentObject(store)
                .environment(lang)
        }
        .modelContainer(for: [Transaction.self, PortfolioSnapshot.self])
    }
}
