//
//  addstock.swift
//  Macro
//

import SwiftUI
import SwiftData

struct DiscoverableStock: Identifiable {
    var id: String { symbol }
    let symbol: String
    let name: String
    let category: String
}

struct BuyTarget: Identifiable {
    let symbol: String
    var id: String { symbol }
}

public struct AddStockView: View {
    @Environment(AppStore.self) private var store
    @Environment(LanguageManager.self) private var lang
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var selectedCategory: String = "Popular"
    @State private var buyTarget: BuyTarget? = nil
    @State private var showSignInAlert = false

    private let categories = ["Popular", "Banking", "Energy", "Real Estate", "Consumer", "Health"]

    private let discoverableStocks = [
        DiscoverableStock(symbol: "2010.SR", name: "SABIC",                  category: "Popular"),
        DiscoverableStock(symbol: "2222.SR", name: "Saudi Aramco",           category: "Popular"),
        DiscoverableStock(symbol: "7010.SR", name: "STC",                    category: "Popular"),
        DiscoverableStock(symbol: "4003.SR", name: "Extra",                  category: "Popular"),
        DiscoverableStock(symbol: "2280.SR", name: "Almarai",                category: "Popular"),
        DiscoverableStock(symbol: "1120.SR", name: "Al Rajhi Bank",          category: "Banking"),
        DiscoverableStock(symbol: "1180.SR", name: "SNB (AlAhli)",           category: "Banking"),
        DiscoverableStock(symbol: "1150.SR", name: "Alinma Bank",            category: "Banking"),
        DiscoverableStock(symbol: "1050.SR", name: "Saudi Fransi",           category: "Banking"),
        DiscoverableStock(symbol: "2222.SR", name: "Saudi Aramco",           category: "Energy"),
        DiscoverableStock(symbol: "5110.SR", name: "Saudi Electricity",      category: "Energy"),
        DiscoverableStock(symbol: "2082.SR", name: "ACWA Power",             category: "Energy"),
        DiscoverableStock(symbol: "4290.SR", name: "Aldrees",                category: "Energy"),
        DiscoverableStock(symbol: "4300.SR", name: "Dar Al Arkan",           category: "Real Estate"),
        DiscoverableStock(symbol: "4250.SR", name: "Jabal Omar",             category: "Real Estate"),
        DiscoverableStock(symbol: "4190.SR", name: "Jarir Marketing",        category: "Real Estate"),
        DiscoverableStock(symbol: "2280.SR", name: "Almarai",                category: "Consumer"),
        DiscoverableStock(symbol: "4003.SR", name: "Extra",                  category: "Consumer"),
        DiscoverableStock(symbol: "6001.SR", name: "Halwani Bros",           category: "Consumer"),
        DiscoverableStock(symbol: "4013.SR", name: "Dr. Sulaiman AlHabib",   category: "Health"),
        DiscoverableStock(symbol: "8010.SR", name: "Tawuniya",               category: "Health"),
        DiscoverableStock(symbol: "8020.SR", name: "Bupa Arabia",            category: "Health")
    ]

    // Sector label per category for the row tag
    private func sectorLabel(for category: String) -> String {
        switch category {
        case "Banking":     return "Banking"
        case "Energy":      return "Energy"
        case "Real Estate": return "Real Estate"
        case "Consumer":    return "Consumer"
        case "Health":      return "Healthcare"
        default:            return "Saudi Market"
        }
    }

    private var categorizedDiscoverableStocks: [DiscoverableStock] {
        discoverableStocks.filter { $0.category == selectedCategory }
    }

    public init() {}

    public var body: some View {
        ZStack(alignment: .bottom) {
            Color(red: 247/255, green: 246/255, blue: 242/255).ignoresSafeArea()

            VStack(spacing: 0) {

                // MARK: - Header
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color("brown"))
                    }
                    Spacer()
                    Text(lang.t("addstock.title"))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color("brown"))
                    Spacer()
                    CoinBadge()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 16)

                // MARK: - Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color("brown").opacity(0.4))
                    TextField(lang.t("portfolio.searchPlaceholder"), text: Bindable(store).searchText)
                        .font(.system(size: 15))
                        .foregroundColor(Color("brown"))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .onChange(of: store.searchText) { _, query in
                            Task { await store.performSearch(query: query) }
                        }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(Color("white"))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: Color("brown").opacity(0.04), radius: 8, x: 0, y: 2)
                .padding(.horizontal, 24)

                if !store.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    // Search results
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 8) {
                            if store.searchResults.isEmpty {
                                Text(store.searchText.trimmingCharacters(in: .whitespacesAndNewlines).count < 2
                                     ? lang.t("search.minChars")
                                     : lang.t("search.noMatches"))
                                    .font(.system(size: 13))
                                    .foregroundColor(Color("brown").opacity(0.5))
                                    .padding(.vertical, 16)
                            }
                            ForEach(Array(store.searchResults.enumerated()), id: \.offset) { _, item in
                                Button {
                                    store.searchText = ""
                                    attemptBuy(item.symbol)
                                } label: {
                                    HStack {
                                        Text(String(store.getReadableName(for: item.symbol).prefix(2)).uppercased())
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(Color("brown"))
                                            .frame(width: 44, height: 44)
                                            .background(Color("dark baige"))
                                            .clipShape(Circle())

                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(store.getReadableName(for: item.symbol))
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundColor(Color("brown"))
                                            Text(item.symbol)
                                                .font(.system(size: 12))
                                                .foregroundColor(Color("brown").opacity(0.5))
                                        }
                                        Spacer()
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 22))
                                            .foregroundColor(Color("light brown"))
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                    .background(Color("white"))
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 100)
                    }
                } else {
                    // MARK: - Category pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(categories, id: \.self) { category in
                                Button {
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                        selectedCategory = category
                                    }
                                } label: {
                                    Text(lang.t("category.\(category)"))
                                        .font(.system(size: 13, weight: selectedCategory == category ? .semibold : .regular))
                                        .foregroundColor(selectedCategory == category ? Color("white") : Color("brown"))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(selectedCategory == category ? Color("brown") : Color("white"))
                                        .clipShape(Capsule())
                                        .shadow(color: Color("brown").opacity(selectedCategory == category ? 0 : 0.04),
                                                radius: 4, x: 0, y: 2)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.top, 20)

                    // Section label
                    HStack {
                        Text("POPULAR IN SAUDI MARKET")
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(Color("brown").opacity(0.4))
                            .tracking(0.8)
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 8)

                    // MARK: - Stock list (matches design: name+sector left, price+% right)
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 10) {
                            ForEach(Array(categorizedDiscoverableStocks.enumerated()), id: \.offset) { _, stock in
                                Button {
                                    attemptBuy(stock.symbol)
                                } label: {
                                    DiscoverableRowComponent(
                                        stock: stock,
                                        sectorLabel: sectorLabel(for: stock.category),
                                        livePrice: store.livePrice(for: stock.symbol)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 100)
                    }
                }
            }

            // MARK: - Add to portfolio button (matches design: full width bottom CTA)
            Button {
                // opens search drawer or acts as CTA
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Add to portfolio")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color("light brown"))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color("light brown").opacity(0.35), radius: 12, x: 0, y: 5)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .sheet(item: $buyTarget) { target in
            BuyDetailSheet(symbol: target.symbol)
                .environment(store)
                .environment(lang)
        }
        .alert(lang.t("signin.requiredTitle"), isPresented: $showSignInAlert) {
            Button("Sign In") {}
            Button(lang.t("signin.notNow"), role: .cancel) {}
        } message: {
            Text(lang.t("signin.requiredBody"))
        }
    }

    private func attemptBuy(_ symbol: String) {
        guard store.isSignedIn else { showSignInAlert = true; return }
        buyTarget = BuyTarget(symbol: symbol)
    }
}

// MARK: - Row (matches design: avatar + name + sector tag left, price + % right)
struct DiscoverableRowComponent: View {
    let stock: DiscoverableStock
    let sectorLabel: String
    let livePrice: Double?

    var body: some View {
        HStack(spacing: 14) {
            // Avatar
            Text(String(stock.name.prefix(2)).uppercased())
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color("brown"))
                .frame(width: 44, height: 44)
                .background(Color("dark baige"))
                .clipShape(Circle())

            // Name + sector tag
            VStack(alignment: .leading, spacing: 5) {
                Text(stock.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color("brown"))
                Text(sectorLabel)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color("light brown"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color("light brown").opacity(0.12))
                    .clipShape(Capsule())
            }

            Spacer()

            // Price + plus button
            HStack(spacing: 10) {
                if let price = livePrice, price > 0 {
                    Text("\(Int(price)) SAR")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color("brown").opacity(0.7))
                }
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(Color("light brown"))
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color("brown").opacity(0.03), radius: 6, x: 0, y: 2)
    }
}
