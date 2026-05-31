//
//  TransactionItem.swift
//  Macro
//
//  Created by Ghida Abdullah al-Mughamer on 25/05/2026.
//

import Foundation
import SwiftData

@Model
final public class TransactionItem {
    public var stockSymbol: String
    public var price: Double
    public var quantity: Int
    
    public init(stockSymbol: String, price: Double, quantity: Int) {
        self.stockSymbol = stockSymbol
        self.price = price
        self.quantity = quantity
    }
    
    public var totalCostBasis: Double { price * Double(quantity) }
    public var totalGainLoss: Double { 0.0 }
    public var percentageChange: Double { 0.0 }
}
