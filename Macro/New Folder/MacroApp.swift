//
//  MacroApp.swift
//  Macro
//

import SwiftUI
import SwiftData

@main
struct MacroApp: App {
    @State private var store = AppStore()
    @State private var lang  = LanguageManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .environment(lang)
                .onAppear {
                    store.restoreSession()
                }
        }
        .modelContainer(for: [Transaction.self, PortfolioSnapshot.self])
    }
}
