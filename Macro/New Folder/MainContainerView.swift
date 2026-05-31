//
//   MainContainerView.swift
//   Macro
//
//   Created by Ghida Abdullah al-Mughamer on 25/05/2026.
//

import SwiftUI

// MARK: - Tab Schema
public enum RassahTab: Int, CaseIterable {
    case summary   = 0
    case house     = 1
    case portfolio = 2

    var title: String {
        switch self {
        case .summary:   return "Summary"
        case .house:     return "House"
        case .portfolio: return "portfolio"   // lowercase matches Figma label exactly
        }
    }

    var icon: String {
        switch self {
        case .summary:   return "chart.bar.fill"
        case .house:     return "house.fill"
        case .portfolio: return "arrow.2.squarepath"
        }
    }
}

// MARK: - Main Container
struct MainContainerView: View {
    @State private var selectedTab: RassahTab = .house

    var body: some View {
        ZStack(alignment: .bottom) {
            // FIXED: Using direct asset strings to bypass DesignSystem scope errors
            Color("white").ignoresSafeArea()

            // Active screen
            Group {
                switch selectedTab {
                case .summary:
                    SummaryView()
                case .house:
                    AnalyticsView()
                case .portfolio:
                    PortfolioListView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeInOut(duration: 0.2), value: selectedTab)

            // Floating capsule tab bar
            HStack(spacing: 0) {
                ForEach(RassahTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            selectedTab = tab
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 20, weight: selectedTab == tab ? .semibold : .light))
                            Text(tab.title)
                                .font(.system(size: 11, weight: selectedTab == tab ? .bold : .medium))
                        }
                        .foregroundColor(
                            selectedTab == tab ? Color("light brown") : Color("brown").opacity(0.4)
                        )
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 100)
                    .fill(Color("white"))
                    .shadow(color: Color("brown").opacity(0.08), radius: 16, x: 0, y: 8)
                    .shadow(color: Color("brown").opacity(0.02), radius:  4, x: 0, y: 2)
            )
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

#Preview {
    MainContainerView()
        .environment(AppStore())
}
//
