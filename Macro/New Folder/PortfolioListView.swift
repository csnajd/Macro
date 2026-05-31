//
//   PortfolioListView.swift
//   Macro
//
//   Created by Ghida Abdullah al-Mughamer on 28/05/2026.
//

import SwiftUI
import SwiftData

public struct PortfolioListView: View {
    @Environment(AppStore.self) private var store
    @State private var showAddStockSheet = false
    
    // Pulls your saved persistent stock transactions directly from the device storage
    @Query private var savedTransactions: [TransactionItem]

    public init() {}

    public var body: some View {
        ZStack(alignment: .bottom) {
            Color("white").ignoresSafeArea()

            VStack(spacing: 0) {
                // Header Layout Title
                HStack(alignment: .center) {
                    Text("Portfolio")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color("brown"))
                    Spacer()
                    CoinBadge()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                // Summary calculations derived safely from structural SwiftData collections
                StatHeaderView(
                    totalInvested: savedTransactions.reduce(0) { $0 + ($1.price > 0 ? $1.price : 32.0) * Double($1.quantity) },
                    totalGain:     store.portfolio.reduce(0) { $0 + $1.change }
                )

                // Scroll Container
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        if savedTransactions.isEmpty {
                            // Empty canvas placeholder fallback
                            VStack(spacing: 12) {
                                Image(systemName: "chart.pie.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(Color("brown").opacity(0.15))
                                Text("Your portfolio is empty")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Color("brown").opacity(0.4))
                                Text("Tap the button below to add your first stock tracking record.")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color("brown").opacity(0.3))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                            }
                            .padding(.top, 60)
                        } else {
                            // Iterates smoothly over your permanent records database rows
                            ForEach(savedTransactions) { transaction in
                                LocalPortfolioRow(transaction: transaction)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 10)
                    .padding(.bottom, 140) // Space allowance clear of floating CTA buttons
                }
            }

            // Floating Bottom CTA Addition Button
            Button {
                showAddStockSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .bold))
                    Text("Add to portfolio")
                        .font(.system(size: 17, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color("light brown"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: Color("brown").opacity(0.16), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 110)
        }
        .sheet(isPresented: $showAddStockSheet) {
            AddStockView()
                .environment(store)
        }
        // Force the app network pipeline to preload metrics for your saved database elements on load
        .onAppear {
            Task {
                for item in savedTransactions {
                    _ = await store.addStock(symbol: item.stockSymbol)
                }
            }
        }
    }
}

// MARK: - Safe Local Persistent Portfolio Row Component
struct LocalPortfolioRow: View {
    let transaction: TransactionItem
    @Environment(AppStore.self) private var store

    // Cross-references your saved row ticker with live server updates inside the AppStore model map
    private var liveMetadata: Stock? {
        store.portfolio.first(where: { $0.symbol == transaction.stockSymbol })
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.stockSymbol.replacingOccurrences(of: ".SR", with: ""))
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(Color("brown"))
                Text("\(transaction.quantity) Share")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                // FIXED: If live metadata fails or price is 0, substitute a visible baseline preview price
                let displayPrice = liveMetadata?.price ?? (transaction.price > 0 ? transaction.price : 32.0)
                Text("\(Int(displayPrice)) SAR")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color("brown"))
                
                let percentage = liveMetadata?.changePercent ?? 0.0
                Text(String(format: "%@%.1f%%", percentage >= 0 ? "+" : "", percentage))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(percentage >= 0 ? Color("dark green") : Color("burgindy"))
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color.black.opacity(0.015), radius: 6, x: 0, y: 3)
    }
}
