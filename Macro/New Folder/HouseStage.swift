import Foundation

// MARK: - House Stage (shared)
// Single source of truth for the construction stages and their brick
// thresholds. Both HouseProgressionView (the timeline) and AnalyticsView
// (the "next upgrade" progress panel) read from here, so thresholds are
// never duplicated or out of sync.
struct HouseStage: Identifiable {
    let id = UUID()
    let stageNumber: Int
    let name: String
    let description: String
    let requiredBricks: Int
    let assetName: String
}

enum HouseStages {
    static let all: [HouseStage] = [
        HouseStage(stageNumber: 1, name: "Foundation Laying",
                   description: "Clearing the land plotting vectors and casting raw baseline mortar.",
                   requiredBricks: 0, assetName: "brick"),
        HouseStage(stageNumber: 2, name: "Structural Framing",
                   description: "Erecting structural columns and boundary framing layout structures.",
                   requiredBricks: 5, assetName: "brick"),
        HouseStage(stageNumber: 3, name: "Brick Masonry",
                   description: "Laying exterior structural insulation envelopes and stone details.",
                   requiredBricks: 15, assetName: "brick"),
        HouseStage(stageNumber: 4, name: "Roofing & Trim",
                   description: "Securing environmental barriers and framing premium structural eaves.",
                   requiredBricks: 30, assetName: "brick"),
        HouseStage(stageNumber: 5, name: "Finished Estate",
                   description: "The architectural model is fully developed, polished, and operational.",
                   requiredBricks: 50, assetName: "brick")
    ]

    /// The highest stage the user has reached for a given brick count.
    static func currentStage(forBricks bricks: Int) -> HouseStage {
        all.last(where: { bricks >= $0.requiredBricks }) ?? all[0]
    }

    /// The next stage to unlock, or nil if already at the final stage.
    static func nextStage(forBricks bricks: Int) -> HouseStage? {
        all.first(where: { bricks < $0.requiredBricks })
    }

    /// Progress (0...1) from the current stage's threshold to the next one.
    /// Returns 1.0 when the user is at the final stage.
    static func progress(forBricks bricks: Int) -> Double {
        guard let next = nextStage(forBricks: bricks) else { return 1.0 }
        let current = currentStage(forBricks: bricks)
        let span = Double(next.requiredBricks - current.requiredBricks)
        guard span > 0 else { return 1.0 }
        let done = Double(bricks - current.requiredBricks)
        return min(max(done / span, 0.0), 1.0)
    }

    /// Bricks still needed to reach the next stage, or 0 if at the final stage.
    static func bricksToNext(forBricks bricks: Int) -> Int {
        guard let next = nextStage(forBricks: bricks) else { return 0 }
        return max(next.requiredBricks - bricks, 0)
    }
}