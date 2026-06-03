//
//  SummaryView.swift
//  Macro
//

import SwiftUI
import SwiftData

private enum SummaryExpansion {
    case collapsed
    case expanded
    case full
}

// Helper: format a date per the current app language.
private func localizedDate(_ date: Date, format: String, lang: LanguageManager) -> String {
    let f = DateFormatter()
    f.locale = lang.current.locale
    f.dateFormat = format
    return f.string(from: date)
}

struct SummaryView: View {
    @Environment(AppStore.self) private var store
    @Environment(LanguageManager.self) private var lang
    @Environment(\.modelContext) private var modelContext
    @Query private var transactions: [Transaction]
    @Query private var snapshots: [PortfolioSnapshot]
    @State private var aiService = AISummaryService()
    @State private var expansion: SummaryExpansion = .collapsed

    private var positions: [PortfolioMath.Position] {
        PortfolioMath.allPositions(from: transactions)
    }

    private var livePriceMap: [String: Double] {
        var map: [String: Double] = [:]
        for pos in positions {
            if let p = store.livePrice(for: pos.symbol) { map[pos.symbol] = p }
        }
        return map
    }

    private var currentValue: Double {
        positions.reduce(0.0) { sum, pos in
            let price = store.livePrice(for: pos.symbol) ?? pos.averageBuyPrice
            return sum + price * Double(pos.quantity)
        }
    }

    // Record at most one snapshot per day; the first becomes the baseline.
    private func recordSnapshotIfNeeded() {
        guard !positions.isEmpty else { return }
        guard !SnapshotMath.hasSnapshotToday(snapshots) else { return }
        let snap = PortfolioSnapshot(totalValue: currentValue, brickCount: store.brickCount)
        modelContext.insert(snap)
        try? modelContext.save()
    }

    private func regenerate() async {
        await store.refreshLivePrices(for: positions.map { $0.symbol })
        recordSnapshotIfNeeded()
        let baseline = SnapshotMath.baseline(snapshots)
        await aiService.generateSummary(
            positions: positions,
            livePrices: livePriceMap,
            realizedThisPeriod: PortfolioMath.totalRealizedGain(from: transactions),
            bricksEarned: store.brickCount,
            baselineValue: baseline?.totalValue,
            baselineBricks: baseline?.brickCount ?? 0,
            startDate: baseline?.date
        )
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {

                HStack {
                    Text(lang.t("summary.title"))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color("brown"))
                    Spacer()
                    CoinBadge()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                HStack {
                    Text(lang.t("summary.settings"))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color("brown"))
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 12)

                if aiService.isLoading {
                    LoadingCardView()
                        .padding(.horizontal, 24)
                } else if let s = aiService.summary {
                    Group {
                        switch expansion {
                        case .collapsed:
                            CollapsedCard(summary: s, expansion: $expansion)
                        case .expanded:
                            ExpandedCard(summary: s, expansion: $expansion)
                        case .full:
                            FullReport(summary: s, portfolio: store.portfolio, expansion: $expansion)
                        }
                    }
                    .padding(.horizontal, 24)
                } else {
                    EmptyCard()
                        .padding(.horizontal, 24)
                }

                Spacer(minLength: 120)
            }
        }
        .background(Color("white").ignoresSafeArea())
        .task(id: positions.map { $0.symbol }.sorted().joined(separator: ",")) {
            await regenerate()
        }
    }
}

// MARK: - Collapsed
private struct CollapsedCard: View {
    let summary: WeeklySummary
    @Binding var expansion: SummaryExpansion
    @Environment(AppStore.self) private var store
    @Environment(LanguageManager.self) private var lang

    private var weekLabel: String {
        String(format: lang.t("summary.weekPrefix"),
                localizedDate(summary.weekDate, format: "d MMMM", lang: lang))
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {

            Button {
                withAnimation(.spring(response: 0.3)) { expansion = .expanded }
            } label: {
                HStack {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color("brown").opacity(0.4))
                    Spacer()
                    Text(weekLabel)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color("brown").opacity(0.6))
                }
            }
            .padding(.bottom, 8)

            Text("\(Money.sar(summary.totalChange)) \(lang.t("unit.sar"))")
                .font(.system(size: 34, weight: .bold, design: .serif))
                .foregroundColor(summary.totalChange >= 0 ? Color("dark green") : Color("burgindy"))
                .frame(maxWidth: .infinity, alignment: .trailing)

            SparklineView()
                .frame(height: 48)
                .padding(.vertical, 8)

            Text(lang.t(summary.weekClassificationKey))
                .font(.system(size: 13))
                .foregroundColor(Color("brown").opacity(0.6))
                .multilineTextAlignment(.trailing)
                .lineLimit(2)

            Divider().padding(.vertical, 12)

            MoversList(portfolio: Array(store.portfolio.prefix(3)))

            NextFooter(date: summary.nextSummaryDate)
        }
        .padding(16)
        .background(Color("baige"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Expanded
private struct ExpandedCard: View {
    let summary: WeeklySummary
    @Binding var expansion: SummaryExpansion
    @Environment(AppStore.self) private var store
    @Environment(LanguageManager.self) private var lang

    private var weekLabel: String {
        String(format: lang.t("summary.weekPrefix"),
                localizedDate(summary.weekDate, format: "d MMMM", lang: lang))
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {

            Button {
                withAnimation(.spring(response: 0.3)) { expansion = .collapsed }
            } label: {
                HStack {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color("brown").opacity(0.4))
                    Spacer()
                    Text(weekLabel)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color("brown").opacity(0.6))
                }
            }
            .padding(.bottom, 8)

            Text("\(Money.sar(summary.totalChange)) \(lang.t("unit.sar"))")
                .font(.system(size: 34, weight: .bold, design: .serif))
                .foregroundColor(summary.totalChange >= 0 ? Color("dark green") : Color("burgindy"))
                .frame(maxWidth: .infinity, alignment: .trailing)

            VStack(alignment: .trailing, spacing: 10) {
                Text(lang.t("summary.howCalculated"))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color("brown"))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.bottom, 2)

                // Plain-English (or Arabic) explanation of the number.
                Text(lang.t("summary.explainBody"))
                    .font(.system(size: 12))
                    .foregroundColor(Color("brown").opacity(0.65))
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.bottom, 4)

                CalcRow(label: lang.t("summary.initialValue"),
                        value: String(format: "%.0f %@", summary.portfolioValue, lang.t("unit.sar")))
                CalcRow(label: lang.t("summary.positionGains"),
                        value: String(format: "+%.0f %@", summary.portfolioGains, lang.t("unit.sar")),
                        color: Color("dark green"))
                CalcRow(label: lang.t("summary.positionLosses"),
                        value: String(format: "%.0f %@", summary.portfolioLosses, lang.t("unit.sar")),
                        color: Color("burgindy"))
                Divider()
                CalcRow(label: lang.t("summary.netChange"),
                        value: "\(Money.sar(summary.netChange)) \(lang.t("unit.sar"))",
                        color: summary.netChange >= 0 ? Color("dark green") : Color("burgindy"),
                        bold: true)
            }
            .padding(14)
            .background(Color("white").opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.top, 12)

            Button {
                withAnimation(.spring(response: 0.3)) { expansion = .full }
            } label: {
                HStack {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12))
                    Text(lang.t("summary.viewFullReport"))
                        .font(.system(size: 13))
                        .multilineTextAlignment(.trailing)
                        .lineLimit(2)
                    Spacer()
                }
                .foregroundColor(Color("brown").opacity(0.7))
                .padding(.top, 12)
            }

            Divider().padding(.vertical, 12)

            MoversList(portfolio: Array(store.portfolio.prefix(3)))

            NextFooter(date: summary.nextSummaryDate)
        }
        .padding(16)
        .background(Color("baige"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Full Report
private struct FullReport: View {
    let summary: WeeklySummary
    let portfolio: [Stock]
    @Binding var expansion: SummaryExpansion
    @Environment(LanguageManager.self) private var lang

    private var weekLabel: String {
        String(format: lang.t("summary.weekPrefix"),
                localizedDate(summary.weekDate, format: "d MMMM", lang: lang))
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {

            Button {
                withAnimation(.spring(response: 0.3)) { expansion = .expanded }
            } label: {
                HStack {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color("brown").opacity(0.4))
                    Spacer()
                    Text(weekLabel)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color("brown").opacity(0.6))
                }
            }

            // Detailed summary sentence: % since started, positions positive,
            // best mover's contribution. All real, from holdings + baseline.
            Text(String(format: lang.t(summary.sinceStartChange >= 0 ? "summary.sentencePositive" : "summary.sentenceNegative"),
                        abs(summary.sinceStartPercent),
                        summary.positionsPositive,
                        summary.positionsTotal,
                        summary.bestStockName,
                        Money.sar(summary.bestContribution),
                        lang.t("unit.sar")))
                .font(.system(size: 13))
                .foregroundColor(Color("brown").opacity(0.75))
                .multilineTextAlignment(.trailing)
                .padding(.top, 8)

            // محفظتك مقابل السوق — TASI حقيقي
            STitle(lang.t("summary.vsMarket"))
            VStack(spacing: 8) {
                HStack {
                    Text(Money.percent(summary.weeklyChangePercent))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(summary.weeklyChangePercent >= 0 ? Color("dark green") : Color("burgindy"))
                    Spacer()
                    Text(lang.t("summary.yourPortfolio"))
                        .font(.system(size: 13))
                        .foregroundColor(Color("brown").opacity(0.6))
                }
                HStack {
                    Text(Money.percent(summary.tasiChange))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color("brown"))
                    Spacer()
                    Text(lang.t("summary.tasiIndex"))
                        .font(.system(size: 13))
                        .foregroundColor(Color("brown").opacity(0.6))
                }
                HStack {
                    Spacer()
                    Text(summary.marketOutperform >= 0
                         ? String(format: lang.t("summary.outperformed"), "+", summary.marketOutperform)
                         : String(format: lang.t("summary.underperformed"), abs(summary.marketOutperform)))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(summary.marketOutperform >= 0 ? Color("dark green") : Color("burgindy"))
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background((summary.marketOutperform >= 0 ? Color("dark green") : Color("burgindy")).opacity(0.12))
                        .clipShape(Capsule())
                }
            }
            .padding(12)
            .background(Color("white").opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // قطاعات من المحفظة الحقيقية
            if !summary.sectorPerformance.isEmpty {
                STitle(lang.t("summary.sectorPerf"))
                VStack(spacing: 8) {
                    ForEach(summary.sectorPerformance) { sector in
                        HStack(spacing: 10) {
                            Text(Money.percent(sector.changePercent))
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(sector.isPositive ? Color("dark green") : Color("burgindy"))
                                .frame(width: 52, alignment: .leading)
                            GeometryReader { geo in
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(sector.isPositive ? Color("dark green").opacity(0.7) : Color("burgindy").opacity(0.7))
                                    .frame(width: geo.size.width * CGFloat(min(abs(sector.changePercent) / 5.0, 1.0)), height: 10)
                            }
                            .frame(height: 10)
                            Text(lang.t("category.\(sector.name)"))
                                .font(.system(size: 13))
                                .foregroundColor(Color("brown").opacity(0.7))
                                .frame(width: 90, alignment: .trailing)
                        }
                    }
                }
                .padding(12)
                .background(Color("white").opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // نظرة للأمام
            STitle(lang.t("summary.forwardLook"))
            Text(String(format: lang.t(summary.forwardLookKey), abs(summary.marketOutperform)))
                .font(.system(size: 13))
                .foregroundColor(Color("brown").opacity(0.75))
                .multilineTextAlignment(.trailing)
                .padding(.vertical, 6)

            Divider().padding(.vertical, 12)

            STitle(lang.t("summary.topMovers"))
            MoversList(portfolio: portfolio)

            HStack {
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(summary.bricksThisPeriod)")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(Color("light purple"))
                    Text(lang.t("summary.bricksSince"))
                        .font(.system(size: 11))
                        .foregroundColor(Color("brown").opacity(0.5))
                    Text(lang.t("summary.fromRealized"))
                        .font(.system(size: 11))
                        .foregroundColor(Color("brown").opacity(0.5))
                }
            }
            .padding(.top, 12)

            NextFooter(date: summary.nextSummaryDate)
        }
        .padding(16)
        .background(Color("baige"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Reusable Components

private struct MoversList: View {
    let portfolio: [Stock]
    @Environment(LanguageManager.self) private var lang
    @Environment(AppStore.self) private var store
    var body: some View {
        VStack(spacing: 0) {
            ForEach(portfolio) { stock in
                HStack(spacing: 14) {
                    StockAvatarView(symbol: stock.symbol)
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(store.getReadableName(for: stock.symbol))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color("brown"))
                        Text(stock.symbol.replacingOccurrences(of: ".SR", with: ""))
                            .font(.system(size: 12))
                            .foregroundColor(Color("brown").opacity(0.45))
                    }
                    Spacer()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(Int(stock.price)) \(lang.t("unit.sar"))")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color("brown"))
                        Text(Money.percent(stock.changePercent))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(stock.changePercent >= 0 ? Color("dark green") : Color("burgindy"))
                    }
                }
                .padding(.vertical, 10)
            }
        }
    }
}

private struct STitle: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(Color("brown"))
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.top, 16).padding(.bottom, 6)
    }
}

private struct CalcRow: View {
    let label: String
    let value: String
    var color: Color = Color("brown")
    var bold: Bool = false
    var body: some View {
        HStack {
            Text(value)
                .font(.system(size: 14, weight: bold ? .bold : .medium))
                .foregroundColor(color)
            Spacer()
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(Color("brown").opacity(0.6))
        }
    }
}

private struct NextFooter: View {
    let date: Date
    @Environment(LanguageManager.self) private var lang
    var body: some View {
        HStack {
            Spacer()
            Text(String(format: lang.t("summary.nextLabel"),
                        localizedDate(date, format: "EEEE d MMMM", lang: lang)))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color("brown").opacity(0.5))
        }
        .padding(.top, 12).padding(.bottom, 4)
    }
}

private struct SparklineView: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                let w = geo.size.width
                let h = geo.size.height
                let points: [CGFloat] = [0.4, 0.55, 0.45, 0.6, 0.5, 0.7, 0.65, 0.8]
                path.move(to: CGPoint(x: 0, y: h * (1 - points[0])))
                for (i, p) in points.enumerated() {
                    path.addLine(to: CGPoint(x: w / CGFloat(points.count - 1) * CGFloat(i),
                                            y: h * (1 - p)))
                }
            }
            .stroke(Color("dark green"),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
    }
}

private struct LoadingCardView: View {
    @Environment(LanguageManager.self) private var lang
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text(lang.t("summary.analyzing"))
                .font(.system(size: 13))
                .foregroundColor(Color("brown").opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color("baige"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

private struct EmptyCard: View {
    @Environment(LanguageManager.self) private var lang
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 32))
                .foregroundColor(Color("brown").opacity(0.3))
            Text(lang.t("summary.addStocks"))
                .font(.system(size: 14))
                .foregroundColor(Color("brown").opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color("baige"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
