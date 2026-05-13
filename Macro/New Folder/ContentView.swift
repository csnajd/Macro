//
//  ContentView.swift
//  Macro
//
//  Created by najd aljarba on 13/05/2026.
//

iimport SwiftUI

struct ContentView: View {
    @State private var hasOnboarded = false
    
    var body: some View {
        if hasOnboarded {
            MainContainerView()
        } else {
            WelcomeView(onGetStarted: {
                withAnimation(.spring()) { hasOnboarded = true }
            })
        }
    }
}

#Preview {
    ContentView()
}
