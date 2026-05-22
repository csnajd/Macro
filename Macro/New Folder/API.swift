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
        case name = "longName"
        case price = "regularMarketPrice"
        case change = "regularMarketChange"
        case changePercent = "regularMarketChangePercent"
        case currency
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.symbol = try container.decode(String.self, forKey: .symbol)
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Global Stock"
        self.price = try container.decodeIfPresent(Double.self, forKey: .price) ?? 0.0
        self.change = try container.decodeIfPresent(Double.self, forKey: .change) ?? 0.0
        self.changePercent = try container.decodeIfPresent(Double.self, forKey: .changePercent) ?? 0.0
        self.currency = try container.decodeIfPresent(String.self, forKey: .currency) ?? "SAR"
        self.category = symbol.hasSuffix(".SR") ? .saudi : .global
    }
    
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

enum StockCategory: String, CaseIterable {
    case popular = "Popular"
    case saudi = "Saudi Market"
    case banking = "Banking"
    case energy = "Energy"
    case global = "Global"
}

// MARK: - Yahoo API Formats
struct YahooSearchResponse: Codable { let quotes: [SearchQuote] }
struct SearchQuote: Identifiable, Codable { var id: String { symbol }; let symbol: String; let shortname: String?; let longname: String? }
struct YahooQuoteResponse: Codable { let quoteResponse: QuoteResult }
struct QuoteResult: Codable { let result: [Stock]? }

// MARK: - Direct Global Engine
@Observable
class AppStore {
    var portfolio: [Stock] = [
        Stock(symbol: "SABIC.SR", name: "Saudi Basic Industries Corp", price: 4200.0, change: 92.4, changePercent: 2.3, currency: "SAR", category: .banking),
        Stock(symbol: "ARMCO.SR", name: "Saudi Arabian Oil Co", price: 3840.0, change: 68.4, changePercent: 1.8, currency: "SAR", category: .energy),
        Stock(symbol: "STC.SR", name: "Saudi Telecom Co", price: 2560.0, change: -15.2, changePercent: -0.6, currency: "SAR", category: .saudi),
        Stock(symbol: "RJHI.SR", name: "Al Rajhi Bank", price: 2240.0, change: 8.9, changePercent: 0.4, currency: "SAR", category: .banking)
    ]
    
    var searchText = ""
    var searchResults: [SearchQuote] = []
    
    var totalInvested: Double { portfolio.reduce(0) { $0 + $1.price } }
    var totalGain: Double { portfolio.reduce(0) { $0 + $1.change } }
    
    func performSearch(query: String) async {
        guard query.count > 1 else { self.searchResults = []; return }
        let urlString = "https://query1.finance.yahoo.com/v1/finance/search?q=\(query)"
        guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!) else { return }
        
        do {
            var request = URLRequest(url: url)
            request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(YahooSearchResponse.self, from: data)
            self.searchResults = response.quotes
        } catch { print("Search error: \(error)") }
    }
    
    func addStock(symbol: String) async {
        let cleanSymbol = symbol.trimmingCharacters(in: .whitespacesAndNewlines)
        self.searchText = ""
        self.searchResults = []
        
        let urlString = "https://query1.finance.yahoo.com/v7/finance/quote?symbols=\(cleanSymbol)"
        guard let url = URL(string: urlString) else { return }
        do {
            var request = URLRequest(url: url)
            request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoded = try JSONDecoder().decode(YahooQuoteResponse.self, from: data)
            if let newStock = decoded.quoteResponse.result?.first {
                if !self.portfolio.contains(where: { $0.symbol == newStock.symbol }) {
                    self.portfolio.append(newStock)
                }
            }
        } catch { print("Fetch error: \(error)") }
    }
}
