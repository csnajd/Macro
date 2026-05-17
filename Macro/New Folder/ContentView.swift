//
//  ContentView.swift
//  Macro
//
//  Created by najd aljarba on 13/05/2026.
//

import SwiftUI

struct ContentView: View {
    @State private var hasOnboarded = false
    
    var body: some View {
        if hasOnboarded {
            MainContainerView()
        } else {
            WelcomView(onGetStarted: {
                withAnimation(.spring()) { hasOnboarded = true }
            })
        }
    }
}

#Preview {
    ContentView()
}
