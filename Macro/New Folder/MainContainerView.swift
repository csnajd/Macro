//
//  MainContainerView.swift
//  Macro
//
//  Created by Ghida Abdullah al-Mughamer on 31/05/2026.
//

import SwiftUI

public enum RassahTab: Int, CaseIterable {
    case summary
    case house
    case portfolio

    var icon: String {
        switch self {
        case .summary:   return "chart.bar.fill"
        case .house:     return "house.fill"
        case .portfolio: return "arrow.2.squarepath"
        }
    }
}

struct MainContainerView: View {
    @Environment(AppStore.self) private var store
    @State private var selectedTab: RassahTab = .house

    var body: some View {
        ZStack(alignment: .bottom) {
            Color("white")
                .ignoresSafeArea()

            Group {
                switch selectedTab {
                case .summary:
                    SummaryView()
                case .house:
                    AnalyticsView()
                        .environment(store)
                case .portfolio:
                    PortfolioListView()
                        .environment(store)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // MARK: - Bottom Floating Capsule Tab Bar Menu
            HStack(spacing: 0) {
                ForEach(RassahTab.allCases, id: \.self) { tab in
                    Spacer()
                    
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            selectedTab = tab
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 20))
                                .foregroundColor(selectedTab == tab ? Color("light brown") : Color("brown").opacity(0.4))
                            
                            Text(tab == .summary ? "Summary" : tab == .house ? "House" : "Portfolio")
                                .font(.system(size: 10, weight: selectedTab == tab ? .semibold : .regular))
                                .foregroundColor(selectedTab == tab ? Color("light brown") : Color("brown").opacity(0.4))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    
                    Spacer()
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            // Integrates beautifully with physical home indicators to touch the baseline glass cleanly
            .padding(.bottom, safeAreaBottomPadding + 4)
            .background(
                RoundedRectangle(cornerRadius: 100)
                    .fill(Color("white"))
                    .shadow(color: Color("brown").opacity(0.06), radius: 16, x: 0, y: -4)
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 6)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
    
    private var safeAreaBottomPadding: CGFloat {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return 12
        }
        return window.safeAreaInsets.bottom > 0 ? 0 : 12
    }
}
