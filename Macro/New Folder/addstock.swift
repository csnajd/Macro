//
//  addstock.swift
//  Macro
//
//  Created by Ghida Abdullah al-Mughamer on 25/05/2026.
//

import SwiftUI

public struct AddStockView: View {
    @State private var searchQuery: String = ""
    @State private var selectedCategory: String = "Banking"
    
    let categories = ["Popular", "Banking", "Energy"]
    
    public init() {}
    
    public var body: some View {
        ZStack {
            Color.rassahBaige
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Header Sheet Bar Navigation Asset
                HStack {
                    Button(action: {}) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.rassahBrown)
                    }
                    
                    Spacer()
                    
                    Text("Add Stock")
                        .font(.rassahSans(size: 17, weight: .semibold))
                        .foregroundColor(.rassahBrown)
                    
                    Spacer()
                    
                    // Gamified Brick Counter Token Capsule
                    HStack(spacing: 6) {
                        Image(systemName: "cube.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.rassahLeatherButton)
                        Text("200")
                            .font(.rassahSans(size: 13, weight: .bold))
                            .foregroundColor(.rassahBrown)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.rassahLeatherButton.opacity(0.25))
                    .cornerRadius(RassahTokens.radiusCapsule)
                }
                .padding(.horizontal, RassahTokens.paddingLarge)
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                // Minimalist Search Field Row Component
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.rassahBrown.opacity(0.4))
                    TextField("Search Tadawul stocks...", text: $searchQuery)
                        .font(.rassahSans(size: 15))
                        .foregroundColor(.rassahBrown)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(Color.rassahCardSecondary)
                .cornerRadius(14)
                .padding(.horizontal, RassahTokens.paddingLarge)
                
                // Horizontal Interactive Category Track Filter
                HStack(spacing: 10) {
                    ForEach(categories, id: \.self) { category in
                        Button(action: {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                selectedCategory = category
                            }
                        }) {
                            Text(category)
                                .font(.rassahSans(size: 13, weight: selectedCategory == category ? .semibold : .regular))
                                .foregroundColor(selectedCategory == category ? .rassahWhite : .rassahBrown)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedCategory == category ? Color.rassahBrown : Color.rassahWhite)
                                .cornerRadius(RassahTokens.radiusCapsule)
                                .shadow(color: Color.rassahBrown.opacity(0.03), radius: 4, x: 0, y: 2)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, RassahTokens.paddingLarge)
                .padding(.top, 20)
                
                // Section Title Label Node
                HStack {
                    Text("POPULAR IN SAUDI MARKET")
                        .font(.rassahSans(size: 11, weight: .bold))
                        .foregroundColor(.rassahBrown.opacity(0.4))
                        .tracking(0.5)
                    Spacer()
                }
                .padding(.horizontal, RassahTokens.paddingLarge)
                .padding(.top, 24)
                .padding(.bottom, 12)
                
                // Tadawul Asset Result Grid List Loop
                ScrollView {
                    VStack(spacing: 12) {
                        StockRowComponent(ticker: "SB", name: "SABIC", sector: "Basic Materials", val: "350 SAR", change: "+2.3%", isPositive: true)
                        StockRowComponent(ticker: "AR", name: "Aramco", sector: "Energy", val: "3,840 SAR", change: "+1.8%", isPositive: true)
                        StockRowComponent(ticker: "STC", name: "STC", sector: "Telecom", val: "240 SAR", change: "-0.6%", isPositive: false)
                        StockRowComponent(ticker: "AD", name: "Al Rajhi", sector: "Banking", val: "185 SAR", change: "+0.4%", isPositive: true)
                    }
                    .padding(.horizontal, RassahTokens.paddingLarge)
                }
                
                // Absolute Position Lower Floating Button
                Button(action: {}) {
                    Text("Add to portfolio")
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, RassahTokens.paddingLarge)
                .padding(.bottom, 24)
            }
        }
    }
}

// MARK: - Reusable Stock List Entry Segment Component
struct StockRowComponent: View {
    let ticker: String
    let name: String
    let sector: String
    let val: String
    let change: String
    let isPositive: Bool
    
    var body: some View {
        HStack(spacing: 14) {
            // Circle Monogram Node Block
            Text(ticker)
                .font(.rassahSans(size: 12, weight: .bold))
                .foregroundColor(.rassahBrown)
                .frame(width: 42, height: 42)
                .background(Color.rassahCardSecondary)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.rassahSans(size: 15, weight: .semibold))
                    .foregroundColor(.rassahBrown)
                Text(sector)
                    .font(.rassahSans(size: 12))
                    .foregroundColor(.rassahBrown.opacity(0.5))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(val)
                    .font(.rassahSans(size: 14, weight: .bold))
                    .foregroundColor(.rassahBrown)
                Text(change)
                    .font(.rassahSans(size: 12, weight: .bold))
                    .foregroundColor(isPositive ? .rassahDarkGreen : .rassahBurgundy)
            }
        }
        .padding(.vertical, 8)
    }
}
