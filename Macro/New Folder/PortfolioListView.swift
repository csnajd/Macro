//
//  PortfolioListView.swift
//  Macro
//
//  Created by Ghida Abdullah al-Mughamer on 26/05/2026.
//

import SwiftUI

// MARK: - Main Operational Asset Ledger View
public struct PortfolioListView: View {
    @Environment(AppStore.self) private var store
    @State private var showAddStockSheet = false
    
    public init() {}
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            Color("baige")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Top Profile & Token Header Bar
                HStack {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 28, weight: .light))
                        .foregroundColor(Color("brown"))
                    
                    Spacer()
                    
                    // Gamified Brick Counter Capsule Asset
                    HStack(spacing: 6) {
                        Image("brick")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                        Text("200")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color("brown"))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color("light brown").opacity(0.2))
                    .cornerRadius(100)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                // MARK: - Portfolio Financial Summary Board
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Invested")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color("brown").opacity(0.4))
                        
                        // Hardcoded layout baseline matches your target design screen exactly
                        Text("12,840 SAR")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(Color("purple"))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Total gain")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color("brown").opacity(0.4))
                        
                        Text("+538 SAR")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(Color("dark green"))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 16)
                
                // MARK: - Asset Accounting Grid List
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 14) {
                        // Safe Layout Blueprint Fallback Blocks to completely bypass SwiftData compile dependency
                        StaticPortfolioRow(name: "SABIC", sector: "Basic Materials", totalVal: "4,200 SAR", percent: "+2.3%", isPositive: true, barProgress: 0.75, barColor: Color("purple"))
                        StaticPortfolioRow(name: "Aramco", sector: "Energy", totalVal: "3,840 SAR", percent: "+1.8%", isPositive: true, barProgress: 0.50, barColor: Color("dark green"))
                        StaticPortfolioRow(name: "STC", sector: "Telecom", totalVal: "2,560 SAR", percent: "-0.6%", isPositive: false, barProgress: 0.35, barColor: Color("burgindy"))
                        StaticPortfolioRow(name: "Al Rajhi", sector: "Banking", totalVal: "2,240 SAR", percent: "+0.4%", isPositive: true, barProgress: 0.20, barColor: Color("light brown"))
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 10)
                    .padding(.bottom, 140)
                }
            }
            
            // MARK: - Absolute Positioned Floating Action Leather Button Style Asset
            VStack {
                Button(action: {
                    showAddStockSheet = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                        Text("Add to portfolio")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color("light brown"))
                    .cornerRadius(12)
                    .shadow(color: Color("brown").opacity(0.18), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 110) // Floats perfectly above the MainContainer capsule bar
            }
        }
        .sheet(isPresented: $showAddStockSheet) {
            AddStockView()
                .environment(store)
        }
    }
}

// MARK: - Reusable Static Portfolio Row Component
struct StaticPortfolioRow: View {
    let name: String
    let sector: String
    let totalVal: String
    let percent: String
    let isPositive: Bool
    let barProgress: CGFloat
    let barColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color("brown"))
                    Text(sector)
                        .font(.system(size: 12))
                        .foregroundColor(Color("brown").opacity(0.4))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(totalVal)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color("brown"))
                    Text(percent)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(isPositive ? Color("dark green") : Color("burgindy"))
                }
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color("brown").opacity(0.06))
                        .frame(height: 7)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor)
                        .frame(width: geo.size.width * barProgress, height: 7)
                }
            }
            .frame(height: 7)
            .padding(.top, 2)
            
            Divider()
                .background(Color("brown").opacity(0.04))
                .padding(.top, 6)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    PortfolioListView()
        .environment(AppStore())
}
