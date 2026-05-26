//
//  MainContainerView.swift
//  Macro
//
//  Created by Ghida Abdullah al-Mughamer on 25/05/2026.
//

import SwiftUI

public enum RassahTab: Int, CaseIterable {
    case summary = 0
    case house = 1
    case portfolio = 2
    
    var title: String {
        switch self {
        case .summary: return "Summary"
        case .house: return "House"
        case .portfolio: return "portfolio"
        }
    }
    
    var icon: String {
        switch self {
        case .summary: return "chart.bar.xaxis" // Custom graphic mock placeholder
        case .house: return "house"
        case .portfolio: return "arrow.2.squarepath"
        }
    }
}

struct MainContainerView: View {
    @State private var selectedTab: RassahTab = .house
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.rassahBaige
                .ignoresSafeArea()
            
            // Core Application Switcher View Node
            VStack {
                Spacer()
                switch selectedTab {
                case .summary:
                    Text("Summary View Hub") // AnalyticsView link block
                case .house:
                    Text("Central House Hub View") // Grid state
                case .portfolio:
                    Text("Portfolio Detailed Breakdown") // PortfolioListView link block
                }
                Spacer()
            }
            
            // Custom Floating Capsule Tab Selector Asset from Figma
            VStack {
                HStack(spacing: 40) {
                    ForEach(RassahTab.allCases, id: \.self) { tab in
                        Button(action: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                selectedTab = tab
                            }
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 22, weight: selectedTab == tab ? .medium : .light))
                                Text(tab.title)
                                    .font(.rassahSans(size: 11, weight: selectedTab == tab ? .medium : .regular))
                            }
                            .foregroundColor(selectedTab == tab ? Color.rassahBrown : Color.rassahBrown.opacity(0.4))
                            .frame(minWidth: 65)
                        }
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, RassahTokens.paddingLarge)
                .background(Color.rassahWhite)
                .cornerRadius(RassahTokens.radiusCapsule)
                .tactileShadow()
                .padding(.bottom, 24)
            }
        }
    }
}
