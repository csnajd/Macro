
//
//  HoldingDetailSheet.swift
//  Macro
//
//  Created by Ghida Abdullah al-Mughamer on 02/06/2026.
//
 
import SwiftUI
import SwiftData
 
struct HoldingDetailSheet: View {
    let position: PortfolioMath.Position
 
    @Environment(AppStore.self) private var store
    @Environment(LanguageManager.self) private var lang
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
 
    @State private var sellQuantity: Int = 1
    @State private var didSell: Bool = false
 
    private var livePrice: Double? {
        store.livePrice(for: position.symbol)
    }
 
    private var currentValue: Double {
        (livePrice ?? position.averageBuyPrice) * Double(position.quantity)
    }
 
    private var unrealizedGain: Double {
        currentValue - position.costBasis
    }
 
    var body: some View {
        ZStack {
            Color("baige").ignoresSafeArea()
 
            VStack(spacing: 0) {
 
                // Header
                HStack {
                    Text(store.getReadableName(for: position.symbol))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color("brown"))
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 26))
                            .foregroundColor(Color("brown").opacity(0.3))
                    }
                }
                .padding(.top, 24)
                .padding(.horizontal, 24)
 
                // Symbol
                Text(position.symbol)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color("brown").opacity(0.5))
                    .tracking(1.0)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 4)
 
                // Unrealized gain badge
                HStack(spacing: 4) {
                    Text(unrealizedGain >= 0 ? "+" : "")
                    Text(String(format: "%.2f %@", unrealizedGain, lang.t("unit.sar")))
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(unrealizedGain >= 0 ? Color("dark green") : Color("burgindy"))
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background((unrealizedGain >= 0 ? Color("dark green") : Color("burgindy")).opacity(0.1))
                .clipShape(Capsule())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 8)
 
                // Metrics card
                VStack(spacing: 14) {
                    MetricRow(label: lang.t("sell.sharesHeld"),
                              value: "\(position.quantity)")
                    Divider()
                    MetricRow(label: lang.t("sell.avgBuyPrice"),
                              value: String(format: "%.2f %@", position.averageBuyPrice, lang.t("unit.sar")))
                    Divider()
                    MetricRow(label: lang.t("sell.currentValue"),
                              value: String(format: "%.2f %@", currentValue, lang.t("unit.sar")))
                }
                .padding(20)
                .background(Color("white"))
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .padding(.horizontal, 24)
                .padding(.top, 24)
 
                // Sell controls
                VStack(spacing: 16) {
                    Text(lang.t("sell.howMany"))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color("brown"))
                        .frame(maxWidth: .infinity, alignment: .leading)
 
                    Stepper(value: $sellQuantity, in: 1...position.quantity) {
                        HStack {
                            Text(lang.t("sell.sharesHeld"))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color("brown").opacity(0.6))
                            Spacer()
                            Text("\(sellQuantity)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color("brown"))
                        }
                    }
                    .tint(Color("brown"))
 
                    Button {
                        performSell()
                    } label: {
                        Text(String(format: sellQuantity > 1
                                    ? lang.t("sell.sellShares")
                                    : lang.t("sell.sellShare"), sellQuantity))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color("brown"))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(20)
                .background(Color("white"))
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .padding(.horizontal, 24)
                .padding(.top, 16)
 
                Spacer()
            }
        }
    }
 
    private func performSell() {
        let sellPrice = livePrice ?? position.averageBuyPrice
        let realizedGain = (sellPrice - position.averageBuyPrice) * Double(sellQuantity)
 
        let tx = Transaction(
            symbol: position.symbol,
            type: .sell,
            quantity: sellQuantity,
            pricePerShare: sellPrice,
            date: Date(),
            realizedGain: realizedGain,
            userID: store.currentUserID   // ✅ stamp the sell with the current account
        )
 
        modelContext.insert(tx)
 
        do {
            try modelContext.save()
            store.awardBricks(fromRealizedGain: realizedGain)
            dismiss()
        } catch {
            print("Failed to save sell transaction: \(error.localizedDescription)")
        }
    }
}
 
// MARK: - Metric Row
struct MetricRow: View {
    let label: String
    let value: String
 
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color("brown").opacity(0.6))
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color("brown"))
        }
    }
}
 
