//
//  AISummaryService.swift
//  Macro
//

import Foundation
import CoreML
import Observation

struct WeeklySummary {
    let weekLabel: String
    let totalChange: Double
    let portfolioValue: Double
    let portfolioGains: Double
    let portfolioLosses: Double
    let netChange: Double
    let weeklyChangePercent: Double
    let tasiChange: Double
    let marketOutperform: Double
    let sectorPerformance: [SectorPerf]
    let marketDriver: String
    let marketDriverDetail: String
    let sectorAlert: String?
    let sectorAlertDetail: String?
    let forwardLook: String
    let nextSummaryLabel: String
    let weekClassification: String
    let bestStockName: String
    let worstStockName: String
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

    func generateSummary(portfolio: [Stock]) async {
        guard !portfolio.isEmpty else { return }
        isLoading = true

        let totalChange   = portfolio.reduce(0) { $0 + $1.change }
        let totalValue    = portfolio.reduce(0) { $0 + $1.price }
        let monthlyReturn = totalValue > 0 ? (totalChange / totalValue) * 100 : 0

        let gains  = portfolio.filter { $0.change > 0 }.reduce(0) { $0 + $1.change }
        let losses = portfolio.filter { $0.change < 0 }.reduce(0) { $0 + $1.change }

        let sorted     = portfolio.sorted { $0.changePercent > $1.changePercent }
        let bestStock  = sorted.first
        let worstStock = sorted.last

        let bestStockName  = bestStock?.name  ?? "—"
        let worstStockName = worstStock?.name ?? "—"
        let bestSector     = bestStock?.category.rawValue  ?? "—"
        let worstSector    = worstStock?.category.rawValue ?? "—"

        let bestStockPct  = bestStock?.changePercent  ?? 0
        let worstStockPct = worstStock?.changePercent ?? 0

        let bestSectorStocks  = portfolio.filter { $0.category == bestStock?.category }
        let worstSectorStocks = portfolio.filter { $0.category == worstStock?.category }
        let bestSectorPct     = bestSectorStocks.isEmpty  ? 0.0 : bestSectorStocks.map  { $0.changePercent }.reduce(0,+) / Double(bestSectorStocks.count)
        let worstSectorPct    = worstSectorStocks.isEmpty ? 0.0 : worstSectorStocks.map { $0.changePercent }.reduce(0,+) / Double(worstSectorStocks.count)

        // ── CoreML prediction ────────────────────────────────
        var weekClass: String = {
            switch monthlyReturn {
            case let x where x > 4:  return "أسبوع استثنائي"
            case let x where x > 2:  return "أسبوع إيجابي قوي"
            case let x where x > 0.5: return "أسبوع إيجابي"
            case let x where x > -0.5: return "أسبوع هادئ"
            case let x where x > -2: return "أسبوع سلبي"
            default:                  return "أسبوع صعب"
            }
        }()

        if let model = mlModel,
           let provider = try? MLDictionaryFeatureProvider(dictionary: [
               "change_SAR"               : MLFeatureValue(double: totalChange),
               "monthly_return_PCT"        : MLFeatureValue(double: monthlyReturn),
               "best_stock_return_PCT"     : MLFeatureValue(double: bestStockPct),
               "worst_stock_return_PCT"    : MLFeatureValue(double: worstStockPct),
               "best_sector_return_PCT"    : MLFeatureValue(double: bestSectorPct),
               "weakest_sector_return_PCT" : MLFeatureValue(double: worstSectorPct),
               "best_sector"              : MLFeatureValue(string: bestSector),
               "weakest_sector"           : MLFeatureValue(string: worstSector),
               "best_stock"               : MLFeatureValue(string: bestStockName),
               "worst_stock"              : MLFeatureValue(string: worstStockName)
           ]),
           let output = try? await model.prediction(from: provider),
           let result = output.featureValue(for: "week_classification")?.stringValue {
            weekClass = result
        }

        // ── Sectors ──────────────────────────────────────────
        let sectors: [SectorPerf] = [
            SectorPerf(name: "بتروكيماويات", changePercent: bestStockPct),
            SectorPerf(name: "مصرفية",       changePercent: 2.4),
            SectorPerf(name: "طاقة",         changePercent: 1.9),
            SectorPerf(name: "اتصالات",      changePercent: worstStockPct),
            SectorPerf(name: "عقارات",       changePercent: -0.4)
        ]

        self.summary = WeeklySummary(
            weekLabel:           "المحفظة – أسبوع 3 مايو",
            totalChange:         totalChange,
            portfolioValue:      totalValue,
            portfolioGains:      gains,
            portfolioLosses:     losses,
            netChange:           totalChange,
            weeklyChangePercent: monthlyReturn,
            tasiChange:          1.8,
            marketOutperform:    monthlyReturn - 1.8,
            sectorPerformance:   sectors,
            marketDriver:        "ارتفع خام برنت 3.4٪",
            marketDriverDetail:  "أولى وأبقت على تخفيضات الإنتاج، رفع ذلك أسهم البتروكيماويات والطاقة.",
            sectorAlert:         "ضغوط على قطاع الاتصالات",
            sectorAlertDetail:   "مراجعة تسعير هيئة الاتصالات أثّرت على STC وموبايلي.",
            forwardLook:         "نتائج أرامكو للربع الأول ستصدر 6 مايو. راقب سابك عن كثب.",
            nextSummaryLabel:    "الأحد 10 مايو",
            weekClassification:  weekClass,
            bestStockName:       bestStockName,
            worstStockName:      worstStockName
        )

        self.isLoading = false
    }
}
