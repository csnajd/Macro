import SwiftUI
import SwiftData

struct NajdiBuildingStage: Identifiable {
    let id = UUID()
    let level: Int
    let title: String
    let description: String
    let bricksRequired: Int
}

struct HouseProgressionView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Query private var transactions: [Transaction]

    private let sarPerBrick: Double = 3.4
    @State private var selectedLevelTab: Int = 1

    private let stages = [
        NajdiBuildingStage(level: 1, title: "Desert Groundwork", description: "Plotting structural lines and clearing core sands.", bricksRequired: 0),
        NajdiBuildingStage(level: 2, title: "Lower Archways & Framing", description: "Raising core perimeter blocks and pointed archways.", bricksRequired: 50),
        NajdiBuildingStage(level: 3, title: "Upper Facade & Frieze", description: "Sculpting triangular patterns and gateway towers.", bricksRequired: 150),
        NajdiBuildingStage(level: 4, title: "Completed Heritage Estate", description: "Polished multi-tier structural palace complete.", bricksRequired: 350)
    ]

    private var unrealizedGain: Double {
        let positions = PortfolioMath.allPositions(from: transactions, userID: store.currentUserID)
        return positions.reduce(0.0) { sum, pos in
            let price = store.livePrice(for: pos.symbol) ?? pos.averageBuyPrice
            return sum + (price * Double(pos.quantity)) - pos.costBasis
        }
    }

    private var totalRealizedGain: Double {
        PortfolioMath.totalRealizedGain(from: transactions, userID: store.currentUserID)
    }

    // MARK: - Combined Unified Gain Formula
    private var totalGain: Double {
        unrealizedGain + totalRealizedGain
    }

    private var totalBricks: Int {
        // FIXED: Corrected parameter label to follow totalGain formula logic
        store.totalDynamicBricks(totalGain: totalGain)
    }

    private var currentActiveStage: NajdiBuildingStage {
        stages.last(where: { totalBricks >= $0.bricksRequired }) ?? stages[0]
    }

    private var nextStageTarget: NajdiBuildingStage? {
        stages.first(where: { $0.bricksRequired > totalBricks })
    }

    private var levelProgressPercentage: CGFloat {
        guard let next = nextStageTarget else { return 1.0 }
        let currentMilestone = currentActiveStage.bricksRequired
        let totalNeeded = next.bricksRequired - currentMilestone
        guard totalNeeded > 0 else { return 0.0 }
        let earned = totalBricks - currentMilestone
        return max(0.0, min(1.0, CGFloat(earned) / CGFloat(totalNeeded)))
    }

    var body: some View {
        ZStack {
            Color(red: 245/255, green: 242/255, blue: 235/255).ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - Header
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(Color("brown").opacity(0.25))
                    }
                    Spacer()
                    Text("Estate Build Lab")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Color("brown"))
                    Spacer()
                    HStack(spacing: 4) {
                        Image("brick")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                        Text("\(totalBricks)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color("brown"))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color("light brown").opacity(0.18))
                    .clipShape(Capsule())
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 12)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        let selectedStage = stages.first(where: { $0.level == selectedLevelTab }) ?? stages[0]
                        let isUnlocked = totalBricks >= selectedStage.bricksRequired
                        let isCurrentlyBuilding = currentActiveStage.level == selectedLevelTab && nextStageTarget != nil

                        // MARK: - Image Frame Display
                        ZStack(alignment: .topLeading) {
                            Image("level\(selectedLevelTab)")
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 240)
                                .clipShape(RoundedRectangle(cornerRadius: 24))
                                .saturation(isUnlocked ? 1.0 : 0.15)
                                .blur(radius: isUnlocked ? 0 : 4)
                                .animation(.easeInOut(duration: 0.35), value: selectedLevelTab)

                            if !isUnlocked {
                                ZStack {
                                    Color.black.opacity(0.38)
                                    VStack(spacing: 8) {
                                        Image(systemName: "lock.shield.fill")
                                            .font(.system(size: 26))
                                            .foregroundColor(.white)
                                        Text("LOCKED")
                                            .font(.system(size: 12, weight: .black))
                                            .tracking(2)
                                            .foregroundColor(.white)
                                        Text("Reach \(selectedStage.bricksRequired) bricks to unlock")
                                            .font(.system(size: 11))
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 24))
                            }

                            if isCurrentlyBuilding && isUnlocked {
                                VStack {
                                    Spacer()
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack(spacing: 6) {
                                                ProgressView().tint(.white)
                                                Text("BUILDING...")
                                                    .font(.system(size: 11, weight: .bold))
                                                    .foregroundColor(.white)
                                            }
                                            Text("\(Int(levelProgressPercentage * 100))% Complete")
                                                .font(.system(size: 15, weight: .black))
                                                .foregroundColor(.white)
                                        }
                                        Spacer()
                                    }
                                    .padding(16)
                                    .background(.ultraThinMaterial)
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 24))
                            }

                            HStack {
                                Text("PHASE 0\(selectedLevelTab)")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 5)
                                    .background(isUnlocked ? Color("dark green") : (isCurrentlyBuilding ? Color("light brown") : Color.gray))
                                    .clipShape(Capsule())
                                Spacer()
                            }
                            .padding(14)
                        }
                        .frame(height: 240)

                        // MARK: - Level Tab Row
                        HStack(spacing: 10) {
                            ForEach(stages) { stage in
                                let isActive = selectedLevelTab == stage.level
                                let isTabUnlocked = totalBricks >= stage.bricksRequired
                                Button { selectedLevelTab = stage.level } label: {
                                    VStack(spacing: 4) {
                                        Text("Lvl \(stage.level)")
                                            .font(.system(size: 13, weight: .black))
                                        Image(systemName: isTabUnlocked ? "checkmark.circle.fill" : "lock.fill")
                                            .font(.system(size: 11))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(isActive ? Color("brown") : Color("white"))
                                    .foregroundColor(isActive ? .white : (isTabUnlocked ? Color("brown") : Color.gray.opacity(0.5)))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }

                        // MARK: - Progress Tracker Panel
                        VStack(spacing: 12) {
                            if let next = nextStageTarget {
                                VStack(spacing: 8) {
                                    HStack {
                                        Text("Active Structural Progress")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(Color("brown").opacity(0.8))
                                        Spacer()
                                        Text("\(totalBricks) / \(next.bricksRequired) Bricks")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(Color("brown"))
                                    }
                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 100)
                                                .fill(Color("dark baige").opacity(0.2))
                                            RoundedRectangle(cornerRadius: 100)
                                                .fill(LinearGradient(colors: [Color("light brown"), Color("brown")], startPoint: .leading, endPoint: .trailing))
                                                .frame(width: geo.size.width * levelProgressPercentage)
                                        }
                                    }
                                    .frame(height: 10)
                                }

                                let blocksRemaining = next.bricksRequired - totalBricks
                                let capitalRequired = Double(blocksRemaining) * sarPerBrick
                                Text("Earn +\(String(format: "%.2f", capitalRequired)) SAR more in profits to generate the next \(blocksRemaining) bricks.")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                HStack(spacing: 8) {
                                    Text("👑")
                                        .font(.system(size: 20))
                                    Text("Maximum Level Reached!")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(Color("dark green"))
                                }
                            }
                        }
                        .padding(18)
                        .background(Color("white"))
                        .clipShape(RoundedRectangle(cornerRadius: 20))

                        // MARK: - Structural Description Metadata
                        VStack(alignment: .leading, spacing: 6) {
                            Text(selectedStage.title.uppercased())
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(Color("light brown"))
                            Text(selectedStage.description)
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(18)
                        .background(Color("white"))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
        }
        .onAppear {
            selectedLevelTab = currentActiveStage.level
        }
    }
}
