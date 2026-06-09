//
//  MainContainerView.swift
//  Macro
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

    var labelKey: String {
        switch self {
        case .summary:   return "tab.summary"
        case .house:     return "tab.house"
        case .portfolio: return "tab.portfolio"
        }
    }
}

struct MainContainerView: View {
    @Environment(AppStore.self) private var store
    @Environment(LanguageManager.self) private var lang
    @State private var selectedTab: RassahTab = .house
    @State private var showProfile = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Color("white").ignoresSafeArea()

            Group {
                switch selectedTab {
                case .summary:
                    SummaryView(showProfile: $showProfile)
                case .house:
                    AnalyticsView(showProfile: $showProfile)
                        .environment(store)
                case .portfolio:
                    PortfolioListView(showProfile: $showProfile)
                        .environment(store)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // MARK: - Tab Bar (matches design: equal thirds, icon+label, active highlight)
            HStack(spacing: 0) {
                ForEach(RassahTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            selectedTab = tab
                        }
                    } label: {
                        VStack(spacing: 5) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 22, weight: selectedTab == tab ? .semibold : .regular))
                                .foregroundColor(selectedTab == tab ? Color("light brown") : Color("brown").opacity(0.35))
                                .frame(width: 44, height: 28)
                            Text(lang.t(tab.labelKey))
                                .font(.system(size: 11, weight: selectedTab == tab ? .semibold : .regular))
                                .foregroundColor(selectedTab == tab ? Color("light brown") : Color("brown").opacity(0.35))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, safeAreaBottomPadding)
            .background(
                Color("white")
                    .shadow(color: Color("brown").opacity(0.07), radius: 20, x: 0, y: -6)
            )
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .sheet(isPresented: $showProfile) {
            ProfileView()
                .environment(store)
                .environment(lang)
        }
    }

    private var safeAreaBottomPadding: CGFloat {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return 16 }
        return window.safeAreaInsets.bottom > 0 ? window.safeAreaInsets.bottom : 16
    }
}

// MARK: - Profile Avatar Button
struct ProfileAvatarButton: View {
    @Environment(AppStore.self) private var store
    let action: () -> Void

    private var savedImageData: Data? {
        UserDefaults.standard.data(forKey: "profileImageData")
    }

    var body: some View {
        Button(action: action) {
            Group {
                if let data = savedImageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack {
                        Color("dark baige")
                        Image(systemName: store.isSignedIn ? "person.fill" : "person.badge.plus")
                            .font(.system(size: 14))
                            .foregroundColor(Color("brown").opacity(0.6))
                    }
                }
            }
            .frame(width: 34, height: 34)
            .clipShape(Circle())
            .overlay(
                Circle().stroke(
                    store.isSignedIn ? Color("light brown").opacity(0.5) : Color("brown").opacity(0.2),
                    lineWidth: 1.5
                )
            )
        }
    }
}
