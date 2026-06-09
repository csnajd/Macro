import SwiftUI
import SwiftData

// MARK: - Reusable Coin Badge
struct CoinBadge: View {
    @Environment(AppStore.self) private var store
    @Query private var transactions: [Transaction]

    private var totalGain: Double {
        let positions = PortfolioMath.allPositions(from: transactions, userID: store.currentUserID)
        
        let unrealized = positions.reduce(0.0) { sum, pos in
            let price = store.livePrice(for: pos.symbol) ?? pos.averageBuyPrice
            return sum + (price * Double(pos.quantity)) - pos.costBasis
        }
        
        let realized = PortfolioMath.totalRealizedGain(from: transactions, userID: store.currentUserID)
        
        return unrealized + realized
    }

    var body: some View {
        HStack(spacing: 6) {
            Image("brick")
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
            Text("\(store.totalDynamicBricks(totalGain: totalGain))")
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

// MARK: - Shared Stat Header
struct StatHeaderView: View {
    let totalInvested: Double
    let totalGain: Double
    @Environment(LanguageManager.self) private var lang

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(lang.t("stat.totalInvested"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color("brown").opacity(0.4))
                Text("\(Int(totalInvested).formatted()) \(lang.t("unit.sar"))")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color("purple"))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(lang.t("stat.totalGain"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color("brown").opacity(0.4))
                Text("\(Money.sar(totalGain)) \(lang.t("unit.sar"))")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(totalGain < 0 ? Color("burgindy") : Color("dark green"))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 16)
    }
}
