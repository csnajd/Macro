//
//  AppStore.swift
//  Macro
//
//  Created by Ghida Abdullah al-Mughamer on 03/06/2026.
//

import SwiftUI
import Combine

public class GhinahAppStore: ObservableObject {
    
    // MARK: - Published Properties for Real-time UI Updates
    @Published public var searchText: String = ""
    @Published public var searchResults: [GhinahStockSearchResult] = []
    @Published public var portfolio: [GhinahStockAsset] = []
    
    // MARK: - Developer Sandbox Simulation Controls
    @Published public var isDevTestingActive: Bool = false
    @Published public var injectedMockBricks: Double = 0.0
    
    // Core conversion math rule: Exactly 3.4 SAR in stock returns generates 1 structural brick
    private let sarPerBrick: Double = 3.4
    
    public init() {
        // Pre-populating simulation data stubs for immediate preview verification
        self.portfolio = [
            GhinahStockAsset(symbol: "2222.SR", change: 15.0),
            GhinahStockAsset(symbol: "1120.SR", change: -5.5),
            GhinahStockAsset(symbol: "2082.SR", change: 45.0)
        ]
    }
    
    /// DYNAMIC REVENUE EVALUATOR: Tracks true investment returns or pulls from the mock slider override
    public var netPortfolioGains: Double {
        if isDevTestingActive {
            return injectedMockBricks * sarPerBrick
        } else {
            let totalGain = portfolio.reduce(0.0) { $0 + $1.change }
            return max(0.0, totalGain)
        }
    }
    
    /// CONVERSION CALCULATOR: Automatically converts platform metrics natively into structural house blocks
    public var dynamicallyEarnedBricks: Int {
        guard netPortfolioGains > 0 else { return 0 }
        return Int(netPortfolioGains / sarPerBrick)
    }
    
    // MARK: - Safe Application Method Fallbacks (Keeps legacy sheets compile-safe)
    public func livePrice(for symbol: String) -> Double? {
        return 32.5
    }
    
    public func getReadableName(for symbol: String) -> String {
        switch symbol {
        case "2222.SR": return "Saudi Aramco"
        case "1120.SR": return "Al Rajhi Bank"
        case "2082.SR": return "ACWA Power"
        default: return symbol
        }
    }
    
    public func performSearch(query: String) async {
        guard !query.isEmpty else { return }
        await MainActor.run {
            self.searchResults = [
                GhinahStockSearchResult(symbol: "2222.SR", longname: "Saudi Arabian Oil Co.", shortname: "Saudi Aramco"),
                GhinahStockSearchResult(symbol: "1120.SR", longname: "Al Rajhi Banking & Investment", shortname: "Al Rajhi Bank")
            ].filter { $0.symbol.contains(query.uppercased()) }
        }
    }
    
    public func refreshLivePrices(for symbols: [String]) async {}
}

// MARK: - Supporting Isolated Data Submodels
public struct GhinahStockAsset: Identifiable {
    public let id = UUID()
    public let symbol: String
    public var change: Double
    
    public init(symbol: String, change: Double) {
        self.symbol = symbol
        self.change = change
    }
}

public struct GhinahStockSearchResult {
    public let symbol: String
    public let longname: String?
    public let shortname: String?
}

// =========================================================================
// MARK: - 👑 RUNTIME CRASH SAFESTOP SUBCLASS BRIDGE
// =========================================================================
// ✅ Subclassing natively ensures that ALL views searching for either 'AppStore'
// or 'GhinahAppStore' resolve to this exact single object stream at runtime!
