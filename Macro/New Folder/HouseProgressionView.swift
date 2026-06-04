//
//  HouseProgressionView.swift
//  Macro
//
//  Created by Ghida Abdullah al-Mughamer on 03/06/2026.
//

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
    @Environment(GhinahAppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    private let sarPerBrick: Double = 3.4
    
    // Interactive View State Variables
    @State private var selectedLevelTab: Int = 1
    @State private var isPlacingBrickAnimation: Bool = false
    
    private let stages = [
        NajdiBuildingStage(level: 1, title: "Desert Groundwork", description: "Plotting structural lines and clearing core sands.", bricksRequired: 0),
        NajdiBuildingStage(level: 2, title: "Lower Archways & Framing", description: "Raising core perimeter blocks and pointed archways.", bricksRequired: 50),
        NajdiBuildingStage(level: 3, title: "Upper Facade & Frieze", description: "Sculpting triangular patterns and gateway towers.", bricksRequired: 150),
        NajdiBuildingStage(level: 4, title: "Completed Heritage Estate", description: "Polished multi-tier structural palace complete.", bricksRequired: 350)
    ]
    
    private var totalBricks: Int {
        store.dynamicallyEarnedBricks
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
        let totalBricksNeeded = next.bricksRequired - currentMilestone
        let bricksEarned = totalBricks - currentMilestone
        
        // ✅ CRITICAL RUNTIME SAFEGUARD: Explicitly handle zero denominators to prevent division crashes
        guard totalBricksNeeded > 0 else { return 0.0 }
        
        // Clamp metrics cleanly between 0.0 and 1.0 bounds
        let unclampedPercentage = CGFloat(bricksEarned) / CGFloat(totalBricksNeeded)
        return max(0.0, min(1.0, unclampedPercentage))
    }

    var body: some View {
        ZStack {
            Color(red: 245/255, green: 242/255, blue: 235/255)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Navigation Top Header
                HStack {
                    Button { dismiss() } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Dashboard")
                        }
                        .foregroundColor(Color("brown"))
                    }
                    Spacer()
                    
                    Text("Estate Build Lab")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(store.isDevTestingActive ? Color("dark green") : Color("brown"))
                        .onTapGesture(count: 3) {
                            withAnimation(.spring()) {
                                store.isDevTestingActive.toggle()
                                if store.isDevTestingActive {
                                    store.injectedMockBricks = Double(store.dynamicallyEarnedBricks)
                                }
                            }
                        }
                    
                    Spacer()
                    Text("🧱 \(totalBricks)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color("brown"))
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                // MARK: - Sandbox Simulation Controller Slider
                if store.isDevTestingActive {
                    let mockBrickBinding = Binding<Double>(
                        get: { store.injectedMockBricks },
                        set: { store.injectedMockBricks = $0 }
                    )
                    
                    VStack(spacing: 8) {
                        HStack {
                            Text("🛠️ Global Logic Injector")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color("dark green"))
                            Spacer()
                            Text("Injecting: \(Int(store.injectedMockBricks)) Bricks (≈ \(String(format: "%.1f", store.netPortfolioGains)) SAR)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color("brown"))
                        }
                        Slider(value: mockBrickBinding, in: 0...400, step: 1)
                            .tint(Color("dark green"))
                    }
                    .padding(14)
                    .background(Color("white"))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {
                        
                        // MARK: - Live Construction Site Viewport Card
                        let selectedStageDetails = stages.first(where: { $0.level == selectedLevelTab }) ?? stages[0]
                        let isLevelFullyUnlocked = totalBricks >= selectedStageDetails.bricksRequired
                        let isLevelCurrentlyBuilding = currentActiveStage.level == selectedLevelTab && nextStageTarget != nil
                        
                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 28)
                                .fill(Color("white"))
                                .shadow(color: Color("brown").opacity(0.06), radius: 16, x: 0, y: 8)
                            
                            // Procedural building canvas layout segment
                            NajdiCanvasView(bricksEarned: totalBricks)
                                .frame(height: 360)
                                .clipShape(RoundedRectangle(cornerRadius: 28))
                                .saturation(isLevelFullyUnlocked ? 1.0 : 0.2)
                                .blur(radius: isLevelFullyUnlocked ? 0.0 : (isLevelCurrentlyBuilding ? 1.0 : 5.0))
                            
                            // Blueprint drafting layout mask overlay
                            if !isLevelFullyUnlocked && !isLevelCurrentlyBuilding {
                                ZStack {
                                    Color.black.opacity(0.35)
                                    VStack(spacing: 6) {
                                        Image(systemName: "lock.shield.fill")
                                            .font(.system(size: 26))
                                            .foregroundColor(.white)
                                        Text("BLUEPRINT LOCKED")
                                            .font(.system(size: 11, weight: .bold))
                                            .tracking(1.5)
                                            .foregroundColor(.white)
                                    }
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 28))
                            }
                            
                            // Interactive structural building overlay footer drawer
                            if isLevelCurrentlyBuilding {
                                VStack {
                                    Spacer()
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack(spacing: 6) {
                                                ProgressView().tint(.white)
                                                Text("MASONS BUILDING...")
                                                    .font(.system(size: 11, weight: .bold))
                                                    .foregroundColor(.white)
                                            }
                                            Text("\(Int(levelProgressPercentage * 100))% Layered")
                                                .font(.system(size: 16, weight: .black))
                                                .foregroundColor(.white)
                                        }
                                        Spacer()
                                        Image(systemName: "hammer.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(.white)
                                            .rotationEffect(.degrees(isPlacingBrickAnimation ? -20 : 20))
                                            .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isPlacingBrickAnimation)
                                            .onAppear { isPlacingBrickAnimation = true }
                                    }
                                    .padding(20)
                                    .background(.ultraThinMaterial)
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 28))
                            }
                            
                            // Active Phase Tags
                            HStack {
                                Text("PHASE 0\(selectedLevelTab)")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                    .background(isLevelFullyUnlocked ? Color("dark green") : (isLevelCurrentlyBuilding ? Color("light brown") : Color.gray))
                                    .clipShape(Capsule())
                                Spacer()
                            }
                            .padding(16)
                        }
                        .frame(height: 360)
                        .padding(.top, 10)
                        
                        // MARK: - Level Tab Selector Buttons
                        HStack(spacing: 12) {
                            ForEach(stages) { stage in
                                let isActiveSelection = selectedLevelTab == stage.level
                                let isUnlocked = totalBricks >= stage.bricksRequired
                                
                                Button { selectedLevelTab = stage.level } label: {
                                    VStack(spacing: 4) {
                                        Text("Lvl \(stage.level)")
                                            .font(.system(size: 14, weight: .black))
                                        Image(systemName: isUnlocked ? "checkmark.circle.fill" : "lock.fill")
                                            .font(.system(size: 11))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(isActiveSelection ? Color("brown") : Color("white"))
                                    .foregroundColor(isActiveSelection ? .white : (isUnlocked ? Color("brown") : .gray.opacity(0.5)))
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                }
                            }
                        }
                        
                        // MARK: - Upgrade Progress XP Tracking Gauge
                        VStack(spacing: 14) {
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
                                            RoundedRectangle(cornerRadius: 100).fill(Color("dark baige").opacity(0.2))
                                            RoundedRectangle(cornerRadius: 100)
                                                .fill(LinearGradient(colors: [Color("light brown"), Color("brown")], startPoint: .leading, endPoint: .trailing))
                                                .frame(width: geo.size.width * levelProgressPercentage)
                                        }
                                    }
                                    .frame(height: 12)
                                }
                                
                                let blocksRemaining = next.bricksRequired - totalBricks
                                let capitalRequired = Double(blocksRemaining) * sarPerBrick
                                Text(store.isDevTestingActive ? "Sandbox override actively controlling layout logic components." : "Earn +\(String(format: "%.2f", capitalRequired)) SAR more in profits to automatically generate the next \(blocksRemaining) bricks.")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                Text("👑 Maximum Simulation Level Reached!")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Color("dark green"))
                            }
                        }
                        .padding(20)
                        .background(Color("white"))
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        
                        // MARK: - Phase Description Metadata Card
                        VStack(alignment: .leading, spacing: 6) {
                            Text(selectedStageDetails.title.uppercased())
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(Color("light brown"))
                            Text(selectedStageDetails.description)
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .background(Color("white"))
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationBarHidden(true)
    }
}
