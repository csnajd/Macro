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

    // Explicit structural initializer required to map local fallback objects smoothly
    init(symbol: String, name: String, price: Double, change: Double, changePercent: Double, currency: String, category: StockCategory) {
        self.symbol = symbol
        self.name = name
        self.price = price
        self.change = change
        self.changePercent = changePercent
        self.currency = currency
        self.category = category
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
    var portfolio: [Stock] = []
    var searchText:    String        = ""
    var searchResults: [SearchQuote] = []

    var totalInvested: Double { portfolio.reduce(0) { $0 + $1.price  } }
    var totalGain:     Double { portfolio.reduce(0) { $0 + $1.change } }

    // MARK: Local Lookup Dictionaries
    private let localStockNames: [String: String] = [
        "2010.SR": "SABIC",
        "2222.SR": "Saudi Aramco",
        "7010.SR": "STC",
        "1120.SR": "Al Rajhi Bank",
        "1180.SR": "SNB (AlAhli)",
        "1150.SR": "Alinma Bank",
        "5110.SR": "Saudi Electricity",
        "2082.SR": "ACWA Power",
        "4290.SR": "Aldrees",
        "2280.SR": "Almarai",
        "4003.SR": "Extra",
        "1050.SR": "Saudi Fransi"
    ]

    private let localStocks: [SearchQuote] = [
        SearchQuote(symbol: "2010.SR", shortname: "SABIC",          longname: "Saudi Basic Industries"),
        SearchQuote(symbol: "2222.SR", shortname: "Aramco",         longname: "Saudi Aramco"),
        SearchQuote(symbol: "7010.SR", shortname: "STC",            longname: "Saudi Telecom Company"),
        SearchQuote(symbol: "1120.SR", shortname: "Al Rajhi",       longname: "Al Rajhi Bank"),
        SearchQuote(symbol: "1180.SR", shortname: "SNB",            longname: "Saudi National Bank"),
        SearchQuote(symbol: "1150.SR", shortname: "Alinma",         longname: "Alinma Bank"),
        SearchQuote(symbol: "5110.SR", shortname: "SEC",            longname: "Saudi Electricity Company"),
        SearchQuote(symbol: "2082.SR", shortname: "ACWA Power",     longname: "ACWA Power Company"),
        SearchQuote(symbol: "4290.SR", shortname: "Aldrees",        longname: "Aldrees Petroleum"),
        SearchQuote(symbol: "2280.SR", shortname: "Almarai",        longname: "Almarai Company")
    ]

    private func localStockName(for symbol: String) -> String {
        localStockNames[symbol] ?? symbol
    }

    // MARK: Search with Local Hybrid Fallback
    func performSearch(query: String) async {
        guard query.trimmingCharacters(in: .whitespacesAndNewlines).count > 1 else {
            self.searchResults = []
            return
        }
        
        let cleanQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let endpoints = [
            "https://query1.finance.yahoo.com/v1/finance/search?q=\(cleanQuery)",
            "https://query2.finance.yahoo.com/v1/finance/search?q=\(cleanQuery)"
        ]
        
        for urlString in endpoints {
            guard let url = URL(string: urlString) else { continue }
            do {
                var req = URLRequest(url: url)
                req.timeoutInterval = 8
                req.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
                
                let (data, _) = try await URLSession.shared.data(for: req)
                let results = try JSONDecoder().decode(YahooSearchResponse.self, from: data).quotes
                self.searchResults = results
                return // Found matching live metrics, drop execution loop
            } catch {
                print("❌ Search failed loop shortcut: \(error.localizedDescription)")
            }
        }
        
        // Local Fallback Interceptor Node
        self.searchResults = localStocks.filter {
            $0.symbol.contains(query.uppercased()) ||
            ($0.longname?.lowercased().contains(query.lowercased()) ?? false)
        }
    }

    // MARK: Add Stock Engine with Hybrid Local Fallback
    func addStock(symbol: String) async -> Stock? {
        let clean = symbol.trimmingCharacters(in: .whitespacesAndNewlines)
        self.searchText    = ""
        self.searchResults = []

        // Avoid adding duplicate tracks to active memory
        guard !portfolio.contains(where: { $0.symbol == clean }) else {
            print("Already in portfolio: \(clean)")
            return portfolio.first(where: { $0.symbol == clean })
        }

        // Try live network parsing layer
        if let liveStock = await fetchStockFromYahoo(symbol: clean) {
            portfolio.append(liveStock)
            print("✅ Live stock added: \(clean)")
            return liveStock
        }

        // Offline / Rate-Limited Local Fallback Struct Generator
        let fallback = Stock(
            symbol: clean,
            name: localStockName(for: clean),
            price: 0.0,
            change: 0.0,
            changePercent: 0.0,
            currency: clean.hasSuffix(".SR") ? "SAR" : "USD",
            category: clean.hasSuffix(".SR") ? .saudi : .global
        )
        
        portfolio.append(fallback)
        print("⚠️ Fallback stock added: \(clean)")
        return fallback
    }

    // MARK: Shared Network Fetch Engine Helper Tuple
    private func fetchStockFromYahoo(symbol: String) async -> Stock? {
        let endpoints = [
            "https://query1.finance.yahoo.com/v7/finance/quote?symbols=\(symbol)",
            "https://query2.finance.yahoo.com/v7/finance/quote?symbols=\(symbol)"
        ]
        
        for urlString in endpoints {
            guard let url = URL(string: urlString) else { continue }
            do {
                var req = URLRequest(url: url)
                req.timeoutInterval = 8
                
                // Emulates clear chrome signatures to prevent 401 response blocks
                req.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
                req.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
                
                let (data, response) = try await URLSession.shared.data(for: req)
                
                if let http = response as? HTTPURLResponse {
                    print("HTTP \(http.statusCode) — \(urlString)")
                    guard http.statusCode == 200 else { continue }
                }
                
                let decoded = try JSONDecoder().decode(YahooQuoteResponse.self, from: data)
                if let stock = decoded.quoteResponse.result?.first {
                    return stock
                }
            } catch {
                print("❌ Network node parsing error on \(urlString): \(error.localizedDescription)")
            }
        }
        return nil
    }
}
