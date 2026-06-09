//
//  TransactionType.swift
//  Macro
//
//  Created by Ghala Alsalem on 02/06/2026.
//


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
//
// Each row is stamped with the Apple `userID` of the account that created it,
// so signing into a different account shows a different portfolio, and a guest
// (empty userID) sees nothing.
@Model
final class Transaction {
    var id: UUID
    var symbol: String
    var typeRaw: String          // stored as String; use `type` to read/write
    var quantity: Int
    var pricePerShare: Double
    var date: Date

    // The Apple user ID that owns this transaction. Empty string = guest /
    // unowned. Defaulted so older rows created before this field still decode.
    var userID: String = ""

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
         realizedGain: Double = 0.0,
         userID: String = "") {
        self.id = UUID()
        self.symbol = symbol
        self.typeRaw = type.rawValue
        self.quantity = quantity
        self.pricePerShare = pricePerShare
        self.date = date
        self.realizedGain = realizedGain
        self.userID = userID
    }
}

// MARK: - PortfolioMath
// The single source of truth for turning a list of Transaction events into
// holdings, average cost, cost basis, and realized gains.
// No view should reimplement this logic — call these helpers instead.
//
// Each method has a user-scoped overload that takes a `userID` and only counts
// rows owned by that user. Passing an empty userID (a guest) yields an empty
// portfolio: 0 positions, 0 cost basis, 0 realized gain.
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

    // MARK: - User scoping

    /// Returns only the transactions owned by `userID`. An empty userID (guest)
    /// always returns an empty array, which is what makes a signed-out app
    /// read entirely as zero.
    static func scoped(_ transactions: [Transaction], to userID: String) -> [Transaction] {
        guard !userID.isEmpty else { return [] }
        return transactions.filter { $0.userID == userID }
    }

    // MARK: - Core (operate on a pre-filtered list)

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

    // MARK: - User-scoped overloads (call these from views)

    static func allPositions(from transactions: [Transaction], userID: String) -> [Position] {
        allPositions(from: scoped(transactions, to: userID))
    }

    static func totalRealizedGain(from transactions: [Transaction], userID: String) -> Double {
        totalRealizedGain(from: scoped(transactions, to: userID))
    }

    static func totalCostBasis(from transactions: [Transaction], userID: String) -> Double {
        totalCostBasis(from: scoped(transactions, to: userID))
    }
}

// MARK: - Money formatting helper
// Avoids the "-0" / "+0" problem: values that round to zero show as plain "0"
// with no sign. Otherwise shows the sign for non-zero values.
enum Money {
    /// Formats a SAR amount with no decimals, fixing the -0/+0 sign issue.
    static func sar(_ value: Double, showPlus: Bool = true) -> String {
        let rounded = (value).rounded()
        if rounded == 0 { return "0" }            // never "-0" or "+0"
        let sign = rounded > 0 ? (showPlus ? "+" : "") : "-"
        return "\(sign)\(Int(abs(rounded)))"
    }

    /// Formats a percentage, fixing the -0.0/+0.0 sign issue.
    static func percent(_ value: Double) -> String {
        let rounded = (value * 10).rounded() / 10
        if rounded == 0 { return "0.0%" }
        let sign = rounded > 0 ? "+" : "-"
        return String(format: "%@%.1f%%", sign, abs(rounded))
    }
}
