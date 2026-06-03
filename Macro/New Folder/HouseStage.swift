//
//  HouseStage.swift
//  Macro
//
//  Created by Ghala Alsalem on 02/06/2026.
//


import Foundation

// MARK: - House Stage (shared)
// Single source of truth for the construction stages and their brick
// thresholds. Stage names/descriptions are stored as LOCALIZATION KEYS
// (not display text) so they translate — the views look them up via
// LanguageManager. Both HouseProgressionView and AnalyticsView read these.
struct HouseStage: Identifiable {
    let id = UUID()
    let stageNumber: Int
    let nameKey: String          // localization key, e.g. "stage.1.name"
    let descriptionKey: String   // localization key, e.g. "stage.1.desc"
    let requiredBricks: Int
    let assetName: String
}

enum HouseStages {
    static let all: [HouseStage] = [
        HouseStage(stageNumber: 1, nameKey: "stage.1.name", descriptionKey: "stage.1.desc",
                   requiredBricks: 0, assetName: "brick"),
        HouseStage(stageNumber: 2, nameKey: "stage.2.name", descriptionKey: "stage.2.desc",
                   requiredBricks: 5, assetName: "brick"),
        HouseStage(stageNumber: 3, nameKey: "stage.3.name", descriptionKey: "stage.3.desc",
                   requiredBricks: 15, assetName: "brick"),
        HouseStage(stageNumber: 4, nameKey: "stage.4.name", descriptionKey: "stage.4.desc",
                   requiredBricks: 30, assetName: "brick"),
        HouseStage(stageNumber: 5, nameKey: "stage.5.name", descriptionKey: "stage.5.desc",
                   requiredBricks: 50, assetName: "brick")
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
        let done = Double(bricks - current.requiredBricks)
        return min(max(done / span, 0.0), 1.0)
    }

    static func bricksToNext(forBricks bricks: Int) -> Int {
        guard let next = nextStage(forBricks: bricks) else { return 0 }
        return max(next.requiredBricks - bricks, 0)
    }
}
