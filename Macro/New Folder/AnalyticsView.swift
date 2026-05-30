//
//   AnalyticsView.swift
//   Macro
//
//   Created by Ghida Abdullah al-Mughamer on 26/05/2026.
//

import SwiftUI
import SwiftData

// MARK: - Chart Segment Model
public struct InvestmentSegment: Identifiable {
    public let id    = UUID()
    public let value: Double
    public let color: Color

    public init(value: Double, color: Color) {
        self.value = value
        self.color = color
    }
}

// MARK: - Donut Chart
public struct DonutChartView: View {
    let segments:       [InvestmentSegment]
    let totalValue:     Double
    let centerLabel:    String
    let centerSubLabel: String

    public init(segments: [InvestmentSegment], totalValue: Double,
                centerLabel: String, centerSubLabel: String) {
        self.segments       = segments
        self.totalValue     = totalValue
        self.centerLabel    = centerLabel
        self.centerSubLabel = centerSubLabel
    }

    public var body: some View {
        ZStack {
            ForEach(0..<segments.count, id: \.self) { i in
                Circle()
                    .trim(from: trimStart(for: i), to: trimEnd(for: i))
                    .stroke(segments[i].color, style: StrokeStyle(lineWidth: 24, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .padding(14)
            }

            VStack(spacing: 2) {
                Text(centerLabel)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(Color("brown"))
                Text("SAR")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color("brown").opacity(0.5))
                Text("PORTFOLIO")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color("brown").opacity(0.4))
                    .tracking(0.5)
                    .padding(.top, 2)
                Text(centerSubLabel)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color("dark green"))
                    .padding(.top, 2)
            }
        }
        .frame(width: 220, height: 220)
    }

    private func trimStart(for index: Int) -> Double {
        let prev = segments.prefix(index).reduce(0) { $0 + $1.value }
        return (prev / totalValue) + (index == 0 ? 0 : 0.015)
    }

    private func trimEnd(for index: Int) -> Double {
        let curr = segments.prefix(index + 1).reduce(0) { $0 + $1.value }
        return (curr / totalValue) - 0.015
    }
}

// MARK: - Analytics Hub View
public struct AnalyticsView: View {
    @Environment(AppStore.self) private var store
    @Query private var transactions: [TransactionItem]

    private var chartSegments: [InvestmentSegment] {[
        InvestmentSegment(value: 40, color: Color("light purple")),
        InvestmentSegment(value: 25, color: Color("dark green")),
        InvestmentSegment(value: 20, color: Color("green")),
        InvestmentSegment(value: 15, color: Color("light brown"))
    ]}

    public init() {}

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(Color("brown"))
                    Spacer()
                    CoinBadge()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                StatHeaderView(totalInvested: store.totalInvested, totalGain: store.totalGain)

                ZStack {
                    DonutChartView(segments: chartSegments, totalValue: 100, centerLabel: "12,840", centerSubLabel: "+4.3% ↗")
                }
                .padding(.top, 36)
                .padding(.bottom, 24)

                UpgradeProgressCard()
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                Spacer(minLength: 120)
            }
        }
        .background(Color("white").ignoresSafeArea())
    }
}

struct UpgradeProgressCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 16) {
                ZStack {
                    Color("baige").clipShape(RoundedRectangle(cornerRadius: 12))
                    Image(systemName: "building.columns.fill")
                        .font(.system(size: 26))
                        .foregroundColor(Color("light brown"))
                }
                .frame(width: 60, height: 60)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Next upgrade in").font(.system(size: 16, weight: .semibold)).foregroundColor(Color("brown"))
                    Text("2 days remaining").font(.system(size: 13)).foregroundColor(Color("brown").opacity(0.5))
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 14, weight: .medium)).foregroundColor(Color("brown").opacity(0.3))
            }

            VStack(spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 100).fill(Color("brown").opacity(0.08)).frame(height: 8)
                        RoundedRectangle(cornerRadius: 100).fill(Color("brown").opacity(0.4)).frame(width: geo.size.width * 0.95, height: 8)
                    }
                }
                .frame(height: 8)

                HStack {
                    Text("950/1000").font(.system(size: 11, weight: .medium)).foregroundColor(Color("brown").opacity(0.5))
                    Spacer()
                    Text("95%").font(.system(size: 11, weight: .bold)).foregroundColor(Color("brown").opacity(0.5))
                }
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color("brown").opacity(0.05), radius: 10, x: 0, y: 6)
    }
}


