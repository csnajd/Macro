//
//  AnalyticsView.swift
//  Macro
//
//  Created by Ghida Abdullah al-Mughamer on 31/05/2026.
//

import SwiftUI
import SwiftData

struct AnalyticsView: View {
    @Environment(AppStore.self) private var store
    @Environment(LanguageManager.self) private var lang
    @Query private var transactions: [Transaction]

    @State private var showHouseProgressionSheet = false

    // MARK: - Derived portfolio numbers (single source of truth)

    // Current holdings derived from the transaction event log.
    private var positions: [PortfolioMath.Position] {
        PortfolioMath.allPositions(from: transactions)
    }

    // What the user paid for shares still held.
    private var totalCostBasis: Double {
        PortfolioMath.totalCostBasis(from: transactions)
    }

    // Current market value of held shares, using live prices where available,
    // falling back to cost basis per-holding while a price is still loading
    // (so the user never sees a scary 0 SAR).
    private var totalCurrentValue: Double {
        positions.reduce(0.0) { sum, pos in
            let price = store.livePrice(for: pos.symbol) ?? pos.averageBuyPrice
            return sum + price * Double(pos.quantity)
        }
    }

    // Unrealized gain = current value − cost basis.
    private var unrealizedGain: Double {
        totalCurrentValue - totalCostBasis
    }

    private var gainPercentage: Double {
        totalCostBasis > 0 ? (unrealizedGain / totalCostBasis) * 100 : 0.0
    }

    // MARK: - House upgrade progress (driven by lifetime bricks)

    private var isEstateComplete: Bool {
        HouseStages.nextStage(forBricks: store.brickCount) == nil
    }

    private var upgradeProgress: Double {
        HouseStages.progress(forBricks: store.brickCount)
    }

    private var upgradeProgressLabel: String {
        let remaining = HouseStages.bricksToNext(forBricks: store.brickCount)
        if remaining <= 0 {
            return lang.t("upgrade.builtFull")
        }
        // lang.bricks() returns the grammatically correct phrase for any count
        // (Arabic noun forms change at 1 / 2 / 3–10 / 11+).
        return String(format: lang.t("upgrade.bricksToNext"), lang.bricks(remaining))
    }

    var body: some View {
        ZStack {
            Color(red: 247/255, green: 246/255, blue: 242/255)
                .ignoresSafeArea()

            VStack(spacing: 0) {

                // MARK: - Utility Header
                HStack {
                    // Tapping the profile icon instantly toggles the app
                    // language (Arabic ⇄ English). The small "ع/En" hint shows
                    // which language tapping will switch TO.
                    Button {
                        lang.toggle()
                    } label: {
                        HStack(spacing: 3) {
                            Text("ع")
                                .font(.system(size: 17, weight: lang.current == .arabic ? .bold : .regular))
                                .foregroundColor(Color("brown").opacity(lang.current == .arabic ? 1.0 : 0.4))
                            Text("A")
                                .font(.system(size: 15, weight: lang.current == .english ? .bold : .regular))
                                .foregroundColor(Color("brown").opacity(lang.current == .english ? 1.0 : 0.4))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color("light brown").opacity(0.15))
                        .clipShape(Capsule())
                    }
                    Spacer()
                    CoinBadge()
                }
                .padding(.horizontal, 28)
                .padding(.top, 12)

                // MARK: - Main Stat Cards
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(lang.t("stat.totalInvested"))
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color("brown").opacity(0.6))
                        Text("\(Int(totalCostBasis).formatted()) \(lang.t("unit.sar"))")
                            .font(.system(size: 21, weight: .bold))
                            .foregroundColor(Color("purple"))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 6) {
                        Text(lang.t("stat.totalGain"))
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color("brown").opacity(0.6))
                        Text("\(Money.sar(unrealizedGain)) \(lang.t("unit.sar"))")
                            .font(.system(size: 21, weight: .bold))
                            .foregroundColor(unrealizedGain >= 0 ? Color("dark green") : Color("burgindy"))
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 24)

                Spacer()

                // MARK: - Central Wheel
                ZStack {
                    Circle()
                        .stroke(Color("white"), lineWidth: 26)
                        .frame(width: 215, height: 215)

                    ZStack {
                        if positions.isEmpty {
                            Circle()
                                .trim(from: 0.0, to: 1.0)
                                .stroke(Color("dark baige").opacity(0.3),
                                        style: StrokeStyle(lineWidth: 26, lineCap: .round))
                        } else {
                            let slices = computeDynamicSlices()
                            ForEach(0..<slices.count, id: \.self) { index in
                                let slice = slices[index]
                                Circle()
                                    .trim(from: slice.startPercent, to: max(slice.startPercent, slice.endPercent - 0.04))
                                    .stroke(colorForIndex(index),
                                            style: StrokeStyle(lineWidth: 26, lineCap: .round))
                            }
                        }
                    }
                    .frame(width: 215, height: 215)
                    .rotationEffect(.degrees(-90))

                    VStack(spacing: 1) {
                        Text("\(Int(totalCurrentValue).formatted())")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(Color("brown"))
                        Text(lang.t("unit.sar"))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color("brown").opacity(0.7))
                        Text(lang.t("label.portfolio"))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color("brown").opacity(0.5))
                            .tracking(0.8)
                            .padding(.top, 1)

                        HStack(spacing: 2) {
                            Text(Money.percent(gainPercentage))
                            Image(systemName: gainPercentage >= 0 ? "arrow.up.right" : "arrow.down.right")
                        }
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(gainPercentage >= 0 ? Color("dark green") : Color("burgindy"))
                        .padding(.top, 3)
                    }
                }
                .frame(width: 250, height: 250)

                Spacer()

                // MARK: - Interactive Upgrade Action Panel
                // Real progress toward the next house stage, driven by bricks.
                Button {
                    showHouseProgressionSheet = true
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            Color("dark baige").opacity(0.3)
                            Image("brick")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                        }
                        .frame(width: 54, height: 54)
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                        VStack(alignment: .leading, spacing: 5) {
                            Text(isEstateComplete ? lang.t("upgrade.complete") : lang.t("upgrade.nextIn"))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color("brown"))

                            Text(upgradeProgressLabel)
                                .font(.system(size: 12))
                                .foregroundColor(Color("brown").opacity(0.6))

                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 100)
                                        .fill(Color("dark baige").opacity(0.2))
                                    RoundedRectangle(cornerRadius: 100)
                                        .fill(Color("light brown"))
                                        .frame(width: geo.size.width * CGFloat(upgradeProgress))
                                }
                            }
                            .frame(height: 6)
                            .padding(.top, 2)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color("brown").opacity(0.4))
                            .padding(.trailing, 4)
                    }
                    .padding(14)
                    .background(Color("white"))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(color: Color("brown").opacity(0.04), radius: 10, x: 0, y: 4)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 102)
            }
        }
        // Fetch live prices for everything held when this screen appears.
        .task(id: heldSymbolsKey) {
            await store.refreshLivePrices(for: positions.map { $0.symbol })
        }
        .sheet(isPresented: $showHouseProgressionSheet) {
            HouseProgressionView()
                .environment(store)
        }
    }

    // Stable key so .task re-runs when the set of held symbols changes.
    private var heldSymbolsKey: String {
        positions.map { $0.symbol }.sorted().joined(separator: ",")
    }

    private struct WheelSlice {
        let startPercent: Double
        let endPercent: Double
    }

    // Wheel slices are sized by each holding's share of current market value.
    private func computeDynamicSlices() -> [WheelSlice] {
        guard totalCurrentValue > 0 else { return [] }
        var list: [WheelSlice] = []
        var acc = 0.0
        for pos in positions {
            let price = store.livePrice(for: pos.symbol) ?? pos.averageBuyPrice
            let value = price * Double(pos.quantity)
            let fraction = value / totalCurrentValue
            let start = acc
            let end = acc + fraction
            list.append(WheelSlice(startPercent: start, endPercent: end))
            acc = end
        }
        return list
    }

    private func colorForIndex(_ index: Int) -> Color {
        let strictColors = ["green", "light green", "dark green", "light brown", "burgindy", "purple", "light purple"]
        return Color(strictColors[index % strictColors.count])
    }
}
