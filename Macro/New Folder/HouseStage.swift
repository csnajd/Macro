//
//  HouseStage.swift
//  Macro
//

import Foundation

struct HouseStage: Identifiable {
    let id = UUID()
    let stageNumber: Int
    let nameKey: String
    let descriptionKey: String
    let requiredBricks: Int
    let assetName: String
}

enum HouseStages {
    // These thresholds match NajdiCanvasView's visual phase triggers exactly:
    // Phase 1 (base bricks) starts at 0
    // Phase 2 (double archways) unlocks at 50
    // Phase 3 (upper frieze) unlocks at 150
    // Phase 4 (complete) unlocks at 350
    static let all: [HouseStage] = [
        HouseStage(stageNumber: 1, nameKey: "stage.1.name", descriptionKey: "stage.1.desc",
                   requiredBricks: 0,   assetName: "brick"),
        HouseStage(stageNumber: 2, nameKey: "stage.2.name", descriptionKey: "stage.2.desc",
                   requiredBricks: 50,  assetName: "brick"),
        HouseStage(stageNumber: 3, nameKey: "stage.3.name", descriptionKey: "stage.3.desc",
                   requiredBricks: 150, assetName: "brick"),
        HouseStage(stageNumber: 4, nameKey: "stage.4.name", descriptionKey: "stage.4.desc",
                   requiredBricks: 350, assetName: "brick"),
    ]

    static func currentStage(forBricks bricks: Int) -> HouseStage {
        all.last(where: { bricks >= $0.requiredBricks }) ?? all[0]
    }

    static func nextStage(forBricks bricks: Int) -> HouseStage? {
        all.first(where: { bricks < $0.requiredBricks })
    }

    static func progress(forBricks bricks: Int) -> Double {
        guard let next = nextStage(forBricks: bricks) else { return 1.0 }
        let current = currentStage(forBricks: bricks)
        let span = Double(next.requiredBricks - current.requiredBricks)
        guard span > 0 else { return 1.0 }
        return min(max(Double(bricks - current.requiredBricks) / span, 0.0), 1.0)
    }

    static func bricksToNext(forBricks bricks: Int) -> Int {
        guard let next = nextStage(forBricks: bricks) else { return 0 }
        return max(next.requiredBricks - bricks, 0)
    }
}
