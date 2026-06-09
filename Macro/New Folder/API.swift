//
//  API.swift
//  Macro
//
 
import Foundation
import Observation
import AuthenticationServices
import UIKit
 
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
 
    var sharesHeld: Int = 0
    var averageBuyPrice: Double = 0.0
 
    var totalCostBasis: Double { Double(sharesHeld) * averageBuyPrice }
    var totalCurrentValue: Double { Double(sharesHeld) * price }
 
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
        self.sharesHeld = 0
        self.averageBuyPrice = 0.0
    }
 
    init(symbol: String, name: String, price: Double, change: Double,
         changePercent: Double, currency: String, category: StockCategory,
         sharesHeld: Int = 0, averageBuyPrice: Double = 0.0) {
        self.symbol        = symbol
        self.name          = name
        self.price         = price
        self.change        = change
        self.changePercent = changePercent
        self.currency      = currency
        self.category      = category
        self.sharesHeld    = sharesHeld
        self.averageBuyPrice = averageBuyPrice
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
 
struct YahooChartResponse: Codable { let chart: ChartContainer }
struct ChartContainer:     Codable { let result: [ChartResult]? }
struct ChartResult:        Codable { let meta: ChartMeta }
struct ChartMeta: Codable {
    let symbol: String?
    let currency: String?
    let regularMarketPrice: Double?
    let chartPreviousClose: Double?
    let previousClose: Double?
}
 
// MARK: - AppStore
@Observable
@MainActor
final class AppStore {
    var portfolio:     [Stock]       = []
    var searchText:    String        = ""
    var searchResults: [SearchQuote] = []
 
    var isDevTestingActive: Bool = false
    var injectedMockBricks: Double = 0.0
 
    private let sarPerBrick: Double = 3.4
 
    // MARK: - Auth State (real @Observable stored properties)
    //
    // These are tracked by @Observable, so views re-render the instant they
    // change. They're loaded from UserDefaults once at init and written back
    // whenever they change. `currentUserID` is the Apple user ID and is the
    // key everything else is namespaced under.
 
    private(set) var isSignedIn: Bool
    private(set) var currentUserID: String
    private(set) var userName: String
 
    init() {
        let savedID = UserDefaults.standard.string(forKey: "appleUserID") ?? ""
        self.currentUserID = savedID
        self.isSignedIn = !savedID.isEmpty
        self.userName = savedID.isEmpty
            ? ""
            : (UserDefaults.standard.string(forKey: Self.nameKey(for: savedID)) ?? "")
    }
 
    // MARK: - Per-user UserDefaults keys
    private static func nameKey(for userID: String)   -> String { "userName_\(userID)" }
    private static func bricksKey(for userID: String) -> String { "lifetimeBricks_\(userID)" }
    private static func photoKey(for userID: String)  -> String { "profileImageData_\(userID)" }
 
    // MARK: - Sign in / out
    func signIn(appleUserID: String, name: String) {
        currentUserID = appleUserID
        isSignedIn = true
        UserDefaults.standard.set(appleUserID, forKey: "appleUserID")
 
        // Only overwrite the saved name if Apple actually gave us one this time
        // (it usually only returns the name on the very first sign-in).
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            userName = trimmed
            UserDefaults.standard.set(trimmed, forKey: Self.nameKey(for: appleUserID))
        } else {
            userName = UserDefaults.standard.string(forKey: Self.nameKey(for: appleUserID)) ?? ""
        }
    }
 
    func signOut() {
        currentUserID = ""
        isSignedIn = false
        userName = ""
        // Clear only the active-session pointer. Per-user data (bricks, name,
        // photo, transactions) stays on disk keyed by ID, so signing back into
        // the same account restores everything.
        UserDefaults.standard.removeObject(forKey: "appleUserID")
        // Clear the live in-memory price cache so a guest sees nothing.
        portfolio = []
    }
 
    func restoreSession() {
        let savedID = UserDefaults.standard.string(forKey: "appleUserID") ?? ""
        guard !savedID.isEmpty else {
            currentUserID = ""
            isSignedIn = false
            userName = ""
            return
        }
 
        // Trust the saved session immediately so the user stays signed in
        // across launches. We only sign out if Apple EXPLICITLY tells us the
        // credential was revoked - not for .notFound / .transferred, which can
        // occur on the simulator or transiently even when the session is fine.
        currentUserID = savedID
        isSignedIn = true
        userName = UserDefaults.standard.string(forKey: Self.nameKey(for: savedID)) ?? ""
 
        ASAuthorizationAppleIDProvider().getCredentialState(forUserID: savedID) { [weak self] state, _ in
            Task { @MainActor in
                guard let self else { return }
                if state == .revoked {
                    // The user revoked access in Settings -> sign them out.
                    self.signOut()
                }
                // .authorized / .notFound / .transferred -> keep them signed in.
            }
        }
    }
 
    // MARK: - Profile photo (per user)
    func profileImageData() -> Data? {
        guard !currentUserID.isEmpty else { return nil }
        return UserDefaults.standard.data(forKey: Self.photoKey(for: currentUserID))
    }
 
    func setProfileImageData(_ data: Data) {
        guard !currentUserID.isEmpty else { return }
        UserDefaults.standard.set(data, forKey: Self.photoKey(for: currentUserID))
    }
 
    // MARK: - Brick State (per user)
 
    /// Realized bricks only (locked in from sales). Never goes down. 0 for guests.
    var brickCount: Int {
        guard !currentUserID.isEmpty else { return 0 }
        return UserDefaults.standard.integer(forKey: Self.bricksKey(for: currentUserID))
    }
 
    /// Total bricks = realized (from sales) + unrealized (from current gains).
    /// One brick is earned per 3.4 SAR of gain (sarPerBrick). Returns 0 for a
    /// guest so the whole app reads as zero when signed out.
    func totalDynamicBricks(unrealizedGain: Double) -> Int {
        if isDevTestingActive { return Int(injectedMockBricks) }
        guard isSignedIn else { return 0 }
        let unrealizedBricks = unrealizedGain > 0 ? Int(unrealizedGain / sarPerBrick) : 0
        return brickCount + unrealizedBricks
    }
 
    /// Award bricks from a realized sale gain. Bricks are permanent once awarded.
    func awardBricks(fromRealizedGain gain: Double) {
        guard isSignedIn, !currentUserID.isEmpty, gain > 0 else { return }
        let earned = Int(gain / sarPerBrick)
        guard earned > 0 else { return }
        let key = Self.bricksKey(for: currentUserID)
        UserDefaults.standard.set(brickCount + earned, forKey: key)
    }
 
    // Legacy alias kept so any older view still referencing it compiles.
    var dynamicallyEarnedBricks: Int { brickCount }
 
    // MARK: - Live Price Refresh
    func refreshLivePrices(for symbols: [String]) async {
        let unique = Array(Set(symbols)).filter { !$0.isEmpty }
        guard !unique.isEmpty else { portfolio = []; return }
 
        var fresh: [Stock] = []
        for symbol in unique {
            if var live = await fetchStockFromYahoo(symbol: symbol) {
                if let existing = portfolio.first(where: { $0.symbol == symbol }) {
                    live.sharesHeld = existing.sharesHeld
                    live.averageBuyPrice = existing.averageBuyPrice
                }
                fresh.append(live)
            }
        }
        portfolio = fresh
    }
 
    func livePrice(for symbol: String) -> Double? {
        guard let p = portfolio.first(where: { $0.symbol == symbol })?.price, p > 0 else { return nil }
        return p
    }
 
    // MARK: - Readable Names
    public func getReadableName(for symbol: String) -> String {
        localStockName(for: symbol)
    }
 
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
        SearchQuote(symbol: "2010.SR", shortname: "SABIC",        longname: "Saudi Basic Industries"),
        SearchQuote(symbol: "2222.SR", shortname: "Aramco",       longname: "Saudi Aramco"),
        SearchQuote(symbol: "7010.SR", shortname: "STC",          longname: "Saudi Telecom Company"),
        SearchQuote(symbol: "1120.SR", shortname: "Al Rajhi",     longname: "Al Rajhi Bank"),
        SearchQuote(symbol: "1180.SR", shortname: "SNB",          longname: "Saudi National Bank"),
        SearchQuote(symbol: "1150.SR", shortname: "Alinma",       longname: "Alinma Bank"),
        SearchQuote(symbol: "5110.SR", shortname: "SEC",          longname: "Saudi Electricity Company"),
        SearchQuote(symbol: "2082.SR", shortname: "ACWA Power",   longname: "ACWA Power Company"),
        SearchQuote(symbol: "4290.SR", shortname: "Aldrees",      longname: "Aldrees Petroleum"),
        SearchQuote(symbol: "2280.SR", shortname: "Almarai",      longname: "Almarai Company"),
        SearchQuote(symbol: "4003.SR", shortname: "Extra",        longname: "United Electronics (Extra)"),
        SearchQuote(symbol: "1050.SR", shortname: "Saudi Fransi", longname: "Banque Saudi Fransi"),
        SearchQuote(symbol: "1060.SR", shortname: "SAIB",         longname: "Saudi Investment Bank"),
        SearchQuote(symbol: "1020.SR", shortname: "Bank AlBilad", longname: "Bank AlBilad"),
        SearchQuote(symbol: "2020.SR", shortname: "SABIC AN",     longname: "SABIC Agri-Nutrients"),
        SearchQuote(symbol: "2310.SR", shortname: "Sipchem",      longname: "Sahara International Petrochemical"),
        SearchQuote(symbol: "2060.SR", shortname: "Tasnee",       longname: "National Industrialization"),
        SearchQuote(symbol: "4300.SR", shortname: "Dar Al Arkan", longname: "Dar Al Arkan Real Estate"),
        SearchQuote(symbol: "4250.SR", shortname: "Jabal Omar",   longname: "Jabal Omar Development"),
        SearchQuote(symbol: "4190.SR", shortname: "Jarir",        longname: "Jarir Marketing"),
        SearchQuote(symbol: "4013.SR", shortname: "AlHabib",      longname: "Dr. Sulaiman AlHabib Medical"),
        SearchQuote(symbol: "8010.SR", shortname: "Tawuniya",     longname: "Tawuniya Insurance"),
        SearchQuote(symbol: "8020.SR", shortname: "Bupa",         longname: "Bupa Arabia")
    ]
 
    private func localStockName(for symbol: String) -> String {
        localStockNames[symbol] ?? symbol
    }
 
    // MARK: - Search
    func performSearch(query: String) async {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard q.count >= 2 else { searchResults = []; return }
 
        func score(_ stock: SearchQuote) -> Int {
            let fields = [
                stock.symbol.lowercased(),
                (stock.longname ?? "").lowercased(),
                (stock.shortname ?? "").lowercased(),
                localStockName(for: stock.symbol).lowercased()
            ]
            if fields.contains(where: { $0.hasPrefix(q) }) { return 2 }
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
 
    // MARK: - Add Stock
    func addStock(symbol: String) async -> Stock? {
        let clean = symbol.trimmingCharacters(in: .whitespacesAndNewlines)
        searchText    = ""
        searchResults = []
 
        if let existing = portfolio.first(where: { $0.symbol == clean }) { return existing }
 
        if let liveStock = await fetchStockFromYahoo(symbol: clean) {
            portfolio.append(liveStock)
            return liveStock
        }
 
        let fallback = Stock(
            symbol: clean,
            name: localStockName(for: clean),
            price: 0.0, change: 0.0, changePercent: 0.0,
            currency: clean.hasSuffix(".SR") ? "SAR" : "USD",
            category: clean.hasSuffix(".SR") ? .saudi : .global
        )
        portfolio.append(fallback)
        return fallback
    }
 
    // MARK: - Yahoo Fetch
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
                let price    = meta.regularMarketPrice ?? 0
                let prevClose = meta.chartPreviousClose ?? meta.previousClose ?? price
                let change   = price - prevClose
                let changePct = prevClose > 0 ? (change / prevClose) * 100 : 0
                return Stock(
                    symbol: meta.symbol ?? symbol,
                    name: localStockName(for: symbol),
                    price: price, change: change, changePercent: changePct,
                    currency: meta.currency ?? (symbol.hasSuffix(".SR") ? "SAR" : "USD"),
                    category: symbol.hasSuffix(".SR") ? .saudi : .global
                )
            } catch {
                print("Fetch error: \(error.localizedDescription)")
            }
        }
        return nil
    }
}
