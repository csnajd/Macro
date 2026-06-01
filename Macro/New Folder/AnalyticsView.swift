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
    @Query private var savedTransactions: [TransactionItem]
    
    @State private var showHouseProgressionSheet = false

    private var dynamicTargetUpgradeDate: Date {
        let cal = Calendar.current
        let year = cal.component(.year, from: Date())
        return cal.date(from: DateComponents(year: year, month: 6, day: 13)) ?? Date()
    }

    private var dynamicProgressPercentage: CGFloat {
        let totalDuration: TimeInterval = 30 * 24 * 60 * 60
        let remaining = dynamicTargetUpgradeDate.timeIntervalSince(Date())
        let progress = (totalDuration - remaining) / totalDuration
        return CGFloat(min(max(progress, 0.05), 0.95))
    }

    private var totalInvestedValue: Double {
        savedTransactions.reduce(0) { $0 + ($1.price * Double($1.quantity)) }
    }

    var body: some View {
        ZStack {
            Color(red: 247/255, green: 246/255, blue: 242/255)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                
                // MARK: - Utility Header
                HStack {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 24, weight: .light))
                        .foregroundColor(Color("brown"))
                    Spacer()
                    CoinBadge()
                }
                .padding(.horizontal, 28)
                .padding(.top, 12)
                
                // MARK: - Main Stat Cards
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Total Invested")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color("brown").opacity(0.6))
                        Text("\(Int(totalInvestedValue).formatted()) SAR")
                            .font(.system(size: 21, weight: .bold))
                            .foregroundColor(Color("purple"))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 6) {
                        Text("Total gain")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color("brown").opacity(0.6))
                        
                        let liveGain = store.portfolio.reduce(0.0) { $0 + $1.change }
                        Text(String(format: "%@%.0f SAR", liveGain >= 0 ? "+" : "", liveGain))
                            .font(.system(size: 21, weight: .bold))
                            .foregroundColor(Color("dark green"))
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
                        if savedTransactions.isEmpty {
                            Circle()
                                .trim(from: 0.0, to: 1.0)
                                .stroke(Color("dark baige").opacity(0.3), style: StrokeStyle(lineWidth: 26, lineCap: .round))
                        } else {
                            let slices = computeDynamicSlices()
                            ForEach(0..<slices.count, id: \.self) { index in
                                let slice = slices[index]
                                Circle()
                                    .trim(from: slice.startPercent, to: slice.endPercent - 0.04)
                                    .stroke(colorForIndex(index), style: StrokeStyle(lineWidth: 26, lineCap: .round))
                            }
                        }
                    }
                    .frame(width: 215, height: 215)
                    .rotationEffect(.degrees(-90))

                    VStack(spacing: 1) {
                        Text("\(Int(totalInvestedValue).formatted())")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(Color("brown"))
                        Text("SAR")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color("brown").opacity(0.7))
                        Text("PORTFOLIO")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color("brown").opacity(0.5))
                            .tracking(0.8)
                            .padding(.top, 1)
                        
                        let totalChange = store.portfolio.reduce(0.0) { $0 + $1.change }
                        let totalCurrentValue = store.portfolio.reduce(0.0) { $0 + $1.price }
                        let realPercentage = totalCurrentValue > 0 ? (totalChange / totalCurrentValue) * 100 : 0.0
                        
                        HStack(spacing: 2) {
                            Text(String(format: "%@%.1f%%", realPercentage >= 0 ? "+" : "", realPercentage))
                            Image(systemName: realPercentage >= 0 ? "arrow.up.right" : "arrow.down.right")
                        }
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(realPercentage >= 0 ? Color("dark green") : Color("burgindy"))
                        .padding(.top, 3)
                    }
                }
                .frame(width: 250, height: 250)

                Spacer()

                // MARK: - Interactive Upgrade Action Panel
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
                            Text("Next upgrade in")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color("brown"))
                            
                            Text("2 days remaining")
                                .font(.system(size: 12))
                                .foregroundColor(Color("brown").opacity(0.6))
                            
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 100)
                                        .fill(Color("dark baige").opacity(0.2))
                                    RoundedRectangle(cornerRadius: 100)
                                        .fill(Color("light brown"))
                                        .frame(width: geo.size.width * 0.75)
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
        .sheet(isPresented: $showHouseProgressionSheet) {
            HouseProgressionView()
                .environment(store)
        }
    }

    private struct WheelSlice {
        let startPercent: Double
        let endPercent: Double
    }

    private func computeDynamicSlices() -> [WheelSlice] {
        guard totalInvestedValue > 0 else { return [] }
        var list: [WheelSlice] = []
        var currentAccumulator = 0.0
        for tx in savedTransactions {
            let itemCostBasis = tx.price * Double(tx.quantity)
            let itemPercentage = itemCostBasis / totalInvestedValue
            let start = currentAccumulator
            let end = currentAccumulator + itemPercentage
            list.append(WheelSlice(startPercent: start, endPercent: end))
            currentAccumulator = end
        }
        return list
    }

    private func colorForIndex(_ index: Int) -> Color {
        let strictColors = ["green", "light green", "dark green", "light brown", "burgindy", "purple", "light purple"]
        return Color(strictColors[index % strictColors.count])
    }
}
