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
    @Environment(\.modelContext) private var modelContext
    
    @State private var isSearchDrawerExpanded: Bool = false
    @State private var selectedCategory: String = "Popular"
    
    @Query private var savedTransactions: [TransactionItem]
    
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

    public init() {}

    public var body: some View {
        ZStack(alignment: .bottom) {
            Color("white").ignoresSafeArea()

            VStack(spacing: 0) {
                HStack(alignment: .center) {
                    Text("Portfolio")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color("brown"))
                    Spacer()
                    CoinBadge()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                StatHeaderView(
                    totalInvested: savedTransactions.reduce(0) { $0 + ($1.price > 0 ? $1.price : 32.0) * Double($1.quantity) },
                    totalGain:     store.portfolio.reduce(0) { $0 + $1.change }
                )

                List {
                    if isSearchDrawerExpanded {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(Color("brown").opacity(0.4))
                                TextField("Search global or Tadawul stocks...", text: Bindable(store).searchText)
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
                                    ForEach(store.searchResults) { item in
                                        Button {
                                            inlineAddAction(symbol: item.symbol)
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
                                                    Text(category)
                                                        .font(.system(size: 12, weight: selectedCategory == category ? .semibold : .regular))
                                                        .foregroundColor(selectedCategory == category ? Color("white") : Color("brown"))
                                                        .padding(.horizontal, 14).padding(.vertical, 6)
                                                        .background(selectedCategory == category ? Color("brown") : Color("white")).clipShape(Capsule())
                                                }
                                            }
                                        }
                                    }
                                    
                                    ForEach(categorizedDiscoverableStocks) { stock in
                                        Button { inlineAddAction(symbol: stock.symbol) } label: { InlineDiscoverableRow(stock: stock) }
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
                    
                    if savedTransactions.isEmpty {
                        VStack {
                            Spacer()
                            Text("Your portfolio is empty")
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .center)
                            Spacer()
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    } else {
                        ForEach(savedTransactions) { transaction in
                            LocalPortfolioRow(transaction: transaction)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 6, leading: 24, bottom: 6, trailing: 24))
                        }
                        .onDelete(perform: deleteStocks)
                    }
                    
                    // Transparent spacing card ensures scrolling entries never clip beneath the floating tab bar
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
                    Text(isSearchDrawerExpanded ? "Close Panel" : "Add Stock Inline").bold()
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
    }
    
    private func inlineAddAction(symbol: String) {
        Task {
            if let liveStock = await store.addStock(symbol: symbol) {
                let committedPrice = liveStock.price > 0 ? liveStock.price : defaultPriceForSymbol(symbol)
                
                if let existing = savedTransactions.first(where: { $0.stockSymbol == liveStock.symbol }) {
                    existing.quantity += 1
                } else {
                    let newTransaction = TransactionItem(
                        stockSymbol: liveStock.symbol,
                        price: committedPrice,
                        quantity: 1
                    )
                    modelContext.insert(newTransaction)
                }
                
                try? modelContext.save()
                
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isSearchDrawerExpanded = false
                    store.searchText = ""
                }
            }
        }
    }

    private func deleteStocks(at offsets: IndexSet) {
        for index in offsets {
            let itemToDelete = savedTransactions[index]
            modelContext.delete(itemToDelete)
        }
        try? modelContext.save()
    }

    private func defaultPriceForSymbol(_ symbol: String) -> Double {
        if symbol.starts(with: "2222") { return 32.0 }
        if symbol.starts(with: "2010") { return 78.0 }
        if symbol.starts(with: "1120") { return 82.0 }
        if symbol.starts(with: "7010") { return 39.0 }
        if symbol.starts(with: "2082") { return 360.0 }
        if symbol.starts(with: "4013") { return 290.0 }
        return 45.0
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

// MARK: - Local Portfolio Card Row (With Direct 0 SAR Glitch Safe-Guards)
struct LocalPortfolioRow: View {
    let transaction: TransactionItem
    @Environment(AppStore.self) private var store

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(store.getReadableName(for: transaction.stockSymbol))
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(Color("brown"))
                Text("\(transaction.quantity) \(transaction.quantity > 1 ? "Shares" : "Share")")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
            Spacer()
            
            let livePrice = store.portfolio.first(where: { $0.symbol == transaction.stockSymbol })?.price ?? 0.0
            let displayPrice = livePrice > 0 ? livePrice : fallbackPriceForSymbol(transaction.stockSymbol)
            
            Text("\(Int(displayPrice * Double(transaction.quantity))) SAR")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color("brown"))
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(Color("white"))
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.01), radius: 6, x: 0, y: 3)
    }

    private func fallbackPriceForSymbol(_ symbol: String) -> Double {
        if symbol.starts(with: "2222") { return 32.0 }
        if symbol.starts(with: "2010") { return 78.0 }
        if symbol.starts(with: "1120") { return 82.0 }
        if symbol.starts(with: "7010") { return 39.0 }
        if symbol.starts(with: "2082") { return 360.0 }
        if symbol.starts(with: "4003") { return 75.0 }
        if symbol.starts(with: "2280") { return 58.0 }
        return 45.0
    }
}
