//
//   PortfolioListView.swift
//   Macro
//
//   Created by Ghida Abdullah al-Mughamer on 31/05/2026.
//


import SwiftUI
import SwiftData

public struct PortfolioListView: View {
    @Environment(AppStore.self) private var store
    @Environment(LanguageManager.self) private var lang
    @Environment(\.modelContext) private var modelContext

    @State private var isSearchDrawerExpanded: Bool = false
    @State private var selectedCategory: String = "Popular"
    // The holding the user tapped, shown in the sell sheet.
    // Single sheet router (see the .sheet on body for why it's combined).
    @State private var activeSheet: ActiveSheet? = nil
    // A holding awaiting delete confirmation.
    @State private var pendingRemoval: PortfolioMath.Position? = nil

    @Query private var transactions: [Transaction]

    private let categories = ["Popular", "Banking", "Energy", "Real Estate", "Consumer", "Health"]

    private let discoverableStocks = [
        DiscoverableStock(symbol: "2222.SR", name: "Saudi Aramco",     category: "Popular"),
        DiscoverableStock(symbol: "2010.SR", name: "SABIC",            category: "Popular"),
        DiscoverableStock(symbol: "7010.SR", name: "STC",              category: "Popular"),
        DiscoverableStock(symbol: "1120.SR", name: "Al Rajhi Bank",    category: "Popular"),
        DiscoverableStock(symbol: "2082.SR", name: "ACWA Power",       category: "Popular"),
        DiscoverableStock(symbol: "4003.SR", name: "Extra",            category: "Popular"),
        DiscoverableStock(symbol: "2280.SR", name: "Almarai",          category: "Popular"),

        DiscoverableStock(symbol: "1120.SR", name: "Al Rajhi Bank",    category: "Banking"),
        DiscoverableStock(symbol: "1180.SR", name: "SNB (AlAhli)",     category: "Banking"),
        DiscoverableStock(symbol: "1150.SR", name: "Alinma Bank",      category: "Banking"),
        DiscoverableStock(symbol: "1050.SR", name: "Saudi Fransi",     category: "Banking"),
        DiscoverableStock(symbol: "1060.SR", name: "SAIB",             category: "Banking"),
        DiscoverableStock(symbol: "1020.SR", name: "Bank AlBilad",     category: "Banking"),
        DiscoverableStock(symbol: "1030.SR", name: "Saudi Investment", category: "Banking"),

        DiscoverableStock(symbol: "2222.SR", name: "Saudi Aramco",     category: "Energy"),
        DiscoverableStock(symbol: "5110.SR", name: "Saudi Electricity",category: "Energy"),
        DiscoverableStock(symbol: "2082.SR", name: "ACWA Power",       category: "Energy"),
        DiscoverableStock(symbol: "4290.SR", name: "Aldrees",          category: "Energy"),
        DiscoverableStock(symbol: "2020.SR", name: "SAFCO / SABIC AN", category: "Energy"),
        DiscoverableStock(symbol: "2310.SR", name: "Sipchem",          category: "Energy"),
        DiscoverableStock(symbol: "2060.SR", name: "Tasnee",           category: "Energy"),

        DiscoverableStock(symbol: "4300.SR", name: "Dar Al Arkan",     category: "Real Estate"),
        DiscoverableStock(symbol: "4090.SR", name: "Taiba Investments",category: "Real Estate"),
        DiscoverableStock(symbol: "4150.SR", name: "Arriyadh Development", category: "Real Estate"),
        DiscoverableStock(symbol: "4250.SR", name: "Jabal Omar",       category: "Real Estate"),
        DiscoverableStock(symbol: "4190.SR", name: "Jarir Marketing",  category: "Real Estate"),

        DiscoverableStock(symbol: "2280.SR", name: "Almarai",          category: "Consumer"),
        DiscoverableStock(symbol: "4003.SR", name: "Extra",            category: "Consumer"),
        DiscoverableStock(symbol: "4005.SR", name: "Anan Care (Cenomi)",category: "Consumer"),
        DiscoverableStock(symbol: "4200.SR", name: "Aldrees Transport",category: "Consumer"),
        DiscoverableStock(symbol: "6001.SR", name: "Halwani Bros",     category: "Consumer"),
        DiscoverableStock(symbol: "4040.SR", name: "SAPTCO",           category: "Consumer"),

        DiscoverableStock(symbol: "4009.SR", name: "Saudi German Health", category: "Health"),
        DiscoverableStock(symbol: "4013.SR", name: "Dr. Sulaiman AlHabib", category: "Health"),
        DiscoverableStock(symbol: "2060.SR", name: "Dallah Healthcare",   category: "Health"),
        DiscoverableStock(symbol: "8010.SR", name: "Tawuniya Insurance",  category: "Health"),
        DiscoverableStock(symbol: "8020.SR", name: "Bupa Arabia",         category: "Health")
    ]

    private var categorizedDiscoverableStocks: [DiscoverableStock] {
        discoverableStocks.filter { $0.category == selectedCategory }
    }

    private var positions: [PortfolioMath.Position] {
        PortfolioMath.allPositions(from: transactions)
    }

    private var totalCostBasis: Double {
        PortfolioMath.totalCostBasis(from: transactions)
    }

    private var totalCurrentValue: Double {
        positions.reduce(0.0) { sum, pos in
            let price = store.livePrice(for: pos.symbol) ?? pos.averageBuyPrice
            return sum + price * Double(pos.quantity)
        }
    }

    public init() {}

    public var body: some View {
        ZStack(alignment: .bottom) {
            Color("white").ignoresSafeArea()

            VStack(spacing: 0) {
                HStack(alignment: .center) {
                    Text(lang.t("portfolio.title"))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color("brown"))
                    Spacer()
                    CoinBadge()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                StatHeaderView(
                    totalInvested: totalCostBasis,
                    totalGain: totalCurrentValue - totalCostBasis
                )

                List {
                    if isSearchDrawerExpanded {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(Color("brown").opacity(0.4))
                                TextField(lang.t("portfolio.searchPlaceholder"), text: Bindable(store).searchText)
                                    .font(.system(size: 15))
                                    .foregroundColor(Color("brown"))
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.characters)
                                    .onChange(of: store.searchText) { _, query in
                                        Task { await store.performSearch(query: query) }
                                    }
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Color("dark baige"))
                            .clipShape(RoundedRectangle(cornerRadius: 14))

                            if !store.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                VStack(spacing: 4) {
                                    ForEach(Array(store.searchResults.enumerated()), id: \.offset) { _, item in
                                        Button {
                                            activeSheet = .buy(item.symbol)
                                        } label: {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(item.symbol).bold().foregroundColor(Color("brown"))
                                                    Text(item.longname ?? item.shortname ?? "Asset").font(.system(size: 13)).foregroundColor(Color("brown").opacity(0.6))
                                                }
                                                Spacer()
                                                Image(systemName: "plus.circle.fill").foregroundColor(Color("light brown"))
                                            }
                                            .padding(.vertical, 12).padding(.horizontal, 16).background(Color("white")).cornerRadius(12)
                                        }
                                    }
                                }
                            } else {
                                VStack(spacing: 12) {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            ForEach(categories, id: \.self) { category in
                                                Button {
                                                    withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) { selectedCategory = category }
                                                } label: {
                                                    Text(lang.t("category.\(category)"))
                                                        .font(.system(size: 12, weight: selectedCategory == category ? .semibold : .regular))
                                                        .foregroundColor(selectedCategory == category ? Color("white") : Color("brown"))
                                                        .padding(.horizontal, 14).padding(.vertical, 6)
                                                        .background(selectedCategory == category ? Color("brown") : Color("white")).clipShape(Capsule())
                                                }
                                            }
                                        }
                                    }

                                    ForEach(categorizedDiscoverableStocks, id: \.symbol) { stock in
                                        Button { activeSheet = .buy(stock.symbol) } label: { InlineDiscoverableRow(stock: stock) }
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .background(Color("baige").opacity(0.6))
                        .cornerRadius(18)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets())
                        .padding(.horizontal, 24)
                        .padding(.bottom, 8)
                    }

                    if positions.isEmpty {
                        VStack {
                            Spacer()
                            Text(lang.t("portfolio.empty"))
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .center)
                            Spacer()
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    } else {
                        ForEach(positions) { position in
                            // Tapping a holding opens the sell detail sheet.
                            Button {
                                activeSheet = .sell(position)
                            } label: {
                                HoldingRow(position: position)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 6, leading: 24, bottom: 6, trailing: 24))
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    pendingRemoval = position
                                } label: {
                                    Label(lang.t("remove.swipe"), systemImage: "trash")
                                }
                            }
                        }
                    }

                    Color.clear
                        .frame(height: 190)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
                .listStyle(PlainListStyle())
                .background(Color.clear)
            }

            // Floating Add Action Button
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    isSearchDrawerExpanded.toggle()
                    if !isSearchDrawerExpanded { store.searchText = "" }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: isSearchDrawerExpanded ? "chevron.up" : "plus")
                    Text(isSearchDrawerExpanded ? lang.t("portfolio.closePanel") : lang.t("portfolio.addInline")).bold()
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(isSearchDrawerExpanded ? Color("brown") : Color("light brown"))
                .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 120)
        }
        .task(id: heldSymbolsKey) {
            await store.refreshLivePrices(for: positions.map { $0.symbol })
        }
        // Present via isPresented + a stored selection. Using .sheet(item:)
        // here failed to re-present when the selection changed (it kept the
        // first/last value), so we drive presentation explicitly.
        .sheet(isPresented: Binding(
            get: { activeSheet != nil },
            set: { if !$0 { activeSheet = nil } }
        )) {
            if let sheet = activeSheet {
                switch sheet {
                case .sell(let position):
                    HoldingDetailSheet(position: position)
                        .environment(store)
                case .buy(let symbol):
                    BuyDetailSheet(symbol: symbol)
                        .environment(store)
                        .onDisappear {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isSearchDrawerExpanded = false
                                store.searchText = ""
                            }
                        }
                }
            }
        }
        // Confirm before removing a holding (deletes all its transactions).
        .confirmationDialog(
            lang.t("remove.confirmTitle"),
            isPresented: Binding(
                get: { pendingRemoval != nil },
                set: { if !$0 { pendingRemoval = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(lang.t("remove.confirm"), role: .destructive) {
                if let p = pendingRemoval { removeHolding(p) }
                pendingRemoval = nil
            }
            Button(lang.t("remove.cancel"), role: .cancel) {
                pendingRemoval = nil
            }
        } message: {
            Text(lang.t("remove.confirmBody"))
        }
    }

    private var heldSymbolsKey: String {
        positions.map { $0.symbol }.sorted().joined(separator: ",")
    }

    // Deletes ALL transactions for a symbol, removing the whole position.
    // (Holdings are computed from the log, so we clear the log for that symbol.)
    private func removeHolding(_ position: PortfolioMath.Position) {
        let toDelete = transactions.filter { $0.symbol == position.symbol }
        for tx in toDelete {
            modelContext.delete(tx)
        }
        try? modelContext.save()
    }
}

// Routes the single sheet to either buy or sell. Identifiable so it can
// drive .sheet(item:); the id changes per stock/holding so the sheet
// always rebuilds with the correct data.
enum ActiveSheet: Identifiable {
    case buy(String)                       // symbol to buy
    case sell(PortfolioMath.Position)      // holding to sell

    var id: String {
        switch self {
        case .buy(let symbol):   return "buy-\(symbol)"
        case .sell(let pos):     return "sell-\(pos.symbol)"
        }
    }
}

struct InlineDiscoverableRow: View {
    let stock: DiscoverableStock
    var body: some View {
        HStack(spacing: 12) {
            Text(String(stock.name.prefix(3)).uppercased()).font(.system(size: 11, weight: .bold)).foregroundColor(Color("brown"))
                .frame(width: 36, height: 36).background(Color("dark baige")).clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(stock.name).font(.system(size: 14, weight: .semibold)).foregroundColor(Color("brown"))
                Text(stock.symbol).font(.system(size: 11)).foregroundColor(Color("brown").opacity(0.5))
            }
            Spacer()
            Image(systemName: "plus.circle.fill").font(.system(size: 18)).foregroundColor(Color("light brown"))
        }
        .padding(.vertical, 8).padding(.horizontal, 12).background(Color("white")).cornerRadius(10)
    }
}

// MARK: - Holding Row (one per currently-held position)
struct HoldingRow: View {
    let position: PortfolioMath.Position
    @Environment(AppStore.self) private var store
    @Environment(LanguageManager.self) private var lang

    var body: some View {
        let price = store.livePrice(for: position.symbol) ?? position.averageBuyPrice
        let currentValue = price * Double(position.quantity)
        let costBasis = position.costBasis
        let gain = currentValue - costBasis

        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(store.getReadableName(for: position.symbol))
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(Color("brown"))
                Text("\(position.quantity) \(position.quantity > 1 ? lang.t("portfolio.shares") : lang.t("portfolio.share"))")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(currentValue)) \(lang.t("unit.sar"))")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color("brown"))
                Text("\(Money.sar(gain)) \(lang.t("unit.sar"))")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(gain >= 0 ? Color("dark green") : Color("burgindy"))
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color("brown").opacity(0.3))
                .padding(.leading, 4)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(Color("white"))
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.01), radius: 6, x: 0, y: 3)
    }
}
