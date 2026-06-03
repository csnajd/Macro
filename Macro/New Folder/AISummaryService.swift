//
//  AISummaryService.swift
//  Macro
//
import Foundation
import CoreML
import Observation

// MARK: - Weekly Summary (real-data shape)
// News/market-driver fields removed — those needed a paid news feed we don't
// have. What remains is all computed from the user's real holdings + TASI.
struct WeeklySummary {
    let weekDate: Date               // raw date; view formats per language
    let totalChange: Double          // unrealized gain on current holdings
    let portfolioValue: Double       // cost basis
    let portfolioGains: Double       // sum of positive per-holding gains
    let portfolioLosses: Double      // sum of negative per-holding gains
    let netChange: Double            // == totalChange
    let weeklyChangePercent: Double  // totalChange / cost basis * 100
    let tasiChange: Double           // real TASI % from ^TASI.SR
    let marketOutperform: Double     // portfolio % − TASI %
    let sectorPerformance: [SectorPerf]
    let forwardLookKey: String       // localization key
    let nextSummaryDate: Date        // raw date; view formats per language
    let weekClassificationKey: String // localization key
    let bricksThisPeriod: Int        // bricks earned since started (or total)
    let bestStockName: String
    let worstStockName: String

    // "Since you started" tracking (from snapshots)
    let startDate: Date?             // baseline snapshot date; nil if none yet
    let sinceStartChange: Double     // current value − baseline value
    let sinceStartPercent: Double    // as % of baseline value
    // Content pieces
    let positionsPositive: Int       // how many holdings are in profit
    let positionsTotal: Int          // total holdings
    let bestContribution: Double     // best mover's gain in SAR
    let worstChangePercent: Double   // worst mover's % change
}

struct SectorPerf: Identifiable {
    let id = UUID()
    let name: String
    let changePercent: Double
    var isPositive: Bool { changePercent >= 0 }
}

@Observable
@MainActor
final class AISummaryService {

    var summary: WeeklySummary? = nil
    var isLoading: Bool = false

    private var mlModel: MLModel? = {
        guard let url = Bundle.main.url(forResource: "macro 1",
                                        withExtension: "mlmodelc") ??
                        Bundle.main.url(forResource: "macro_1",
                                        withExtension: "mlmodelc")
        else {
            print("❌ Model not found in bundle")
            return nil
        }
        do {
            return try MLModel(contentsOf: url)
        } catch {
            print("❌ CoreML load error: \(error)")
            return nil
        }
    }()

    // MARK: - Map CoreML's Arabic output back to a localization key
    private static func weekKey(forArabic text: String) -> String? {
        switch text {
        case "أسبوع استثنائي":     return "week.exceptional"
        case "أسبوع إيجابي قوي":   return "week.strongPositive"
        case "أسبوع إيجابي":       return "week.positive"
        case "أسبوع هادئ":         return "week.calm"
        case "أسبوع سلبي":         return "week.negative"
        case "أسبوع صعب":          return "week.tough"
        default:                   return nil
        }
    }

    // MARK: - Real TASI fetch (^TASI.SR) via chart endpoint
    private func fetchTASIChange() async -> Double? {
        let endpoints = [
            "https://query1.finance.yahoo.com/v8/finance/chart/%5ETASI.SR",
            "https://query2.finance.yahoo.com/v8/finance/chart/%5ETASI.SR"
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
                if let meta = decoded.chart.result?.first?.meta {
                    let price = meta.regularMarketPrice ?? 0
                    let prev = meta.chartPreviousClose ?? meta.previousClose ?? price
                    return prev > 0 ? ((price - prev) / prev) * 100 : 0
                }
            } catch {
                print("❌ TASI fetch failed: \(error.localizedDescription)")
            }
        }
        return nil
    }

    // MARK: - Generate summary from REAL holdings
    // `positions` = current holdings (from PortfolioMath).
    // `livePrices` = symbol → live price (from the store's cache).
    // `baselineValue`/`baselineBricks`/`startDate` = first snapshot, for
    //   "since you started" figures (nil/0 if no snapshot yet).
    func generateSummary(positions: [PortfolioMath.Position],
                         livePrices: [String: Double],
                         realizedThisPeriod: Double,
                         bricksEarned: Int,
                         baselineValue: Double?,
                         baselineBricks: Int,
                         startDate: Date?) async {
        guard !positions.isEmpty else {
            summary = nil
            return
        }
        isLoading = true

        // Per-holding current value, cost basis, and unrealized gain.
        var costBasis = 0.0
        var currentValue = 0.0
        var gains = 0.0
        var losses = 0.0
        var positiveCount = 0

        struct Eval { let symbol: String; let pct: Double; let gain: Double }
        var evals: [Eval] = []

        for pos in positions {
            let price = livePrices[pos.symbol] ?? pos.averageBuyPrice
            let cv = price * Double(pos.quantity)
            let cb = pos.costBasis
            let gain = cv - cb
            let pct = cb > 0 ? (gain / cb) * 100 : 0

            costBasis += cb
            currentValue += cv
            if gain >= 0 { gains += gain; positiveCount += 1 } else { losses += gain }
            evals.append(Eval(symbol: pos.symbol, pct: pct, gain: gain))
        }

        let totalChange = currentValue - costBasis
        let portfolioPct = costBasis > 0 ? (totalChange / costBasis) * 100 : 0

        let sortedByPct = evals.sorted { $0.pct > $1.pct }
        let bestStockName  = sortedByPct.first?.symbol.replacingOccurrences(of: ".SR", with: "") ?? "—"
        let worstStockName = sortedByPct.last?.symbol.replacingOccurrences(of: ".SR", with: "") ?? "—"
        let bestStockPct   = sortedByPct.first?.pct ?? 0
        let worstStockPct  = sortedByPct.last?.pct ?? 0
        let bestContribution = sortedByPct.first?.gain ?? 0

        // "Since you started" figures from the baseline snapshot.
        let sinceStartChange = baselineValue != nil ? currentValue - baselineValue! : totalChange
        let sinceStartPercent = (baselineValue ?? 0) > 0 ? (sinceStartChange / baselineValue!) * 100 : portfolioPct

        // Real sectors: group holdings by category, average their % change.
        var sectorTotals: [StockCategory: (sum: Double, count: Int)] = [:]
        for pos in positions {
            let category: StockCategory = pos.symbol.hasSuffix(".SR") ? .saudi : .global
            let price = livePrices[pos.symbol] ?? pos.averageBuyPrice
            let cb = pos.costBasis
            let pct = cb > 0 ? ((price * Double(pos.quantity) - cb) / cb) * 100 : 0
            let existing = sectorTotals[category] ?? (0, 0)
            sectorTotals[category] = (existing.sum + pct, existing.count + 1)
        }
        let sectors: [SectorPerf] = sectorTotals.map { (cat, v) in
            SectorPerf(name: cat.rawValue, changePercent: v.count > 0 ? v.sum / Double(v.count) : 0)
        }.sorted { $0.changePercent > $1.changePercent }

        // Real TASI.
        let tasiChange = await fetchTASIChange() ?? 0.0

        // CoreML week classification on real numbers (falls back to rules).
        // We emit a KEY (not display text) so the view can localize it.
        var weekClassKey: String = {
            switch portfolioPct {
            case let x where x > 4:   return "week.exceptional"
            case let x where x > 2:   return "week.strongPositive"
            case let x where x > 0.5: return "week.positive"
            case let x where x > -0.5: return "week.calm"
            case let x where x > -2:  return "week.negative"
            default:                  return "week.tough"
            }
        }()

        let bestSector  = sectors.first?.name ?? "—"
        let worstSector = sectors.last?.name ?? "—"
        let bestSectorPct  = sectors.first?.changePercent ?? 0
        let worstSectorPct = sectors.last?.changePercent ?? 0

        if let model = mlModel,
           let provider = try? MLDictionaryFeatureProvider(dictionary: [
               "change_SAR"                : MLFeatureValue(double: totalChange),
               "monthly_return_PCT"        : MLFeatureValue(double: portfolioPct),
               "best_stock_return_PCT"     : MLFeatureValue(double: bestStockPct),
               "worst_stock_return_PCT"    : MLFeatureValue(double: worstStockPct),
               "best_sector_return_PCT"    : MLFeatureValue(double: bestSectorPct),
               "weakest_sector_return_PCT" : MLFeatureValue(double: worstSectorPct),
               "best_sector"               : MLFeatureValue(string: bestSector),
               "weakest_sector"            : MLFeatureValue(string: worstSector),
               "best_stock"                : MLFeatureValue(string: bestStockName),
               "worst_stock"               : MLFeatureValue(string: worstStockName)
           ]),
           let output = try? await model.prediction(from: provider),
           let result = output.featureValue(for: "week_classification")?.stringValue {
            // Map the model's Arabic output back to one of our keys.
            weekClassKey = Self.weekKey(forArabic: result) ?? weekClassKey
        }

        // Forward-look emitted as a key; the view fills in the number.
        let forwardKey = portfolioPct >= 0 ? "summary.forwardAhead" : "summary.forwardBehind"

        // Bricks since started: current total minus the baseline's count.
        let bricksSinceStart = max(bricksEarned - baselineBricks, 0)

        self.summary = WeeklySummary(
            weekDate:            Date(),
            totalChange:         totalChange,
            portfolioValue:      costBasis,
            portfolioGains:      gains,
            portfolioLosses:     losses,
            netChange:           totalChange,
            weeklyChangePercent: portfolioPct,
            tasiChange:          tasiChange,
            marketOutperform:    portfolioPct - tasiChange,
            sectorPerformance:   sectors,
            forwardLookKey:      forwardKey,
            nextSummaryDate:     Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
            weekClassificationKey: weekClassKey,
            bricksThisPeriod:    bricksSinceStart,
            bestStockName:       bestStockName,
            worstStockName:      worstStockName,
            startDate:           startDate,
            sinceStartChange:    sinceStartChange,
            sinceStartPercent:   sinceStartPercent,
            positionsPositive:   positiveCount,
            positionsTotal:      positions.count,
            bestContribution:    bestContribution,
            worstChangePercent:  worstStockPct
        )

        self.isLoading = false
    }
}
