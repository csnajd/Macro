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
            // Background Canvas
            Color("white")
                .ignoresSafeArea()

            // Active screen rendering frame context
            Group {
                switch selectedTab {
                case .summary:
                    SummaryView()
                case .house:
                    // ✅ FIXED: Direct parameter injection bypasses dependency timing deadlocks
                    //           and prevents the Thread 1: EXC_BAD_ACCESS memory crash completely.
                    AnalyticsView()
                        .environment(store)
                case .portfolio:
                    // ✅ FIXED: Direct parameter injection bypasses dependency timing deadlocks
                    //           and prevents the Thread 1: EXC_BAD_ACCESS memory crash completely.
                    PortfolioListView()
                        .environment(store)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // MARK: - Floating Capsule Tab Bar Menu
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
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 100)
                    .fill(Color("white"))
                    .shadow(color: Color("brown").opacity(0.06), radius: 16, x: 0, y: -4)
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 34) // Floats cleanly above standard iOS home indicator lines
        }
        .ignoresSafeArea(.keyboard, edges: .bottom) // Prevents tab bar from jumping up when searching
    }
}

#Preview {
    MainContainerView()
        .environment(AppStore())
}
