//
//  AnalyticsView.swift
//  Macro
//

import SwiftUI
import SwiftData

struct AnalyticsView: View {
    @Binding var showProfile: Bool

    @Environment(AppStore.self) private var store
    @Environment(LanguageManager.self) private var lang
    @Query private var transactions: [Transaction]

    @State private var showHouseProgressionSheet = false

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

    private var unrealizedGain: Double {
        totalCurrentValue - totalCostBasis
    }

    private var gainPercentage: Double {
        totalCostBasis > 0 ? (unrealizedGain / totalCostBasis) * 100 : 0.0
    }

    private var totalBricks: Int {
        store.totalDynamicBricks(unrealizedGain: unrealizedGain)
    }

    private var isEstateComplete: Bool {
        HouseStages.nextStage(forBricks: totalBricks) == nil
    }

    private var upgradeProgress: Double {
        HouseStages.progress(forBricks: totalBricks)
    }

    private var upgradeProgressLabel: String {
        let remaining = HouseStages.bricksToNext(forBricks: totalBricks)
        if remaining <= 0 { return lang.t("upgrade.builtFull") }
        return String(format: lang.t("upgrade.bricksToNext"), lang.bricks(remaining))
    }

    private var currentStageNumber: Int {
        HouseStages.currentStage(forBricks: totalBricks).stageNumber
    }

    var body: some View {
        ZStack {
            Color(red: 247/255, green: 246/255, blue: 242/255).ignoresSafeArea()

            VStack(spacing: 0) {

                // MARK: - Header
                HStack {
                    Button { lang.toggle() } label: {
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
                    HStack(spacing: 8) {
                        CoinBadge()
                        ProfileAvatarButton(action: { showProfile = true })
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                // MARK: - Stats row
                HStack(alignment: .top) {
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
                        Text("\(Money.sar(unrealizedGain)) \(lang.t("unit.sar"))")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(unrealizedGain >= 0 ? Color("dark green") : Color("burgindy"))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 8)

                Spacer()

                // MARK: - Donut wheel
                ZStack {
                    Circle()
                        .stroke(Color("white"), lineWidth: 28)
                        .frame(width: 220, height: 220)

                    ZStack {
                        if positions.isEmpty {
                            Circle()
                                .trim(from: 0, to: 1)
                                .stroke(Color("dark baige").opacity(0.3),
                                        style: StrokeStyle(lineWidth: 28, lineCap: .round))
                        } else {
                            let slices = computeDynamicSlices()
                            ForEach(0..<slices.count, id: \.self) { i in
                                Circle()
                                    .trim(from: slices[i].startPercent,
                                          to: max(slices[i].startPercent, slices[i].endPercent - 0.03))
                                    .stroke(colorForIndex(i),
                                            style: StrokeStyle(lineWidth: 28, lineCap: .round))
                            }
                        }
                    }
                    .frame(width: 220, height: 220)
                    .rotationEffect(.degrees(-90))

                    VStack(spacing: 2) {
                        Text("\(Int(totalCurrentValue).formatted())")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(Color("brown"))
                        Text(lang.t("unit.sar"))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color("brown").opacity(0.6))
                        Text(lang.t("label.portfolio"))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color("brown").opacity(0.4))
                            .tracking(1)
                            .padding(.top, 2)
                        HStack(spacing: 2) {
                            Text(Money.percent(gainPercentage))
                            Image(systemName: gainPercentage >= 0 ? "arrow.up.right" : "arrow.down.right")
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(gainPercentage >= 0 ? Color("dark green") : Color("burgindy"))
                        .padding(.top, 2)
                    }
                }
                .frame(width: 260, height: 260)
                .shadow(color: Color("brown").opacity(0.04), radius: 16, x: 0, y: 8)

                Spacer()

                // MARK: - Upgrade panel (matches design: house thumbnail left, progress right)
                Button {
                    showHouseProgressionSheet = true
                } label: {
                    HStack(spacing: 14) {
                        // House level image thumbnail
                        Image("level\(currentStageNumber)")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 64, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: 14))

                        VStack(alignment: .leading, spacing: 6) {
                            Text(isEstateComplete ? lang.t("upgrade.complete") : lang.t("upgrade.nextIn"))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color("brown"))

                            Text(upgradeProgressLabel)
                                .font(.system(size: 12))
                                .foregroundColor(Color("brown").opacity(0.55))

                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 100)
                                        .fill(Color("dark baige").opacity(0.25))
                                        .frame(height: 6)
                                    RoundedRectangle(cornerRadius: 100)
                                        .fill(Color("light brown"))
                                        .frame(width: geo.size.width * CGFloat(upgradeProgress), height: 6)
                                }
                            }
                            .frame(height: 6)
                        }

                        Spacer()

                        // Progress percentage + chevron
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(Int(upgradeProgress * 100))%")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color("light brown"))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color("brown").opacity(0.3))
                        }
                    }
                    .padding(14)
                    .background(Color("white"))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: Color("brown").opacity(0.05), radius: 12, x: 0, y: 4)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 100)
            }
        }
        .task(id: heldSymbolsKey) {
            await store.refreshLivePrices(for: positions.map { $0.symbol })
        }
        .sheet(isPresented: $showHouseProgressionSheet) {
            HouseProgressionView()
                .environment(store)
        }
    }

    private var heldSymbolsKey: String {
        positions.map { $0.symbol }.sorted().joined(separator: ",")
    }

    private struct WheelSlice {
        let startPercent: Double
        let endPercent: Double
    }

    private func computeDynamicSlices() -> [WheelSlice] {
        guard totalCurrentValue > 0 else { return [] }
        var list: [WheelSlice] = []
        var acc = 0.0
        for pos in positions {
            let price = store.livePrice(for: pos.symbol) ?? pos.averageBuyPrice
            let value = price * Double(pos.quantity)
            let fraction = value / totalCurrentValue
            list.append(WheelSlice(startPercent: acc, endPercent: acc + fraction))
            acc += fraction
        }
        return list
    }

    private func colorForIndex(_ index: Int) -> Color {
        let colors = ["green", "light green", "dark green", "light brown", "burgindy", "purple", "light purple"]
        return Color(colors[index % colors.count])
    }
}
