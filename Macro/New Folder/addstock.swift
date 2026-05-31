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

// MARK: - Main Add Stock View
public struct AddStockView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext // SwiftData container context

    @State private var selectedCategory: String = "Popular"
    private let categories = ["Popular", "Banking", "Energy"]

    // Preset list of top Saudi Market (Tadawul) equities grouped by sector
    private let discoverableStocks = [
        // Popular / General Market
        DiscoverableStock(symbol: "2010.SR", name: "SABIC", category: "Popular"),
        DiscoverableStock(symbol: "2222.SR", name: "Saudi Aramco", category: "Popular"),
        DiscoverableStock(symbol: "7010.SR", name: "STC", category: "Popular"),
        DiscoverableStock(symbol: "4003.SR", name: "Extra", category: "Popular"),
        DiscoverableStock(symbol: "2280.SR", name: "Almarai", category: "Popular"),
        
        // Banking Sector
        DiscoverableStock(symbol: "1120.SR", name: "Al Rajhi Bank", category: "Banking"),
        DiscoverableStock(symbol: "1180.SR", name: "SNB (AlAhli)", category: "Banking"),
        DiscoverableStock(symbol: "1150.SR", name: "Alinma Bank", category: "Banking"),
        DiscoverableStock(symbol: "1050.SR", name: "Saudi Fransi", category: "Banking"),
        
        // Energy & Utilities Sector
        DiscoverableStock(symbol: "2222.SR", name: "Saudi Aramco", category: "Energy"),
        DiscoverableStock(symbol: "5110.SR", name: "Saudi Electricity", category: "Energy"),
        DiscoverableStock(symbol: "2082.SR", name: "ACWA Power", category: "Energy"),
        DiscoverableStock(symbol: "4290.SR", name: "Aldrees", category: "Energy")
    ]

    private var categorizedDiscoverableStocks: [DiscoverableStock] {
        return discoverableStocks.filter { $0.category == selectedCategory }
    }

    public init() {}

    public var body: some View {
        ZStack(alignment: .bottom) {
            Color("baige").ignoresSafeArea()

            VStack(spacing: 0) {
                // Header Row
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color("brown"))
                    }
                    Spacer()
                    Text("Add Stock")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color("brown"))
                    Spacer()
                    CoinBadge()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 16)

                // Search field bar
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
                .padding(.horizontal, 24)

                // DYNAMIC SEARCH RESULTS LAYER
                if !store.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 4) {
                            ForEach(store.searchResults) { item in
                                Button {
                                    Task {
                                        if let liveStock = await store.addStock(symbol: item.symbol) {
                                            saveDirectToDatabase(stock: liveStock)
                                            dismiss()
                                        }
                                    }
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.symbol)
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(Color("brown"))
                                            Text(item.longname ?? item.shortname ?? "Financial Asset")
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
                    // SECTOR PILLS GRID LAYER
                    VStack(spacing: 0) {
                        HStack(spacing: 10) {
                            ForEach(categories, id: \.self) { category in
                                Button {
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                        selectedCategory = category
                                    }
                                } label: {
                                    Text(category)
                                        .font(.system(size: 13, weight: selectedCategory == category ? .semibold : .regular))
                                        .foregroundColor(selectedCategory == category ? Color("white") : Color("brown"))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(selectedCategory == category ? Color("brown") : Color("white"))
                                        .clipShape(Capsule())
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)

                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 12) {
                                ForEach(categorizedDiscoverableStocks) { stock in
                                    Button {
                                        Task {
                                            if let liveStock = await store.addStock(symbol: stock.symbol) {
                                                saveDirectToDatabase(stock: liveStock)
                                                dismiss()
                                            }
                                        }
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
    }

    // MARK: - Direct Database Committer logic
    private func saveDirectToDatabase(stock: Stock) {
        let newTransaction = TransactionItem(stockSymbol: stock.symbol, price: stock.price, quantity: 1)
        modelContext.insert(newTransaction)
        try? modelContext.save()
        print("💾 SwiftData Success: Permanently committed \(stock.symbol)")
    }
}

// MARK: - Subview Row Render Component (FIXED: Added Back to Scope)
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
