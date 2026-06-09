//
//  ContentView.swift
//  Macro
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AppStore.self) private var store
    @Environment(LanguageManager.self) private var lang

    @AppStorage("hasLaunchedBefore") private var hasLaunchedBefore = false

    var body: some View {
        Group {
            if hasLaunchedBefore {
                MainContainerView()
                    .transition(.opacity)
            } else {
                WelcomView(onFinish: {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        hasLaunchedBefore = true
                    }
                })
                .transition(.opacity)
            }
        }
        .environment(\.layoutDirection, lang.current.layoutDirection)
    }
}
