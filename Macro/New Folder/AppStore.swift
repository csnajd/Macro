//
//  AppStore.swift
//  Macro
//
//  Created by Ghida Abdullah al-Mughamer on 03/06/2026.
//

import SwiftUI
import Observation

@Observable
public class GhinahAppStore {
    public var searchText: String = ""
    public var searchResults: [GhinahStockSearchResult] = []
    public var portfolio: [GhinahStockAsset] = []
    
    public var isDevTestingActive: Bool = false
    public var injectedMockBricks: Double = 0.0
    
    private let sarPerBrick: Double = 3.4
    
    public init() {
        self.portfolio = [
            GhinahStockAsset(symbol: "2222.SR", change: 15.0),
            GhinahStockAsset(symbol: "1120.SR", change: -5.5),
            GhinahStockAsset(symbol: "2082.SR", change: 45.0)
        ]
    }
    
    public var netPortfolioGains: Double {
        if isDevTestingActive {
            return injectedMockBricks * sarPerBrick
        } else {
            let totalGain = portfolio.reduce(0.0) { $0 + $1.change }
            return max(0.0, totalGain)
        }
    }
    
    public var dynamicallyEarnedBricks: Int {
        get {
            guard netPortfolioGains > 0 else { return 0 }
            return Int(netPortfolioGains / sarPerBrick)
        }
    }
    
    public func livePrice(for symbol: String) -> Double? { return 32.5 }
    public func getReadableName(for symbol: String) -> String { return symbol }
    public func performSearch(query: String) async {}
    public func refreshLivePrices(for symbols: [String]) async {}
}

public struct GhinahStockAsset: Identifiable {
    public let id = UUID()
    public let symbol: String
    public var change: Double
}

public struct GhinahStockSearchResult {
    public let symbol: String
    public let longname: String?
    public let shortname: String?
}
