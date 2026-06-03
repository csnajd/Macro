//
//  HouseProgressionView.swift
//  Macro
//
//  Created by Ghida Abdullah al-Mughamer on 01/06/2026.
//

import SwiftUI
import SwiftData

struct HouseProgressionView: View {
    @Environment(AppStore.self) private var store
    @Environment(LanguageManager.self) private var lang
    @Environment(\.dismiss) private var dismiss

    // Stages now come from the shared HouseStages source (see HouseStage.swift).
    private let constructionStages = HouseStages.all

    private var currentActiveStage: HouseStage {
        HouseStages.currentStage(forBricks: store.brickCount)
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
                            Text(lang.t("house.back"))
                        }
                        .foregroundColor(Color("brown"))
                    }
                    Spacer()
                    Text(lang.t("house.blueprint"))
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

                                Image("brick")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 90, height: 90)
                            }

                            VStack(spacing: 4) {
                                Text("\(lang.t("house.stagePrefix")) \(currentActiveStage.stageNumber): \(lang.t(currentActiveStage.nameKey))")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(Color("brown"))

                                Text(String(format: lang.t("house.lifetimeScore"), store.brickCount))
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color("light brown"))
                            }
                        }
                        .padding(.top, 12)

                        // MARK: - 3. Architectural Development Milestones Pipeline Tracker
                        VStack(alignment: .leading, spacing: 0) {
                            Text(lang.t("house.pipeline"))
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
                                        Text(lang.t(stage.nameKey))
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(isUnlocked ? Color("brown") : .gray.opacity(0.7))

                                        Text(lang.t(stage.descriptionKey))
                                            .font(.system(size: 12))
                                            .foregroundColor(.gray.opacity(0.8))
                                            .lineLimit(2)
                                            .fixedSize(horizontal: false, vertical: true)

                                        if !isUnlocked {
                                            Text(String(format: lang.t("house.requiresBricks"), stage.requiredBricks))
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
