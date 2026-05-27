//
//  AnalyticsView.swift
//  Macro
//
//  Created by Ghida Abdullah al-Mughamer on 26/05/2026.
//

import SwiftUI
import SwiftData

// MARK: - Core Chart Data Model
public struct InvestmentSegment: Identifiable {
    public let id = UUID()
    public let value: Double
    public let color: Color
    
    public init(value: Double, color: Color) {
        self.value = value
        self.color = color
    }
}

// MARK: - Spatial Donut Chart Vector View Component
public struct DonutChartView: View {
    let segments: [InvestmentSegment]
    let totalValue: Double
    let centerLabel: String
    let centerSubLabel: String
    
    public init(segments: [InvestmentSegment], totalValue: Double, centerLabel: String, centerSubLabel: String) {
        self.segments = segments
        self.totalValue = totalValue
        self.centerLabel = centerLabel
        self.centerSubLabel = centerSubLabel
    }
    
    public var body: some View {
        ZStack {
            ForEach(0..<segments.count, id: \.self) { index in
                Circle()
                    .trim(from: startAngle(for: index), to: endAngle(for: index))
                    // 24pt stroke thickness with clean gaps and rounded caps matching your Figma curves
                    .stroke(segments[index].color, style: StrokeStyle(lineWidth: 24, lineCap: .round))
                    .rotationEffect(.degrees(-90)) // Aligns the slice start straight up to noon
                    .padding(14) // Structural inner layout padding layer
            }
            
            // Center Metrics Core Card Asset
            VStack(spacing: 2) {
                Text(centerLabel)
                    .font(.rassahSans(size: 26, weight: .bold))
                    .foregroundColor(Color("brown"))
                Text("SAR")
                    .font(.rassahSans(size: 12, weight: .semibold))
                    .foregroundColor(Color("brown").opacity(0.5))
                Text("PORTFOLIO")
                    .font(.rassahSans(size: 11, weight: .bold))
                    .foregroundColor(Color("brown").opacity(0.4))
                    .tracking(0.5)
                    .padding(.top, 2)
                Text(centerSubLabel)
                    .font(.rassahSans(size: 13, weight: .bold))
                    .foregroundColor(Color("dark green"))
                    .padding(.top, 2)
            }
        }
        .frame(width: 220, height: 220) // Proportional spatial footprint layout boundary box
    }
    
    private func startAngle(for index: Int) -> Double {
        let previousSum = segments.prefix(index).reduce(0) { $0 + $1.value }
        // Minor math padding injection (0.015) forms the custom premium gaps between slices seen in your wireframe
        return (previousSum / totalValue) + (index == 0 ? 0 : 0.015)
    }
    
    private func endAngle(for index: Int) -> Double {
        let currentSum = segments.prefix(index + 1).reduce(0) { $0 + $1.value }
        return (currentSum / totalValue) - 0.015
    }
}

// MARK: - Main Analytics Hub View
public struct AnalyticsView: View {
    @Environment(AppStore.self) private var store
    @Query private var transactions: [TransactionItem]
    
    // Explicit 1:1 mapping to your exact asset catalog strings
    private var chartSegments: [InvestmentSegment] {
        [
            InvestmentSegment(value: 40, color: Color("light purple")),
            InvestmentSegment(value: 25, color: Color("dark green")),
            InvestmentSegment(value: 20, color: Color("green")),
            InvestmentSegment(value: 15, color: Color("light brown"))
        ]
    }
    
    public init() {}
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                // MARK: - Top Profile & Token Header Row
                HStack {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(Color("brown"))
                    
                    Spacer()
                    
                    // Gamified Brick Counter Token Capsule
                    HStack(spacing: 6) {
                        Image("brick")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                        Text("200")
                            .font(.rassahSans(size: 14, weight: .bold))
                            .foregroundColor(Color("brown"))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color("light brown").opacity(0.18))
                    .cornerRadius(RassahTokens.radiusCapsule)
                }
                .padding(.horizontal, RassahTokens.paddingLarge)
                .padding(.top, 16)
                
                // MARK: - Metrics Overview Labels
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Invested")
                            .font(.rassahSans(size: 13, weight: .medium))
                            .foregroundColor(Color("brown").opacity(0.4))
                        Text("12,840 SAR")
                            .font(.rassahSans(size: 24, weight: .bold))
                            .foregroundColor(Color("purple"))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Total gain")
                            .font(.rassahSans(size: 13, weight: .medium))
                            .foregroundColor(Color("brown").opacity(0.4))
                        Text("+538 SAR")
                            .font(.rassahSans(size: 24, weight: .bold))
                            .foregroundColor(Color("dark green"))
                    }
                }
                .padding(.horizontal, RassahTokens.paddingLarge)
                .padding(.top, 28)
                
                // MARK: - Central Interactive Segmented Chart Node
                ZStack {
                    DonutChartView(
                        segments: chartSegments,
                        totalValue: 100,
                        centerLabel: "12,840",
                        centerSubLabel: "+4.3% ↗"
                    )
                }
                .padding(.top, 36)
                .padding(.bottom, 24)
                
                // MARK: - Gamified Cultural Milestone Upgrade Card
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 16) {
                        // Castle Vector Art Frame Anchor
                        ZStack {
                            Color("baige")
                                .cornerRadius(12)
                            Image(systemName: "building.columns.fill")
                                .font(.system(size: 26))
                                .foregroundColor(Color("light brown"))
                        }
                        .frame(width: 60, height: 60)
                        .shadow(color: Color("brown").opacity(0.04), radius: 4, x: 0, y: 2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Next upgrade in")
                                .font(.rassahSans(size: 16, weight: .semibold))
                                .foregroundColor(Color("brown"))
                            Text("2 days remaining")
                                .font(.rassahSans(size: 13))
                                .foregroundColor(Color("brown").opacity(0.5))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color("brown").opacity(0.3))
                    }
                    
                    // Geometric Progress Meter Spacing
                    VStack(spacing: 6) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: RassahTokens.radiusCapsule)
                                    .fill(Color("brown").opacity(0.08))
                                    .frame(height: 8)
                                
                                RoundedRectangle(cornerRadius: RassahTokens.radiusCapsule)
                                    .fill(Color("brown").opacity(0.4))
                                    .frame(width: geo.size.width * 0.95, height: 8)
                            }
                        }
                        .frame(height: 8)
                        
                        HStack {
                            Text("950/1000")
                                .font(.rassahSans(size: 11, weight: .medium))
                                .foregroundColor(Color("brown").opacity(0.5))
                            Spacer()
                            Text("95%")
                                .font(.rassahSans(size: 11, weight: .bold))
                                .foregroundColor(Color("brown").opacity(0.5))
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(RassahTokens.paddingMedium)
                .background(Color("white"))
                .cornerRadius(20)
                .shadow(color: Color("brown").opacity(0.05), radius: 10, x: 0, y: 6)
                .padding(.horizontal, RassahTokens.paddingLarge)
                .padding(.top, 20)
                
                Spacer(minLength: 120)
            }
        }
        .background(Color("baige").ignoresSafeArea())
    }
}

#Preview {
    AnalyticsView()
        .environment(AppStore())
}
