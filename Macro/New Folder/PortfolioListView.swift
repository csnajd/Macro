//
//  PortfolioListView.swift
//  Macro
//

import SwiftUI
import SwiftData

public struct PortfolioListView: View {
    @Binding var showProfile: Bool

    @Environment(AppStore.self) private var store
    @Environment(LanguageManager.self) private var lang
    @Environment(\.modelContext) private var modelContext

    @State private var isSearchDrawerExpanded: Bool = false
    @State private var selectedCategory: String = "Popular"
    @State private var buySymbol: BuyTarget? = nil
    @State private var sellPosition: PortfolioMath.Position? = nil
    @State private var pendingRemoval: PortfolioMath.Position? = nil
    @State private var showSignInAlert = false

    @Query private var transactions: [Transaction]

    private let categories = ["Popular", "Banking", "Energy", "Real Estate", "Consumer", "Health"]

    private let discoverableStocks = [
        DiscoverableStock(symbol: "2222.SR", name: "Saudi Aramco",        category: "Popular"),
        DiscoverableStock(symbol: "2010.SR", name: "SABIC",               category: "Popular"),
        DiscoverableStock(symbol: "7010.SR", name: "STC",                 category: "Popular"),
        DiscoverableStock(symbol: "1120.SR", name: "Al Rajhi Bank",       category: "Popular"),
        DiscoverableStock(symbol: "2082.SR", name: "ACWA Power",          category: "Popular"),
        DiscoverableStock(symbol: "4003.SR", name: "Extra",               category: "Popular"),
        DiscoverableStock(symbol: "2280.SR", name: "Almarai",             category: "Popular"),
        DiscoverableStock(symbol: "1120.SR", name: "Al Rajhi Bank",       category: "Banking"),
        DiscoverableStock(symbol: "1180.SR", name: "SNB (AlAhli)",        category: "Banking"),
        DiscoverableStock(symbol: "1150.SR", name: "Alinma Bank",         category: "Banking"),
        DiscoverableStock(symbol: "1050.SR", name: "Saudi Fransi",        category: "Banking"),
        DiscoverableStock(symbol: "1060.SR", name: "SAIB",                category: "Banking"),
        DiscoverableStock(symbol: "1020.SR", name: "Bank AlBilad",        category: "Banking"),
        DiscoverableStock(symbol: "1030.SR", name: "Saudi Investment",    category: "Banking"),
        DiscoverableStock(symbol: "2222.SR", name: "Saudi Aramco",        category: "Energy"),
        DiscoverableStock(symbol: "5110.SR", name: "Saudi Electricity",   category: "Energy"),
        DiscoverableStock(symbol: "2082.SR", name: "ACWA Power",          category: "Energy"),
        DiscoverableStock(symbol: "4290.SR", name: "Aldrees",             category: "Energy"),
        DiscoverableStock(symbol: "2020.SR", name: "SAFCO / SABIC AN",    category: "Energy"),
        DiscoverableStock(symbol: "2310.SR", name: "Sipchem",             category: "Energy"),
        DiscoverableStock(symbol: "2060.SR", name: "Tasnee",              category: "Energy"),
        DiscoverableStock(symbol: "4300.SR", name: "Dar Al Arkan",        category: "Real Estate"),
        DiscoverableStock(symbol: "4090.SR", name: "Taiba Investments",   category: "Real Estate"),
        DiscoverableStock(symbol: "4150.SR", name: "Arriyadh Development",category: "Real Estate"),
        DiscoverableStock(symbol: "4250.SR", name: "Jabal Omar",          category: "Real Estate"),
        DiscoverableStock(symbol: "4190.SR", name: "Jarir Marketing",     category: "Real Estate"),
        DiscoverableStock(symbol: "2280.SR", name: "Almarai",             category: "Consumer"),
        DiscoverableStock(symbol: "4003.SR", name: "Extra",               category: "Consumer"),
        DiscoverableStock(symbol: "4005.SR", name: "Anan Care (Cenomi)",  category: "Consumer"),
        DiscoverableStock(symbol: "4200.SR", name: "Aldrees Transport",   category: "Consumer"),
        DiscoverableStock(symbol: "6001.SR", name: "Halwani Bros",        category: "Consumer"),
        DiscoverableStock(symbol: "4040.SR", name: "SAPTCO",              category: "Consumer"),
        DiscoverableStock(symbol: "4009.SR", name: "Saudi German Health", category: "Health"),
        DiscoverableStock(symbol: "4013.SR", name: "Dr. Sulaiman AlHabib",category: "Health"),
        DiscoverableStock(symbol: "2070.SR", name: "Dallah Healthcare",   category: "Health"),
        DiscoverableStock(symbol: "8010.SR", name: "Tawuniya Insurance",  category: "Health"),
        DiscoverableStock(symbol: "8020.SR", name: "Bupa Arabia",         category: "Health")
    ]

    private var categorizedDiscoverableStocks: [DiscoverableStock] {
        discoverableStocks.filter { $0.category == selectedCategory }
    }

    private var positions: [PortfolioMath.Position] {
        PortfolioMath.allPositions(from: transactions, userID: store.currentUserID)
    }

    private var totalCostBasis: Double {
        PortfolioMath.totalCostBasis(from: transactions, userID: store.currentUserID)
    }

    private var totalCurrentValue: Double {
        positions.reduce(0.0) { sum, pos in
            let price = store.livePrice(for: pos.symbol) ?? pos.averageBuyPrice
            return sum + price * Double(pos.quantity)
        }
    }

    public init(showProfile: Binding<Bool>) {
        self._showProfile = showProfile
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            Color(red: 247/255, green: 246/255, blue: 242/255).ignoresSafeArea()

            VStack(spacing: 0) {

                // MARK: - Header
                HStack(alignment: .center) {
                    Text(lang.t("portfolio.title"))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color("brown"))
                    Spacer()
                    HStack(spacing: 8) {
                        CoinBadge()
                        ProfileAvatarButton(action: { showProfile = true })
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 4)

                // MARK: - Stat header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(lang.t("stat.totalInvested"))
                            .font(.system(size: 12))
                            .foregroundColor(Color("brown").opacity(0.5))
                        Text("\(Int(totalCostBasis).formatted()) \(lang.t("unit.sar"))")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(Color("purple"))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(lang.t("stat.totalGain"))
                            .font(.system(size: 12))
                            .foregroundColor(Color("brown").opacity(0.5))
                        Text("\(Money.sar(totalCurrentValue - totalCostBasis)) \(lang.t("unit.sar"))")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor((totalCurrentValue - totalCostBasis) >= 0 ? Color("dark green") : Color("burgindy"))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 12)

                // MARK: - Holdings list
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
                                    .textInputAutocapitalization(.never)
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
                                    if store.searchResults.isEmpty {
                                        Text(store.searchText.trimmingCharacters(in: .whitespacesAndNewlines).count < 2
                                             ? lang.t("search.minChars")
                                             : lang.t("search.noMatches"))
                                            .font(.system(size: 13))
                                            .foregroundColor(Color("brown").opacity(0.5))
                                            .padding(.vertical, 12)
                                    }
                                    ForEach(Array(store.searchResults.enumerated()), id: \.offset) { _, item in
                                        Button { attemptBuy(item.symbol) } label: {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(store.getReadableName(for: item.symbol))
                                                        .bold().foregroundColor(Color("brown"))
                                                    Text(item.symbol)
                                                        .font(.system(size: 13))
                                                        .foregroundColor(Color("brown").opacity(0.6))
                                                }
                                                Spacer()
                                                Image(systemName: "plus.circle.fill")
                                                    .foregroundColor(Color("light brown"))
                                            }
                                            .padding(.vertical, 12).padding(.horizontal, 16)
                                            .background(Color("white")).cornerRadius(12)
                                        }
                                    }
                                }
                            } else {
                                VStack(spacing: 12) {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            ForEach(categories, id: \.self) { category in
                                                Button {
                                                    withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                                                        selectedCategory = category
                                                    }
                                                } label: {
                                                    Text(lang.t("category.\(category)"))
                                                        .font(.system(size: 12, weight: selectedCategory == category ? .semibold : .regular))
                                                        .foregroundColor(selectedCategory == category ? Color("white") : Color("brown"))
                                                        .padding(.horizontal, 14).padding(.vertical, 6)
                                                        .background(selectedCategory == category ? Color("brown") : Color("white"))
                                                        .clipShape(Capsule())
                                                }
                                            }
                                        }
                                    }
                                    ForEach(Array(categorizedDiscoverableStocks.enumerated()), id: \.offset) { _, stock in
                                        Button { attemptBuy(stock.symbol) } label: {
                                            InlineDiscoverableRow(stock: stock)
                                        }
                                        .buttonStyle(PlainButtonStyle())
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
                            Button { sellPosition = position } label: {
                                HoldingRow(position: position)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 5, leading: 24, bottom: 5, trailing: 24))
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
                        .frame(height: 160)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
                .listStyle(PlainListStyle())
                .background(Color.clear)
            }

            // MARK: - Add stock button (matches design: full width, prominent)
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    isSearchDrawerExpanded.toggle()
                    if !isSearchDrawerExpanded { store.searchText = "" }
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: isSearchDrawerExpanded ? "chevron.up" : "plus")
                        .font(.system(size: 16, weight: .semibold))
                    Text(isSearchDrawerExpanded
                         ? lang.t("portfolio.closePanel")
                         : lang.t("portfolio.addInline"))
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(isSearchDrawerExpanded ? Color("brown") : Color("light brown"))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color("light brown").opacity(0.3), radius: 12, x: 0, y: 4)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 100)
        }
        .task(id: heldSymbolsKey) {
            await store.refreshLivePrices(for: positions.map { $0.symbol })
        }
        .sheet(item: $buySymbol, onDismiss: {
            isSearchDrawerExpanded = false
            store.searchText = ""
        }) { target in
            BuyDetailSheet(symbol: target.symbol)
                .environment(store)
                .environment(lang)
        }
        .sheet(item: $sellPosition) { position in
            HoldingDetailSheet(position: position)
                .environment(store)
                .environment(lang)
        }
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
            Button(lang.t("remove.cancel"), role: .cancel) { pendingRemoval = nil }
        } message: {
            Text(lang.t("remove.confirmBody"))
        }
        .alert(lang.t("signin.requiredTitle"), isPresented: $showSignInAlert) {
            Button("Sign In") { showProfile = true }
            Button(lang.t("signin.notNow"), role: .cancel) {}
        } message: {
            Text(lang.t("signin.requiredBody"))
        }
    }

    private var heldSymbolsKey: String {
        positions.map { $0.symbol }.sorted().joined(separator: ",")
    }

    private func attemptBuy(_ symbol: String) {
        guard store.isSignedIn else { showSignInAlert = true; return }
        buySymbol = BuyTarget(symbol: symbol)
    }

    private func removeHolding(_ position: PortfolioMath.Position) {
        // Only delete the current user's rows for this symbol, so we never
        // touch another account's data that happens to share a symbol.
        let toDelete = transactions.filter {
            $0.symbol == position.symbol && $0.userID == store.currentUserID
        }
        for tx in toDelete { modelContext.delete(tx) }
        try? modelContext.save()
    }
}

// MARK: - Inline Discoverable Row
struct InlineDiscoverableRow: View {
    let stock: DiscoverableStock
    var body: some View {
        HStack(spacing: 12) {
            Text(String(stock.name.prefix(3)).uppercased())
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color("brown"))
                .frame(width: 38, height: 38)
                .background(Color("dark baige"))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(stock.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color("brown"))
                Text(stock.symbol)
                    .font(.system(size: 11))
                    .foregroundColor(Color("brown").opacity(0.5))
            }
            Spacer()
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(Color("light brown"))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(Color("white"))
        .cornerRadius(12)
    }
}

// MARK: - Holding Row (matches design: name+shares left, value+gain right, colored gain bar)
struct HoldingRow: View {
    let position: PortfolioMath.Position
    @Environment(AppStore.self) private var store
    @Environment(LanguageManager.self) private var lang

    var body: some View {
        let price = store.livePrice(for: position.symbol) ?? position.averageBuyPrice
        let currentValue = price * Double(position.quantity)
        let gain = currentValue - position.costBasis
        let gainPct = position.costBasis > 0 ? (gain / position.costBasis) * 100 : 0

        VStack(spacing: 0) {
            HStack(alignment: .center) {
                // Left: avatar + name/shares
                HStack(spacing: 12) {
                    Text(String(store.getReadableName(for: position.symbol).prefix(2)).uppercased())
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color("brown"))
                        .frame(width: 44, height: 44)
                        .background(Color("dark baige"))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 3) {
                        Text(store.getReadableName(for: position.symbol))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color("brown"))
                        Text(lang.shares(position.quantity))
                            .font(.system(size: 12))
                            .foregroundColor(Color("brown").opacity(0.45))
                    }
                }

                Spacer()

                // Right: value + gain%
                VStack(alignment: .trailing, spacing: 3) {
                    Text("\(Int(currentValue).formatted()) \(lang.t("unit.sar"))")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color("brown"))
                    Text(Money.percent(gainPct))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(gain >= 0 ? Color("dark green") : Color("burgindy"))
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color("brown").opacity(0.25))
                    .padding(.leading, 6)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            // Colored gain bar at bottom of card
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color("dark baige").opacity(0.3))
                        .frame(height: 3)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(gain >= 0 ? Color("dark green") : Color("burgindy"))
                        .frame(width: geo.size.width * CGFloat(min(abs(gainPct) / 20.0, 1.0)), height: 3)
                }
            }
            .frame(height: 3)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .background(Color("white"))
        .cornerRadius(16)
        .shadow(color: Color("brown").opacity(0.04), radius: 8, x: 0, y: 3)
    }
}
