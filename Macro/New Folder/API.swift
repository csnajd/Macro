//
//  API.swift
//  Macro
//
//  Created by Ghida Abdullah al-Mughamer on 30/11/1447 AH.
//

import Foundation
import Observation

// MARK: - Core Structural Objects
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

// MARK: - Yahoo Finance Response Components
struct YahooSearchResponse: Codable { let quotes: [SearchQuote] }

struct SearchQuote: Identifiable, Codable {
    var id: String { symbol }
    let symbol: String
    let shortname: String?
    let longname: String?
}

struct YahooQuoteResponse: Codable { let quoteResponse: QuoteResult }
struct QuoteResult:        Codable { let result: [Stock]? }

// Chart endpoint (v8) response — used for reliable live prices.
struct YahooChartResponse: Codable {
    let chart: ChartContainer
}
struct ChartContainer: Codable {
    let result: [ChartResult]?
}
struct ChartResult: Codable {
    let meta: ChartMeta
}
struct ChartMeta: Codable {
    let symbol: String?
    let currency: String?
    let regularMarketPrice: Double?
    let chartPreviousClose: Double?
    let previousClose: Double?
}

// MARK: - AppStore State Node
@Observable
@MainActor
final class AppStore {
    // `portfolio` is now a LIVE-PRICE CACHE keyed by symbol — it holds the
    // latest Yahoo quote for each symbol the user currently holds. It is NOT
    // the user's holdings (those live in SwiftData as Transaction rows).
    var portfolio:     [Stock]       = []
    var searchText:    String        = ""
    var searchResults: [SearchQuote] = []

    // Tracks base stock counts for application persistence state if needed
    var stocksAddedCount: Int {
        get { UserDefaults.standard.integer(forKey: "stocksAddedCount") }
        set { UserDefaults.standard.set(newValue, forKey: "stocksAddedCount") }
    }

    // Bricks are permanent. Once earned from a profitable sale they are stored
    // on the device and never recalculated, so market fluctuations can never
    // take them away.
    var brickCount: Int {
        get { UserDefaults.standard.integer(forKey: "lifetimeBricks") }
        set { UserDefaults.standard.set(newValue, forKey: "lifetimeBricks") }
    }

    // 1 brick per 3.4 SAR of REALIZED profit (profit locked in by selling).
    private let sarPerBrick: Double = 3.4

    /// Call this once when a sell locks in a profit. Only adds bricks —
    /// never removes them. A loss-making sale awards zero, never negative.
    func awardBricks(fromRealizedGain gain: Double) {
        guard gain > 0 else { return }
        let earned = Int(gain / sarPerBrick)
        guard earned > 0 else { return }
        brickCount += earned
    }

    // MARK: - Live Price Refresh

    /// Fetches live quotes for every held symbol and refreshes `portfolio`.
    /// Call this from a view's .task, passing the symbols the user holds.
    func refreshLivePrices(for symbols: [String]) async {
        let unique = Array(Set(symbols)).filter { !$0.isEmpty }
        guard !unique.isEmpty else {
            portfolio = []
            return
        }

        var fresh: [Stock] = []
        for symbol in unique {
            if let live = await fetchStockFromYahoo(symbol: symbol) {
                fresh.append(live)
            }
            // If a fetch fails we omit it; the view falls back to cost basis
            // for that holding, never showing a scary 0 SAR.
        }
        portfolio = fresh
    }

    /// Live price for a symbol if we have a valid one cached, else nil.
    func livePrice(for symbol: String) -> Double? {
        guard let p = portfolio.first(where: { $0.symbol == symbol })?.price,
              p > 0 else { return nil }
        return p
    }

    // MARK: - Readable Names
    public func getReadableName(for symbol: String) -> String {
        return localStockName(for: symbol)
    }

    // MARK: - Local Repository Map Dictionaries
    private let localStockNames: [String: String] = [
        "2010.SR": "SABIC", "2222.SR": "Saudi Aramco", "7010.SR": "STC",
        "1120.SR": "Al Rajhi Bank", "1180.SR": "SNB (AlAhli)", "1150.SR": "Alinma Bank",
        "5110.SR": "Saudi Electricity", "2082.SR": "ACWA Power", "4290.SR": "Aldrees",
        "2280.SR": "Almarai", "4003.SR": "Extra", "1050.SR": "Saudi Fransi",
        "1060.SR": "SAIB", "1020.SR": "Bank AlBilad", "1030.SR": "Saudi Investment",
        "2020.SR": "SABIC Agri-Nutrients", "2310.SR": "Sipchem", "2060.SR": "Tasnee",
        "4300.SR": "Dar Al Arkan", "4090.SR": "Taiba Investments", "4150.SR": "Arriyadh Development",
        "4250.SR": "Jabal Omar", "4190.SR": "Jarir Marketing", "4005.SR": "Cenomi Care",
        "4200.SR": "Aldrees Transport", "6001.SR": "Halwani Bros", "4040.SR": "SAPTCO",
        "4009.SR": "Saudi German Health", "4013.SR": "Dr. Sulaiman AlHabib",
        "8010.SR": "Tawuniya", "8020.SR": "Bupa Arabia"
    ]

    private let localStocks: [SearchQuote] = [
        SearchQuote(symbol: "2010.SR", shortname: "SABIC",      longname: "Saudi Basic Industries"),
        SearchQuote(symbol: "2222.SR", shortname: "Aramco",     longname: "Saudi Aramco"),
        SearchQuote(symbol: "7010.SR", shortname: "STC",        longname: "Saudi Telecom Company"),
        SearchQuote(symbol: "1120.SR", shortname: "Al Rajhi",   longname: "Al Rajhi Bank"),
        SearchQuote(symbol: "1180.SR", shortname: "SNB",        longname: "Saudi National Bank"),
        SearchQuote(symbol: "1150.SR", shortname: "Alinma",     longname: "Alinma Bank"),
        SearchQuote(symbol: "5110.SR", shortname: "SEC",        longname: "Saudi Electricity Company"),
        SearchQuote(symbol: "2082.SR", shortname: "ACWA Power", longname: "ACWA Power Company"),
        SearchQuote(symbol: "4290.SR", shortname: "Aldrees",    longname: "Aldrees Petroleum"),
        SearchQuote(symbol: "2280.SR", shortname: "Almarai",    longname: "Almarai Company"),
        SearchQuote(symbol: "4003.SR", shortname: "Extra",      longname: "United Electronics (Extra)"),
        SearchQuote(symbol: "1050.SR", shortname: "Saudi Fransi", longname: "Banque Saudi Fransi"),
        SearchQuote(symbol: "1060.SR", shortname: "SAIB",       longname: "Saudi Investment Bank"),
        SearchQuote(symbol: "1020.SR", shortname: "Bank AlBilad", longname: "Bank AlBilad"),
        SearchQuote(symbol: "2020.SR", shortname: "SABIC AN",   longname: "SABIC Agri-Nutrients"),
        SearchQuote(symbol: "2310.SR", shortname: "Sipchem",    longname: "Sahara International Petrochemical"),
        SearchQuote(symbol: "2060.SR", shortname: "Tasnee",     longname: "National Industrialization"),
        SearchQuote(symbol: "4300.SR", shortname: "Dar Al Arkan", longname: "Dar Al Arkan Real Estate"),
        SearchQuote(symbol: "4250.SR", shortname: "Jabal Omar", longname: "Jabal Omar Development"),
        SearchQuote(symbol: "4190.SR", shortname: "Jarir",      longname: "Jarir Marketing"),
        SearchQuote(symbol: "4013.SR", shortname: "AlHabib",    longname: "Dr. Sulaiman AlHabib Medical"),
        SearchQuote(symbol: "8010.SR", shortname: "Tawuniya",   longname: "Tawuniya Insurance"),
        SearchQuote(symbol: "8020.SR", shortname: "Bupa",       longname: "Bupa Arabia")
    ]

    private func localStockName(for symbol: String) -> String {
        localStockNames[symbol] ?? symbol
    }

    // MARK: - Search Logic
    // Local-only, ranked. Requires 2+ characters (a single letter matches too
    // much to be useful). Results that START with the query rank above results
    // that merely contain it, so typing "ra" surfaces "Al Rajhi" first.
    func performSearch(query: String) async {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard q.count >= 2 else {
            searchResults = []
            return
        }

        // Score each stock: 2 = a field starts with the query, 1 = contains it,
        // 0 = no match. Then keep the matches, best-ranked first.
        func score(_ stock: SearchQuote) -> Int {
            let fields = [
                stock.symbol.lowercased(),
                (stock.longname ?? "").lowercased(),
                (stock.shortname ?? "").lowercased(),
                localStockName(for: stock.symbol).lowercased()
            ]
            if fields.contains(where: { $0.hasPrefix(q) }) { return 2 }
            // also treat a word-start match (e.g. "rajhi" in "Al Rajhi") as strong
            if fields.contains(where: { $0.split(separator: " ").contains { $0.hasPrefix(q) } }) { return 2 }
            if fields.contains(where: { $0.contains(q) }) { return 1 }
            return 0
        }

        searchResults = localStocks
            .map { (stock: $0, score: score($0)) }
            .filter { $0.score > 0 }
            .sorted { $0.score > $1.score }
            .map { $0.stock }
    }

    // MARK: - Add Stock Logic
    // Ensures a symbol is present in the live-price cache. Returns the live
    // (or fallback) Stock so the caller can record a buy at the right price.
    func addStock(symbol: String) async -> Stock? {
        let clean = symbol.trimmingCharacters(in: .whitespacesAndNewlines)
        searchText    = ""
        searchResults = []

        // If we already have a live quote cached, reuse it.
        if let existing = portfolio.first(where: { $0.symbol == clean }) {
            return existing
        }

        let result: Stock?
        if let liveStock = await fetchStockFromYahoo(symbol: clean) {
            portfolio.append(liveStock)
            result = liveStock
        } else {
            let fallback = Stock(
                symbol: clean,
                name: localStockName(for: clean),
                price: 0.0, change: 0.0, changePercent: 0.0,
                currency: clean.hasSuffix(".SR") ? "SAR" : "USD",
                category: clean.hasSuffix(".SR") ? .saudi : .global
            )
            portfolio.append(fallback)
            result = fallback
        }

        stocksAddedCount += 1
        return result
    }

    // MARK: - Yahoo API Native Requester
    // Uses the v8 chart endpoint, which (unlike v7/quote) doesn't require a
    // cookie/crumb and reliably returns a current price. Short timeout so a
    // dead request fails fast instead of hanging the UI.
    private func fetchStockFromYahoo(symbol: String) async -> Stock? {
        let encoded = symbol.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? symbol
        let endpoints = [
            "https://query1.finance.yahoo.com/v8/finance/chart/\(encoded)",
            "https://query2.finance.yahoo.com/v8/finance/chart/\(encoded)"
        ]
        for urlString in endpoints {
            guard let url = URL(string: urlString) else { continue }
            do {
                var req = URLRequest(url: url)
                req.timeoutInterval = 6
                req.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
                             forHTTPHeaderField: "User-Agent")
                let (data, response) = try await URLSession.shared.data(for: req)
                if let http = response as? HTTPURLResponse, http.statusCode != 200 { continue }

                let decoded = try JSONDecoder().decode(YahooChartResponse.self, from: data)
                guard let meta = decoded.chart.result?.first?.meta else { continue }

                let price = meta.regularMarketPrice ?? 0
                let prevClose = meta.chartPreviousClose ?? meta.previousClose ?? price
                let change = price - prevClose
                let changePct = prevClose > 0 ? (change / prevClose) * 100 : 0

                return Stock(
                    symbol: meta.symbol ?? symbol,
                    name: localStockName(for: symbol),
                    price: price,
                    change: change,
                    changePercent: changePct,
                    currency: meta.currency ?? (symbol.hasSuffix(".SR") ? "SAR" : "USD"),
                    category: symbol.hasSuffix(".SR") ? .saudi : .global
                )
            } catch {
                print("❌ Core fetch connection block: \(error.localizedDescription)")
            }
        }
        return nil
    }
}
