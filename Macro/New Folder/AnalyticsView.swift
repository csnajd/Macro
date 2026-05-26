//
//  AnalyticsView.swift
//  Macro
//
//  Created by Ghida Abdullah al-Mughamer on 25/05/2026.
//

import SwiftUI

struct InvestmentSegment: Identifiable {
    let id = UUID()
    let value: Double
    let color: Color
}

struct DonutChartView: View {
    let segments: [InvestmentSegment]
    let totalValue: Double
    let centerLabel: String
    let centerSubLabel: String
    
    var body: some View {
        ZStack {
            ForEach(0..<segments.count, id: \.self) { index in
                Circle()
                    .trim(from: startAngle(for: index), to: endAngle(for: index))
                    .stroke(segments[index].color, style: StrokeStyle(lineWidth: 24, lineCap: .round))
                    .rotationEffect(.degrees(-90)) // Dynamic sweep orientation control
            }
            
            // Center Metrics Core Card Asset
            VStack(spacing: 2) {
                Text(centerLabel)
                    .font(.rassahSans(size: 22, weight: .bold))
                    .foregroundColor(.rassahBrown)
                Text("SAR")
                    .font(.rassahSans(size: 12, weight: .medium))
                    .foregroundColor(.rassahBrown.opacity(0.6))
                Text(centerSubLabel)
                    .font(.rassahSans(size: 11, weight: .bold))
                    .foregroundColor(.darkGreen)
            }
        }
        .frame(width: 180, height: 180)
    }
    
    private func startAngle(for index: Int) -> Double {
        let previousSum = segments.prefix(index).reduce(0) { $0 + $1.value }
        return previousSum / totalValue
    }
    
    private func endAngle(for index: Int) -> Double {
        let currentSum = segments.prefix(index + 1).reduce(0) { $0 + $1.value }
        return currentSum / totalValue
    }
}
