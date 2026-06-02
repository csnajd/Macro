import Foundation
import SwiftData

// MARK: - Transaction Type
// A buy adds shares; a sell removes shares and may realize a gain.
enum TransactionType: String, Codable {
    case buy
    case sell
}

// MARK: - Transaction (Event Log)
// Every buy and every sell is stored as its own row.
// Current holdings are computed by summing these events (see PortfolioMath).
// This keeps full transaction history available for free later.
@Model
final class Transaction {
    var id: UUID
    var symbol: String
    var typeRaw: String          // stored as String; use `type` to read/write
    var quantity: Int
    var pricePerShare: Double
    var date: Date

    // For SELL rows only: the profit locked in by this sale, frozen at sell-time.
    // Computed once against the average cost basis at the moment of sale, then
    // never recalculated — this is what makes bricks "only go up".
    // For BUY rows this stays 0.
    var realizedGain: Double

    var type: TransactionType {
        get { TransactionType(rawValue: typeRaw) ?? .buy }
        set { typeRaw = newValue.rawValue }
    }

    init(symbol: String,
         type: TransactionType,
         quantity: Int,
         pricePerShare: Double,
         date: Date = Date(),
         realizedGain: Double = 0.0) {
        self.id = UUID()
        self.symbol = symbol
        self.typeRaw = type.rawValue
        self.quantity = quantity
        self.pricePerShare = pricePerShare
        self.date = date
        self.realizedGain = realizedGain
    }
}

// MARK: - PortfolioMath
// The single source of truth for turning a list of Transaction events into
// holdings, average cost, cost basis, and realized gains.
// No view should reimplement this logic — call these helpers instead.
enum PortfolioMath {

    /// Snapshot of a single stock's position derived from its transactions.
    struct Position: Identifiable {
        var id: String { symbol }
        let symbol: String
        let quantity: Int            // shares currently held (buys - sells)
        let averageBuyPrice: Double  // average cost of shares still held
        let realizedGain: Double     // total profit locked in from past sells

        var costBasis: Double { averageBuyPrice * Double(quantity) }
        var isHeld: Bool { quantity > 0 }
    }

    /// Computes the current position for one symbol from its transactions,
    /// processed in date order using the AVERAGE COST method.
    ///
    /// On a sell, realized gain = (sellPrice - averageBuyPrice) * quantitySold.
    /// The average buy price is unaffected by sells (average-cost behavior).
    static func position(for symbol: String, from transactions: [Transaction]) -> Position {
        let ordered = transactions
            .filter { $0.symbol == symbol }
            .sorted { $0.date < $1.date }

        var heldQuantity = 0
        var totalCost = 0.0          // running cost of currently-held shares
        var realized = 0.0

        for tx in ordered {
            switch tx.type {
            case .buy:
                heldQuantity += tx.quantity
                totalCost += tx.pricePerShare * Double(tx.quantity)

            case .sell:
                let avg = heldQuantity > 0 ? totalCost / Double(heldQuantity) : 0
                let sellQty = min(tx.quantity, heldQuantity) // never sell more than held
                realized += (tx.pricePerShare - avg) * Double(sellQty)
                // remove sold shares from the cost pool at average cost
                totalCost -= avg * Double(sellQty)
                heldQuantity -= sellQty
            }
        }

        let avgPrice = heldQuantity > 0 ? totalCost / Double(heldQuantity) : 0
        return Position(symbol: symbol,
                        quantity: heldQuantity,
                        averageBuyPrice: avgPrice,
                        realizedGain: realized)
    }

    /// All currently-held positions (quantity > 0) across every symbol.
    static func allPositions(from transactions: [Transaction]) -> [Position] {
        let symbols = Set(transactions.map { $0.symbol })
        return symbols
            .map { position(for: $0, from: transactions) }
            .filter { $0.isHeld }
            .sorted { $0.symbol < $1.symbol }
    }

    /// Total realized gain across the whole portfolio (includes sold-out positions).
    static func totalRealizedGain(from transactions: [Transaction]) -> Double {
        let symbols = Set(transactions.map { $0.symbol })
        return symbols.reduce(0.0) { $0 + position(for: $1, from: transactions).realizedGain }
    }

    /// Total cost basis of shares currently held.
    static func totalCostBasis(from transactions: [Transaction]) -> Double {
        allPositions(from: transactions).reduce(0.0) { $0 + $1.costBasis }
    }
}