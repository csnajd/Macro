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
    
    @EnvironmentObject private var store: GhinahAppStore
    @Environment(LanguageManager.self) private var lang
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var sellQuantity: Int = 1
    @State private var lastBricksEarned: Int? = nil
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
        NavigationView {
            ZStack {
                Color(red: 245/255, green: 242/255, blue: 235/255)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        
                        // MARK: - Asset Performance Header
                        VStack(spacing: 8) {
                            Text(store.getReadableName(for: position.symbol))
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(Color("brown"))
                            
                            Text(position.symbol)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.gray)
                                .tracking(1.0)
                            
                            HStack(spacing: 4) {
                                Text(unrealizedGain >= 0 ? "+" : "")
                                Text(String(format: "%.2f SAR", unrealizedGain))
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .foregroundColor(unrealizedGain >= 0 ? Color("dark green") : .red)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(unrealizedGain >= 0 ? Color("dark green").opacity(0.1) : .red.opacity(0.1))
                            .clipShape(Capsule())
                        }
                        .padding(.top, 20)
                        
                        // MARK: - Structural Holding Metrics
                        VStack(spacing: 14) {
                            MetricRow(label: "Shares Held", value: "\(position.quantity)")
                            Divider()
                            MetricRow(label: "Avg Buy Price", value: String(format: "%.2f SAR", position.averageBuyPrice))
                            Divider()
                            MetricRow(label: "Current Value", value: String(format: "%.2f SAR", currentValue))
                        }
                        .padding(20)
                        .background(Color("white"))
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        
                        // MARK: - Liquidation Controls
                        VStack(spacing: 16) {
                            Text("LIQUIDATE HOLDING POSITION")
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(Color("light brown"))
                                .tracking(1.2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Stepper(value: $sellQuantity, in: 1...position.quantity) {
                                HStack {
                                    Text("Quantity to Sell:")
                                        .font(.system(size: 14, weight: .medium))
                                    Spacer()
                                    Text("\(sellQuantity)")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(Color("brown"))
                                }
                            }
                            .tint(Color("brown"))
                            
                            Button {
                                executeAssetLiquidation()
                            } label: {
                                Text("Confirm Transaction Sale")
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
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundColor(Color("brown"))
                }
            }
        }
    }
    
    private func executeAssetLiquidation() {
        let realizedGain = ((livePrice ?? position.averageBuyPrice) - position.averageBuyPrice) * Double(sellQuantity)
        let brickReward = max(0, Int(realizedGain / 3.4))
        
        let tx = Transaction(
            symbol: position.symbol,
            type: .sell,
            quantity: -sellQuantity,
            pricePerShare: livePrice ?? position.averageBuyPrice,
            date: Date()
        )
        
        modelContext.insert(tx)
        
        do {
            try modelContext.save()
            lastBricksEarned = brickReward
            didSell = true
            dismiss()
        } catch {
            print("Failed to save transaction item record: \(error.localizedDescription)")
        }
    }
}

// MARK: - Locally Bound Layout Helpers
struct MetricRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color("brown"))
        }
    }
}
