//
//  TransactionModel.swift
//  Macro
//
//  Created by Ghida Abdullah al-Mughamer on 25/05/2026.
//

import Foundation
import SwiftData

@Model
final class TransactionItem {
    @Attribute(.unique) var id: String
    var symbol: String
    var sharesCount: Double
    var purchasePrice: Double
    var dateAdded: Date
    
    init(symbol: String, sharesCount: Double, purchasePrice: Double, dateAdded: Date = Date()) {
        self.id = UUID().uuidString
        self.symbol = symbol.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        self.sharesCount = sharesCount
        self.purchasePrice = purchasePrice
        self.dateAdded = dateAdded
    }
}
