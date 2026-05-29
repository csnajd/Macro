//
//  API.swift
//  Macro
//
//  Created by Ghida Abdullah al-Mughamer on 30/11/1447 AH.
//

import Foundation
import Observation

// MARK: - Core Models
struct Stock: Identifiable, Codable {
    var id: String { symbol }
    let symbol: String
    let name: String
    let price: Double
    let change: Double
    let changePercent: Double
    let currency: String?
    let category: StockCategory

    enum CodingKeys: String, CodingKey {
        case symbol
        case name          = "longName"
        case price         = "regularMarketPrice"
        case change        = "regularMarketChange"
        case changePercent = "regularMarketChangePercent"
        case currency
    }

    init(from decoder: Decoder) throws {
        let container      = try decoder.container(keyedBy: CodingKeys.self)
        self.symbol        = try container.decode(String.self, forKey: .symbol)
        self.name          = try container.decodeIfPresent(String.self, forKey: .name)          ?? "Global Stock"
        self.price         = try container.decodeIfPresent(Double.self, forKey: .price)         ?? 0.0
        self.change        = try container.decodeIfPresent(Double.self, forKey: .change)        ?? 0.0
        self.changePercent = try container.decodeIfPresent(Double.self, forKey: .changePercent) ?? 0.0
        self.currency      = try container.decodeIfPresent(String.self, forKey: .currency)      ?? "SAR"
        self.category      = symbol.hasSuffix(".SR") ? .saudi : .global
    }

    init(symbol: String, name: String, price: Double, change: Double,
         changePercent: Double, currency: String, category: StockCategory) {
        self.symbol        = symbol
        self.name          = name
        self.price         = price
        self.change        = change
        self.changePercent = changePercent
        self.currency      = currency
        self.category      = category
    }
}

enum StockCategory: String, CaseIterable, Codable {
    case popular = "Popular"
    case saudi   = "Saudi Market"
    case banking = "Banking"
    case energy  = "Energy"
    case global  = "Global"
}

// MARK: - Yahoo Finance Response Shapes
struct YahooSearchResponse: Codable { let quotes: [SearchQuote] }

struct SearchQuote: Identifiable, Codable {
    var id: String { symbol }
    let symbol: String
    let shortname: String?
    let longname: String?
}

struct YahooQuoteResponse: Codable { let quoteResponse: QuoteResult }
struct QuoteResult:        Codable { let result: [Stock]? }

// MARK: - Automated AppStore Engine
@Observable
@MainActor
final class AppStore {

    // PERFECTED: Initialized as an empty collection array to allow full choice control
    var portfolio: [Stock] = []

    var searchText:    String        = ""
    var searchResults: [SearchQuote] = []

    // MARK: Computed Metrics (Derived directly from live picked stocks)
    var totalInvested: Double { portfolio.reduce(0) { $0 + $1.price  } }
    var totalGain:     Double { portfolio.reduce(0) { $0 + $1.change } }

    // MARK: Yahoo Search Vector Engine
    func performSearch(query: String) async {
        guard query.trimmingCharacters(in: .whitespacesAndNewlines).count > 1 else {
            self.searchResults = []
            return
        }

        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let raw = "https://query1.finance.yahoo.com/v1/finance/search?q=\(cleanQuery)"
        guard let encoded = raw.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encoded) else { return }

        do {
            var req = URLRequest(url: url)
            req.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
                         forHTTPHeaderField: "User-Agent")
            let (data, _) = try await URLSession.shared.data(for: req)
            self.searchResults = try JSONDecoder().decode(YahooSearchResponse.self, from: data).quotes
        } catch {
            print("Search engine down-stream network failure: \(error)")
        }
    }

    // MARK: Add Stock from Yahoo Quote Engine
    func addStock(symbol: String) async {
        let clean = symbol.trimmingCharacters(in: .whitespacesAndNewlines)
        self.searchText    = ""
        self.searchResults = []

        guard let url = URL(string: "https://query1.finance.yahoo.com/v7/finance/quote?symbols=\(clean)") else { return }

        do {
            var req = URLRequest(url: url)
            req.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
                         forHTTPHeaderField: "User-Agent")
            let (data, _) = try await URLSession.shared.data(for: req)
            let decoded   = try JSONDecoder().decode(YahooQuoteResponse.self, from: data)
            if let newStock = decoded.quoteResponse.result?.first {
                if !portfolio.contains(where: { $0.symbol == newStock.symbol }) {
                    portfolio.append(newStock)
                }
            }
        } catch {
            print("Stock detail extraction engine pipeline failure: \(error)")
        }
    }
}
