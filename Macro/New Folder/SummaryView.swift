//
//  SummaryView.swift
//  Macro
//

import SwiftUI

private enum SummaryExpansion {
    case collapsed
    case expanded
    case full
}

struct SummaryView: View {
    @Environment(AppStore.self) private var store
    @State private var aiService = AISummaryService()
    @State private var expansion: SummaryExpansion = .collapsed

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {

                HStack {
                    Text("الملخص")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color("brown"))
                    Spacer()
                    CoinBadge()
                }
                .environment(\.layoutDirection, .rightToLeft)
                .padding(.horizontal, 24)
                .padding(.top, 16)

                HStack {
                    Text("إعدادات الملخص")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color("brown"))
                    Spacer()
                }
                .environment(\.layoutDirection, .rightToLeft)
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
        .environment(\.layoutDirection, .rightToLeft)
        .task {
            await aiService.generateSummary(portfolio: store.portfolio)
        }
        .onChange(of: store.portfolio.count) { _, _ in
            Task { await aiService.generateSummary(portfolio: store.portfolio) }
        }
    }
}

// MARK: - Collapsed
private struct CollapsedCard: View {
    let summary: WeeklySummary
    @Binding var expansion: SummaryExpansion
    @Environment(AppStore.self) private var store

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
                    Text(summary.weekLabel)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color("brown").opacity(0.6))
                }
            }
            .padding(.bottom, 8)

            Text(String(format: "%@%.0f SAR", summary.totalChange >= 0 ? "+" : "", summary.totalChange))
                .font(.system(size: 34, weight: .bold, design: .serif))
                .foregroundColor(Color("dark green"))
                .frame(maxWidth: .infinity, alignment: .trailing)

            SparklineView()
                .frame(height: 48)
                .padding(.vertical, 8)

            Text(summary.weekClassification + " — " + summary.marketDriver)
                .font(.system(size: 13))
                .foregroundColor(Color("brown").opacity(0.6))
                .multilineTextAlignment(.trailing)
                .lineLimit(2)

            Divider().padding(.vertical, 12)

            MoversList(portfolio: Array(store.portfolio.prefix(3)))

            NextFooter(label: summary.nextSummaryLabel)
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
                    Text(summary.weekLabel)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color("brown").opacity(0.6))
                }
            }
            .padding(.bottom, 8)

            Text(String(format: "%@%.0f SAR", summary.totalChange >= 0 ? "+" : "", summary.totalChange))
                .font(.system(size: 34, weight: .bold, design: .serif))
                .foregroundColor(Color("dark green"))
                .frame(maxWidth: .infinity, alignment: .trailing)

            VStack(alignment: .trailing, spacing: 10) {
                Text("كيف تم الحساب")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color("brown"))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.bottom, 2)

                CalcRow(label: "القيمة الابتدائية",
                        value: String(format: "%.0f SAR", summary.portfolioValue))
                CalcRow(label: "أرباح المراكز",
                        value: String(format: "+%.0f SAR", summary.portfolioGains),
                        color: Color("dark green"))
                CalcRow(label: "خسائر المراكز",
                        value: String(format: "%.0f SAR", summary.portfolioLosses),
                        color: Color("burgindy"))
                Divider()
                CalcRow(label: "صافي التغيير",
                        value: String(format: "%@%.0f SAR", summary.netChange >= 0 ? "+" : "", summary.netChange),
                        color: Color("dark green"),
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
                    Text(summary.marketDriver)
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

            NextFooter(label: summary.nextSummaryLabel)
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
                    Text(summary.weekLabel)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color("brown").opacity(0.6))
                }
            }

            Text(String(format: "ارتفعت المحفظة %.1f%% خلال 7 أيام.", summary.weeklyChangePercent))
                .font(.system(size: 13))
                .foregroundColor(Color("brown").opacity(0.75))
                .multilineTextAlignment(.trailing)
                .padding(.top, 8)

            // كيف تم الحساب
            STitle("كيف تم الحساب")
            VStack(spacing: 8) {
                HStack {
                    Text(String(format: "+%.1f%%", summary.weeklyChangePercent))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color("dark green"))
                    Spacer()
                    Text("محفظتك")
                        .font(.system(size: 13))
                        .foregroundColor(Color("brown").opacity(0.6))
                }
                HStack {
                    Text(String(format: "+%.1f%%", summary.tasiChange))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color("brown"))
                    Spacer()
                    Text("TASI (مؤشر كل الأسهم)")
                        .font(.system(size: 13))
                        .foregroundColor(Color("brown").opacity(0.6))
                }
                HStack {
                    Spacer()
                    Text(String(format: "تفوقت على السوق بـ +%.1f%%", summary.marketOutperform))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color("dark green"))
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Color("dark green").opacity(0.12))
                        .clipShape(Capsule())
                }
            }
            .padding(12)
            .background(Color("white").opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // قطاعات
            STitle("قطاعات تداول هذا الأسبوع")
            VStack(spacing: 8) {
                ForEach(summary.sectorPerformance) { sector in
                    HStack(spacing: 10) {
                        Text(String(format: "%@%.1f%%", sector.changePercent >= 0 ? "+" : "", sector.changePercent))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(sector.isPositive ? Color("dark green") : Color("burgindy"))
                            .frame(width: 52, alignment: .leading)
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 6)
                                .fill(sector.isPositive ? Color("dark green").opacity(0.7) : Color("burgindy").opacity(0.7))
                                .frame(width: geo.size.width * CGFloat(min(abs(sector.changePercent) / 5.0, 1.0)), height: 10)
                        }
                        .frame(height: 10)
                        Text(sector.name)
                            .font(.system(size: 13))
                            .foregroundColor(Color("brown").opacity(0.7))
                            .frame(width: 90, alignment: .trailing)
                    }
                }
            }
            .padding(12)
            .background(Color("white").opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // ما حرّك السوق
            STitle("ما الذي حرّك السوق")
            InsightBlock(highlight: summary.marketDriver,
                         bodyText: summary.marketDriverDetail,
                         isAlert: false)
            InsightBlock(highlight: "أرباح البنوك للربع الأول تجاوزت التوقعات",
                         bodyText: "أعلن الراجحي عن نمو أرباح 7٪ سنويًا.",
                         isAlert: false)

            if let alert = summary.sectorAlert, let detail = summary.sectorAlertDetail {
                InsightBlock(highlight: alert, bodyText: detail, isAlert: true)
            }

            // نظرة للأمام
            STitle("نظرة للأمام")
            Text(summary.forwardLook)
                .font(.system(size: 13))
                .foregroundColor(Color("brown").opacity(0.75))
                .multilineTextAlignment(.trailing)
                .padding(.vertical, 6)

            Divider().padding(.vertical, 12)

            STitle("أبرز المتحركين")
            MoversList(portfolio: portfolio)

            HStack {
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("+54")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(Color("light purple"))
                    Text("الطابوق المكتسب هذا الأسبوع")
                        .font(.system(size: 11))
                        .foregroundColor(Color("brown").opacity(0.5))
                    Text("من أرباحك")
                        .font(.system(size: 11))
                        .foregroundColor(Color("brown").opacity(0.5))
                }
            }
            .padding(.top, 12)

            NextFooter(label: summary.nextSummaryLabel)
        }
        .padding(16)
        .background(Color("baige"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Reusable Components

private struct MoversList: View {
    let portfolio: [Stock]
    var body: some View {
        VStack(spacing: 0) {
            ForEach(portfolio) { stock in
                HStack(spacing: 14) {
                    StockAvatarView(symbol: stock.symbol)
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(stock.symbol.replacingOccurrences(of: ".SR", with: ""))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color("brown"))
                        Text(stock.category.rawValue)
                            .font(.system(size: 12))
                            .foregroundColor(Color("brown").opacity(0.45))
                    }
                    Spacer()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(Int(stock.price)) SAR")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color("brown"))
                        Text(String(format: "%@%.1f%%", stock.changePercent >= 0 ? "+" : "", stock.changePercent))
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
private struct InsightBlock: View {
    let highlight: String
    let bodyText: String
    let isAlert: Bool

    var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            Text(highlight)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(isAlert ? Color("burgindy") : Color("dark green"))
                .frame(maxWidth: .infinity, alignment: .trailing)
            Text(bodyText)
                .font(.system(size: 13))
                .foregroundColor(Color("brown").opacity(0.7))
                .multilineTextAlignment(.trailing)
        }
        .padding(12)
        .background(isAlert ? Color("burgindy").opacity(0.07) : Color("white").opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.bottom, 6)
    }
}
private struct NextFooter: View {
    let label: String
    var body: some View {
        HStack {
            Spacer()
            Text("الملخص القادم: \(label)")
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
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("يتم تحليل محفظتك…")
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
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 32))
                .foregroundColor(Color("brown").opacity(0.3))
            Text("أضف أسهمًا لتوليد الملخص")
                .font(.system(size: 14))
                .foregroundColor(Color("brown").opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color("baige"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
