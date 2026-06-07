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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .environment(lang)
        }
        .modelContainer(for: [Transaction.self, PortfolioSnapshot.self])
    }
}
