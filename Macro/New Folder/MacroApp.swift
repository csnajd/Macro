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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
        }
        // ✅ Persistent local device database container engine initialization
        .modelContainer(for: TransactionItem.self)
    }
}
