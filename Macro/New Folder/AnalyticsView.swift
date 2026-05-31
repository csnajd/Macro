//
//  AnalyticsView.swift
//  Macro
//
//  Created by Ghida Abdullah al-Mughamer on 25/05/2026.
//

import SwiftUI
import SwiftData

struct AnalyticsView: View {
    @Environment(AppStore.self) private var store
    
    // Reads your true persistent database holdings directly from the device disk storage
    @Query private var savedTransactions: [TransactionItem]
    
    // MARK: - Automated Dynamic Calendar Targeting Logic
    private var dynamicTargetUpgradeDate: Date {
        let calendar = Calendar.current
        // Automatically grabs whatever the current year is right now from the system clock
        let currentYear = calendar.component(.year, from: Date())
        
        // Dynamically builds the next upcoming milestone date without hardcoding the year
        return calendar.date(from: DateComponents(year: currentYear, month: 6, day: 13)) ?? Date()
    }
    
    private var dynamicProgressPercentage: CGFloat {
        let totalDuration: TimeInterval = 30 * 24 * 60 * 60 // 30-day baseline sprint scale
        let remaining = dynamicTargetUpgradeDate.timeIntervalSince(Date())
        let progress = (totalDuration - remaining) / totalDuration
        
        // Restricts horizontal bar values safely between 5% and 95% for clean UI continuity
        return CGFloat(min(max(progress, 0.05), 0.95))
    }
    
    private var totalInvestedValue: Double {
        savedTransactions.reduce(0) { $0 + ($1.price * Double($1.quantity)) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Top Header Metrics Linked to SwiftData
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total invested")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    Text("\(Int(totalInvestedValue)) SAR")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color("brown"))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total gain")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    let liveGain = store.portfolio.reduce(0.0) { $0 + $1.change }
                    Text(String(format: "%@%.0f SAR", liveGain >= 0 ? "+" : "", liveGain))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(liveGain >= 0 ? Color("dark green") : Color("burgindy"))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            Spacer()

            // MARK: - Central Allocation Circle Chart Ring
            ZStack {
                Circle()
                    .stroke(Color("brown").opacity(0.08), lineWidth: 24)
                    .frame(width: 240, height: 240)
                
                if savedTransactions.isEmpty {
                    Circle()
                        .trim(from: 0.0, to: 1.0)
                        .stroke(Color("brown").opacity(0.05), style: StrokeStyle(lineWidth: 24, lineCap: .round))
                } else {
                    ForEach(Array(savedTransactions.enumerated()), id: \.offset) { index, transaction in
                        let totalCount = Double(savedTransactions.count)
                        let start = Double(index) / totalCount
                        let end = Double(index + 1) / totalCount
                        
                        Circle()
                            .trim(from: start, to: end - 0.02)
                            .stroke(colorForSymbol(transaction.stockSymbol), style: StrokeStyle(lineWidth: 24, lineCap: .round))
                    }
                }
                
                VStack(spacing: 4) {
                    Text("\(Int(totalInvestedValue))")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(Color("brown"))
                    Text("SAR")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                    Text("PORTFOLIO")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.gray)
                        .tracking(1.0)
                }
            }
            .frame(width: 260, height: 260)
            .rotationEffect(.degrees(-90))
            
            Spacer()
            
            // MARK: - Game Upgrade Progress Card Section
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: "building.columns.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color("light brown"))
                        .frame(width: 48, height: 48)
                        .background(Color("light brown").opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Next upgrade")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.gray)
                        
                        // NATIVE APPLE DATE KIT: Render style dynamically adjusts to the device localization settings completely hands-free
                        Text(dynamicTargetUpgradeDate, style: .date)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color("brown"))
                    }
                    Spacer()
                }
                
                // Slider framework progress bar layout
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 100)
                            .fill(Color("brown").opacity(0.06))
                        RoundedRectangle(cornerRadius: 100)
                            .fill(Color("light brown"))
                            .frame(width: geo.size.width * dynamicProgressPercentage)
                    }
                }
                .frame(height: 8)
            }
            .padding(20)
            .background(Color("white"))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 24)
            .padding(.bottom, 140)
        }
        .onAppear {
            Task {
                for item in savedTransactions {
                    _ = await store.addStock(symbol: item.stockSymbol)
                }
            }
        }
    }
    
    private func colorForSymbol(_ symbol: String) -> Color {
        switch symbol {
        case let s where s.starts(with: "2010"): return Color("purple")
        case let s where s.starts(with: "7010"): return Color("burgindy")
        case let s where s.starts(with: "1120"): return Color("light brown")
        default:                                 return Color("dark green")
        }
    }
}
