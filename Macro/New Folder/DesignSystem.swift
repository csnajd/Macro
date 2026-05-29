// Add these to the absolute bottom of your DesignSystem.swift file if they are missing

import SwiftUI

// MARK: - Reusable Coin Badge
struct CoinBadge: View {
    var count: Int = 0 // Simulating a fresh onboarding experience

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "cube.fill")
                .font(.system(size: 12))
                .foregroundColor(Color("light brown"))
            Text("\(count)")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color("brown"))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color("light brown").opacity(0.18))
        .clipShape(Capsule())
    }
}

// MARK: - Reusable Stock Avatar Monogram
struct StockAvatarView: View {
    let symbol: String
    var size: CGFloat = 42

    private var abbreviation: String {
        let clean = symbol.replacingOccurrences(of: ".SR", with: "")
        return String(clean.prefix(clean.count > 3 ? 2 : 3)).uppercased()
    }

    var body: some View {
        Text(abbreviation)
            .font(.system(size: abbreviation.count > 2 ? 11 : 13, weight: .bold))
            .foregroundColor(Color("brown"))
            .frame(width: size, height: size)
            .background(Color("dark baige"))
            .clipShape(Circle())
    }
}

// MARK: - Shared Stat Header (Total Invested / Total Gain)
struct StatHeaderView: View {
    let totalInvested: Double
    let totalGain: Double

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Total invested")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color("brown").opacity(0.4))
                Text("\(Int(totalInvested).formatted()) SAR")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color("purple"))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("Total gain")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color("brown").opacity(0.4))
                Text("\(totalGain >= 0 ? "+" : "")\(Int(totalGain).formatted()) SAR")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color("dark green"))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 16)
    }
}
