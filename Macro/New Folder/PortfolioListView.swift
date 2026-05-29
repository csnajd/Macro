//
//   PortfolioListView.swift
//   Macro
//
//   Created by Ghida Abdullah al-Mughamer on 28/05/2026.
//

import SwiftUI

public struct PortfolioListView: View {
    @Environment(AppStore.self) private var store
    @State private var showAddStockSheet = false

    public init() {}

    public var body: some View {
        ZStack(alignment: .bottom) {
            // FIXED: Standard color primitive used to clear compiler error
            Color("white").ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack(alignment: .center) {
                    Text("Portfolio")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color("brown"))
                    Spacer()
                    CoinBadge()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                // Metrics
                StatHeaderView(
                    totalInvested: store.totalInvested,
                    totalGain:     store.totalGain
                )

                // Live stock list
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        ForEach(store.portfolio) { stock in
                            LivePortfolioRow(stock: stock)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 10)
                    .padding(.bottom, 140)
                }
            }

            // Floating CTA
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
    }
}

// MARK: - Portfolio Row
struct LivePortfolioRow: View {
    let stock: Stock

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(stock.symbol.replacingOccurrences(of: ".SR", with: ""))
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Color("brown"))
                    Text(stock.category.rawValue)
                        .font(.system(size: 13))
                        .foregroundColor(Color("brown").opacity(0.4))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(stock.price)) SAR")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color("brown"))
                    Text(String(format: "%@%.1f%%", stock.changePercent >= 0 ? "+" : "", stock.changePercent))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(stock.changePercent >= 0 ? Color("dark green") : Color("burgindy"))
                }
            }

            // Progress bar — width driven by change magnitude capped at 100 %
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 100)
                        .fill(Color("brown").opacity(0.06))
                        .frame(height: 7)
                    RoundedRectangle(cornerRadius: 100)
                        .fill(barColor)
                        .frame(
                            width: geo.size.width * CGFloat(
                                min(max(abs(stock.changePercent) / 5.0, 0.15), 1.0)
                            ),
                            height: 7
                        )
                }
            }
            .frame(height: 7)

            Divider()
                .background(Color("brown").opacity(0.05))
                .padding(.top, 4)
        }
    }

    private var barColor: Color {
        switch stock.symbol {
        case let s where s.starts(with: "SABIC"): return Color("purple")
        case let s where s.starts(with: "STC"):   return Color("burgindy")
        case let s where s.starts(with: "RJHI"):  return Color("light brown")
        default:                                   return Color("dark green")
        }
    }
}
