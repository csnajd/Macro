//
//  HouseProgressionView.swift
//  Macro
//
//  Created by Ghida Abdullah al-Mughamer on 01/06/2026.
//

import SwiftUI
import SwiftData

struct HouseStage: Identifiable {
    let id = UUID()
    let stageNumber: Int
    let name: String
    let description: String
    let requiredBricks: Int
    let assetName: String // Place corresponding level art assets here
}

struct HouseProgressionView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    // Historical staging timeline mapping out the construction growth milestones
    private let constructionStages = [
        HouseStage(stageNumber: 1, name: "Foundation Laying", description: "Clearing the land plotting vectors and casting raw baseline mortar.", requiredBricks: 0, assetName: "brick"),
        HouseStage(stageNumber: 2, name: "Structural Framing", description: "Erecting structural columns and boundary framing layout structures.", requiredBricks: 5, assetName: "brick"),
        HouseStage(stageNumber: 3, name: "Brick Masonry", description: "Laying exterior structural insulation envelopes and stone details.", requiredBricks: 15, assetName: "brick"),
        HouseStage(stageNumber: 4, name: "Roofing & Trim", description: "Securing environmental barriers and framing premium structural eaves.", requiredBricks: 30, assetName: "brick"),
        HouseStage(stageNumber: 5, name: "Finished Estate", description: "The architectural model is fully developed, polished, and operational.", requiredBricks: 50, assetName: "brick")
    ]
    
    private var currentActiveStage: HouseStage {
        // Matches the user's live brick gains against the nearest tier requirements
        constructionStages.last(where: { store.brickCount >= $0.requiredBricks }) ?? constructionStages[0]
    }

    var body: some View {
        ZStack {
            // Premium background canvas tint
            Color(red: 247/255, green: 246/255, blue: 242/255)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - 1. Custom Back Header Navigation
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                        }
                        .foregroundColor(Color("brown"))
                    }
                    Spacer()
                    Text("Estate Blueprint")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Color("brown"))
                    Spacer()
                    CoinBadge()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 28) {
                        
                        // MARK: - 2. Current Construction Visual Centerpiece
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color("white"))
                                    .frame(width: 180, height: 180)
                                    .shadow(color: Color("brown").opacity(0.04), radius: 12, x: 0, y: 6)
                                
                                // Displays the active graphic frame representing the current level phase
                                Image("brick")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 90, height: 90)
                            }
                            
                            VStack(spacing: 4) {
                                Text("Stage \(currentActiveStage.stageNumber): \(currentActiveStage.name)")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(Color("brown"))
                                
                                Text("Lifetime Brick Score: \(store.brickCount)")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color("light brown"))
                            }
                        }
                        .padding(.top, 12)
                        
                        // MARK: - 3. Architectural Development Milestones Pipeline Tracker
                        VStack(alignment: .leading, spacing: 0) {
                            Text("CONSTRUCTION PIPELINE")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.gray.opacity(0.7))
                                .tracking(1.0)
                                .padding(.bottom, 16)
                                .padding(.horizontal, 4)
                            
                            ForEach(0..<constructionStages.count, id: \.self) { index in
                                let stage = constructionStages[index]
                                let isUnlocked = store.brickCount >= stage.requiredBricks
                                let isCurrent = currentActiveStage.id == stage.id
                                
                                HStack(alignment: .top, spacing: 16) {
                                    // Milestone Timeline Connector Nodes
                                    VStack(spacing: 0) {
                                        Circle()
                                            .fill(isCurrent ? Color("light brown") : (isUnlocked ? Color("green") : Color.gray.opacity(0.2)))
                                            .frame(width: 14, height: 14)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color("white"), lineWidth: 2)
                                            )
                                        
                                        if index < constructionStages.count - 1 {
                                            Rectangle()
                                                .fill(isUnlocked ? Color("green").opacity(0.5) : Color.gray.opacity(0.15))
                                                .frame(width: 2, height: 50)
                                        }
                                    }
                                    
                                    // Content Card Description Layouts
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(stage.name)
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(isUnlocked ? Color("brown") : .gray.opacity(0.7))
                                        
                                        Text(stage.description)
                                            .font(.system(size: 12))
                                            .foregroundColor(.gray.opacity(0.8))
                                            .lineLimit(2)
                                            .fixedSize(horizontal: false, vertical: true)
                                        
                                        if !isUnlocked {
                                            Text("Requires \(stage.requiredBricks) Bricks")
                                                .font(.system(size: 11, weight: .semibold))
                                                .foregroundColor(Color("burgindy").opacity(0.8))
                                                .padding(.top, 2)
                                        }
                                    }
                                    .padding(.bottom, index < constructionStages.count - 1 ? 16 : 0)
                                    
                                    Spacer()
                                }
                            }
                        }
                        .padding(20)
                        .background(Color("white"))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: Color.black.opacity(0.01), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
    }
}
