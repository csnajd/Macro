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

            // Floating tab bar
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
                            Text(lang.t(tab.labelKey))
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
        .sheet(isPresented: $showProfile) {
            ProfileView()
                .environment(store)
                .environment(lang)
        }
    }

    private var safeAreaBottomPadding: CGFloat {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return 12 }
        return window.safeAreaInsets.bottom > 0 ? 0 : 12
    }
}

// MARK: - Profile Avatar Button (used inside each screen's header)
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
