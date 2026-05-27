//
//  MainContainerView.swift
//  Macro
//
//  Created by Ghida Abdullah al-Mughamer on 25/05/2026.
//

import SwiftUI

// MARK: - Navigation Tab Schema Mapping
public enum RassahTab: Int, CaseIterable {
    case summary = 0
    case house = 1
    case portfolio = 2
    
    /// Tab Titles matching your exact lowercase Figma labels
    var title: String {
        switch self {
        case .summary: return "Summary"
        case .house: return "House"
        case .portfolio: return "portfolio" // Explicit lowercase 'p' from wireframe
        }
    }
    
    /// Target platform system layout icons
    var icon: String {
        switch self {
        case .summary: return "chart.bar.fill"       // Premium multi-segment chart shape
        case .house: return "house.fill"             // Central house core node icon
        case .portfolio: return "arrow.2.squarepath" // Looped dynamic asset flow indicator
        }
    }
}

// MARK: - Main Multi-Screen Container Blueprint
struct MainContainerView: View {
    @State private var selectedTab: RassahTab = .portfolio // Starts on portfolio screen by default
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color("baige")
                .ignoresSafeArea()
            
            // MARK: - Central Active Content Layer Switcher
            VStack {
                switch selectedTab {
                case .summary:
                    AnalyticsView() // Your gorgeous complete segmented donut chart hub
                case .house:
                    // Empty placeholder layout state node for your next feature sprint
                    VStack {
                        Spacer()
                        Text("Central House Hub Blueprint Area")
                            .font(.system(size: 16, design: .default))
                            .foregroundColor(Color("brown").opacity(0.3))
                        Spacer()
                    }
                case .portfolio:
                    PortfolioListView() // Your live accounting list ledger card stack
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // MARK: - Floating Capsule Navigation Controller Asset
            HStack(spacing: 0) {
                ForEach(RassahTab.allCases, id: \.self) { tab in
                    Button(action: {
                        // Smooth tactile spring response when switching panels
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            selectedTab = tab
                        }
                    }) {
                        VStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 21, weight: selectedTab == tab ? .semibold : .light))
                            Text(tab.title)
                                .font(.system(size: 11, weight: selectedTab == tab ? .bold : .medium, design: .default))
                        }
                        // Active selector maps to light brown, dormant items fade elegantly to brown opacity
                        .foregroundColor(selectedTab == tab ? Color("light brown") : Color("brown").opacity(0.4))
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: RassahTokens.radiusCapsule)
                    .fill(Color("white"))
                    // Multi-layered subtle shadow framework mimicking your clay depths
                    .shadow(color: Color("brown").opacity(0.08), radius: 16, x: 0, y: 8)
                    .shadow(color: Color("brown").opacity(0.02), radius: 4, x: 0, y: 2)
            )
            .padding(.horizontal, RassahTokens.paddingXL) // Contracts container into a floating capsule asset shape
            .padding(.bottom, 24) // Floating lift clearance gap pushing bar cleanly above safe guidelines
        }
        .ignoresSafeArea(.keyboard, edges: .bottom) // UI security override layout protection
    }
}

// MARK: - Preview Pipeline Container
#Preview {
    MainContainerView()
        .environment(AppStore())
}
