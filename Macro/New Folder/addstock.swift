//
//   addstock.swift
//   Macro
//
//   Created by Ghida Abdullah al-Mughamer on 25/05/2026.
//

import SwiftUI
import SwiftData

// MARK: - Discoverable Stock Schema
struct DiscoverableStock: Identifiable {
    var id: String { symbol }
    let symbol: String
    let name: String
    let category: String
}

// Identifiable wrapper whose id IS the symbol, so .sheet(item:) builds a fresh
// buy sheet for each distinct stock (no stale-value reuse).
struct BuyTarget: Identifiable {
    let symbol: String
    var id: String { symbol }
}

// MARK: - Main Add Stock View
public struct AddStockView: View {
    @Environment(AppStore.self) private var store
    @Environment(LanguageManager.self) private var lang
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var selectedCategory: String = "Popular"
    // Tapping a stock sets this; it drives the buy sheet. id == symbol so each
    // distinct stock builds a fresh sheet with the correct value.
    @State private var buyTarget: BuyTarget? = nil

    private let categories = ["Popular", "Banking", "Energy", "Real Estate", "Consumer", "Health"]

    // Preset list of top Saudi Market (Tadawul) equities grouped by sector.
    private let discoverableStocks = [
        DiscoverableStock(symbol: "2010.SR", name: "SABIC", category: "Popular"),
        DiscoverableStock(symbol: "2222.SR", name: "Saudi Aramco", category: "Popular"),
        DiscoverableStock(symbol: "7010.SR", name: "STC", category: "Popular"),
        DiscoverableStock(symbol: "4003.SR", name: "Extra", category: "Popular"),
        DiscoverableStock(symbol: "2280.SR", name: "Almarai", category: "Popular"),

        DiscoverableStock(symbol: "1120.SR", name: "Al Rajhi Bank", category: "Banking"),
        DiscoverableStock(symbol: "1180.SR", name: "SNB (AlAhli)", category: "Banking"),
        DiscoverableStock(symbol: "1150.SR", name: "Alinma Bank", category: "Banking"),
        DiscoverableStock(symbol: "1050.SR", name: "Saudi Fransi", category: "Banking"),

        DiscoverableStock(symbol: "2222.SR", name: "Saudi Aramco", category: "Energy"),
        DiscoverableStock(symbol: "5110.SR", name: "Saudi Electricity", category: "Energy"),
        DiscoverableStock(symbol: "2082.SR", name: "ACWA Power", category: "Energy"),
        DiscoverableStock(symbol: "4290.SR", name: "Aldrees", category: "Energy"),

        DiscoverableStock(symbol: "4300.SR", name: "Dar Al Arkan", category: "Real Estate"),
        DiscoverableStock(symbol: "4250.SR", name: "Jabal Omar", category: "Real Estate"),
        DiscoverableStock(symbol: "4190.SR", name: "Jarir Marketing", category: "Real Estate"),

        DiscoverableStock(symbol: "2280.SR", name: "Almarai", category: "Consumer"),
        DiscoverableStock(symbol: "4003.SR", name: "Extra", category: "Consumer"),
        DiscoverableStock(symbol: "6001.SR", name: "Halwani Bros", category: "Consumer"),

        DiscoverableStock(symbol: "4013.SR", name: "Dr. Sulaiman AlHabib", category: "Health"),
        DiscoverableStock(symbol: "8010.SR", name: "Tawuniya", category: "Health"),
        DiscoverableStock(symbol: "8020.SR", name: "Bupa Arabia", category: "Health")
    ]

    private var categorizedDiscoverableStocks: [DiscoverableStock] {
        discoverableStocks.filter { $0.category == selectedCategory }
    }

    public init() {}

    public var body: some View {
        ZStack(alignment: .bottom) {
            Color("baige").ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
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

                // Search field
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
                .background(Color("dark baige"))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 24)

                if !store.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    // SEARCH RESULTS
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 4) {
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
                                    let sym = item.symbol
                                    store.searchText = ""
                                    attemptBuy(sym)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(store.getReadableName(for: item.symbol))
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(Color("brown"))
                                            Text(item.symbol)
                                                .font(.system(size: 13))
                                                .foregroundColor(Color("brown").opacity(0.6))
                                                .lineLimit(1)
                                        }
                                        Spacer()
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 22))
                                            .foregroundColor(Color("light brown"))
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                    .background(Color("white"))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                    }
                } else {
                    // CATEGORY PILLS + LIST
                    VStack(spacing: 0) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
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
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        .padding(.top, 20)

                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 12) {
                                ForEach(Array(categorizedDiscoverableStocks.enumerated()), id: \.offset) { _, stock in
                                    Button {
                                        attemptBuy(stock.symbol)
                                    } label: {
                                        DiscoverableRowComponent(stock: stock)
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                            .padding(.bottom, 40)
                        }
                    }
                }
            }
        }
        // The proper buy flow: quantity / price / date, real Transaction model.
        .sheet(item: $buyTarget) { target in
            BuyDetailSheet(symbol: target.symbol)
                .environment(store)
                .environment(lang)
        }
    }

    // ✅ FIXED: Instantly sets buy target without any guest sign-in check loops!
    private func attemptBuy(_ symbol: String) {
        buyTarget = BuyTarget(symbol: symbol)
    }
}

// MARK: - Row component
struct DiscoverableRowComponent: View {
    let stock: DiscoverableStock

    var body: some View {
        HStack(spacing: 14) {
            Text(String(stock.name.prefix(3)).uppercased())
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color("brown"))
                .frame(width: 42, height: 42)
                .background(Color("dark baige"))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(stock.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color("brown"))
                Text(stock.symbol)
                    .font(.system(size: 12))
                    .foregroundColor(Color("brown").opacity(0.5))
            }

            Spacer()

            Image(systemName: "plus.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(Color("light brown"))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
