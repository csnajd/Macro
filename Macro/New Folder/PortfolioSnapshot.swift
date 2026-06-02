import Foundation
import SwiftData

// MARK: - Portfolio Snapshot
// A point-in-time record of the portfolio's total value and brick count.
// Recorded once per day when the Summary opens. The earliest snapshot is the
// baseline for all "since you started" figures — real, time-based, no faking.
@Model
final class PortfolioSnapshot {
    var date: Date
    var totalValue: Double   // current market value of holdings at snapshot time
    var brickCount: Int      // lifetime bricks at snapshot time

    init(date: Date = Date(), totalValue: Double, brickCount: Int) {
        self.date = date
        self.totalValue = totalValue
        self.brickCount = brickCount
    }
}

// MARK: - Snapshot helpers
enum SnapshotMath {
    /// Whether we already recorded a snapshot today (so we throttle to 1/day).
    static func hasSnapshotToday(_ snapshots: [PortfolioSnapshot]) -> Bool {
        let cal = Calendar.current
        return snapshots.contains { cal.isDateInToday($0.date) }
    }

    /// The earliest snapshot (the baseline). Nil if none yet.
    static func baseline(_ snapshots: [PortfolioSnapshot]) -> PortfolioSnapshot? {
        snapshots.min(by: { $0.date < $1.date })
    }
}