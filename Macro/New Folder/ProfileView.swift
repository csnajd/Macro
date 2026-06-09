//
//  ProfileView.swift
//  Macro
//

import SwiftUI
import SwiftData
import AuthenticationServices
import PhotosUI

struct ProfileView: View {
    @Environment(AppStore.self) private var store
    @Environment(LanguageManager.self) private var lang
    @Environment(\.dismiss) private var dismiss
    @Query private var transactions: [Transaction]

    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var profileImageData: Data? = nil
    @State private var signInError = false
    @State private var showSignOutConfirm = false

    private var savedImageData: Data? {
        UserDefaults.standard.data(forKey: "profileImageData")
    }

    private var unrealizedGain: Double {
        let positions = PortfolioMath.allPositions(from: transactions)
        return positions.reduce(0.0) { sum, pos in
            let price = store.livePrice(for: pos.symbol) ?? pos.averageBuyPrice
            return sum + (price * Double(pos.quantity)) - pos.costBasis
        }
    }

    private var totalBricks: Int {
        store.totalDynamicBricks(unrealizedGain: unrealizedGain)
    }

    private var totalInvested: Double {
        PortfolioMath.totalCostBasis(from: transactions)
    }

    private var totalGain: Double {
        unrealizedGain + PortfolioMath.totalRealizedGain(from: transactions)
    }

    private var currentStageNumber: Int {
        HouseStages.currentStage(forBricks: totalBricks).stageNumber
    }

    var body: some View {
        ZStack {
            Color("baige").ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {

                    // MARK: - Header
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 26))
                                .foregroundColor(Color("brown").opacity(0.3))
                        }
                        Spacer()
                        Text("Profile")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(Color("brown"))
                        Spacer()
                        Color.clear.frame(width: 26, height: 26)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 28)

                    // MARK: - Avatar
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        ZStack(alignment: .bottomTrailing) {
                            Group {
                                if let data = profileImageData ?? savedImageData,
                                   let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                } else {
                                    ZStack {
                                        Color("dark baige")
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 44))
                                            .foregroundColor(Color("brown").opacity(0.35))
                                    }
                                }
                            }
                            .frame(width: 96, height: 96)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color("white"), lineWidth: 3))
                            .shadow(color: Color("brown").opacity(0.1), radius: 8, x: 0, y: 4)

                            // Camera badge
                            ZStack {
                                Circle()
                                    .fill(Color("light brown"))
                                    .frame(width: 28, height: 28)
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                            }
                            .offset(x: 2, y: 2)
                        }
                    }
                    .onChange(of: selectedPhoto) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                profileImageData = data
                                UserDefaults.standard.set(data, forKey: "profileImageData")
                            }
                        }
                    }
                    .onAppear {
                        profileImageData = savedImageData
                    }

                    // Name
                    Text(store.isSignedIn && !store.userName.isEmpty ? store.userName : "Guest")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color("brown"))
                        .padding(.top, 14)

                    if store.isSignedIn {
                        Label("Signed in with Apple", systemImage: "applelogo")
                            .font(.system(size: 12))
                            .foregroundColor(Color("brown").opacity(0.45))
                            .padding(.top, 4)
                    } else {
                        Text("Browsing as guest")
                            .font(.system(size: 12))
                            .foregroundColor(Color("brown").opacity(0.4))
                            .padding(.top, 4)
                    }

                    // MARK: - Stats Row
                    HStack(spacing: 0) {
                        ProfileStatPill(
                            label: "Bricks",
                            value: "\(totalBricks)",
                            icon: "brick"
                        )
                        Rectangle()
                            .fill(Color("dark baige").opacity(0.4))
                            .frame(width: 1, height: 36)
                        ProfileStatPill(
                            label: "Invested",
                            value: "\(Int(totalInvested))",
                            suffix: "SAR"
                        )
                        Rectangle()
                            .fill(Color("dark baige").opacity(0.4))
                            .frame(width: 1, height: 36)
                        ProfileStatPill(
                            label: "Gain",
                            value: Money.sar(totalGain),
                            suffix: "SAR",
                            valueColor: totalGain >= 0 ? Color("dark green") : Color("burgindy")
                        )
                    }
                    .padding(.vertical, 18)
                    .background(Color("white"))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .padding(.horizontal, 24)
                    .padding(.top, 28)

                    // MARK: - Current Estate Level
                    VStack(spacing: 14) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Your Estate")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Color("brown"))
                                Text("Level \(currentStageNumber) of \(HouseStages.all.count)")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color("brown").opacity(0.5))
                            }
                            Spacer()
                            HStack(spacing: 4) {
                                Image("brick")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 14, height: 14)
                                Text("\(totalBricks) bricks")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Color("light brown"))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color("light brown").opacity(0.12))
                            .clipShape(Capsule())
                        }

                        Image("level\(currentStageNumber)")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .frame(height: 160)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(16)
                    .background(Color("white"))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .padding(.horizontal, 24)
                    .padding(.top, 14)

                    // MARK: - Sign In / Sign Out Card
                    VStack(spacing: 14) {
                        if store.isSignedIn {
                            // Signed in state
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color("dark green").opacity(0.1))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(Color("dark green"))
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Account linked")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Color("brown"))
                                    Text("Your progress is saved to your Apple ID")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color("brown").opacity(0.5))
                                }
                                Spacer()
                            }

                            Button {
                                showSignOutConfirm = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                    Text("Sign Out")
                                }
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color("burgindy"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color("burgindy").opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }

                        } else {
                            // Guest state
                            VStack(spacing: 10) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color("light brown").opacity(0.12))
                                            .frame(width: 40, height: 40)
                                        Image(systemName: "person.badge.plus")
                                            .font(.system(size: 18))
                                            .foregroundColor(Color("light brown"))
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Sign in to add stocks")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(Color("brown"))
                                        Text("Browsing is open — adding stocks needs an account")
                                            .font(.system(size: 12))
                                            .foregroundColor(Color("brown").opacity(0.5))
                                    }
                                    Spacer()
                                }

                                SignInWithAppleButton(.signIn) { request in
                                    request.requestedScopes = [.fullName, .email]
                                } onCompletion: { result in
                                    switch result {
                                    case .success(let auth):
                                        guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else { return }
                                        store.signIn(
                                            appleUserID: credential.user,
                                            name: credential.fullName?.givenName ?? ""
                                        )
                                        signInError = false
                                    case .failure:
                                        signInError = true
                                    }
                                }
                                .signInWithAppleButtonStyle(.black)
                                .frame(height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                                if signInError {
                                    Text(lang.t("signin.failed"))
                                        .font(.system(size: 12))
                                        .foregroundColor(Color("burgindy"))
                                        .multilineTextAlignment(.center)
                                }
                            }
                        }
                    }
                    .padding(16)
                    .background(Color("white"))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .padding(.horizontal, 24)
                    .padding(.top, 14)

                    // MARK: - App Info
                    VStack(spacing: 0) {
                        ProfileInfoRow(icon: "lock.shield", label: "All data stored on your device only")
                        Divider().padding(.leading, 54)
                        ProfileInfoRow(icon: "chart.bar", label: "For tracking and education only")
                        Divider().padding(.leading, 54)
                        ProfileInfoRow(icon: "building.columns", label: "Saudi Tadawul + Global markets")
                        Divider().padding(.leading, 54)
                        ProfileInfoRow(icon: "bell", label: "Optional local notifications only")
                    }
                    .background(Color("white"))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .padding(.horizontal, 24)
                    .padding(.top, 14)
                    .padding(.bottom, 48)
                }
            }
        }
        .confirmationDialog("Sign out?", isPresented: $showSignOutConfirm, titleVisibility: .visible) {
            Button("Sign Out", role: .destructive) {
                store.signOut()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your data stays on this device. You can sign back in anytime.")
        }
    }
}

// MARK: - Subcomponents

private struct ProfileStatPill: View {
    let label: String
    let value: String
    var suffix: String? = nil
    var icon: String? = nil
    var valueColor: Color = Color("brown")

    var body: some View {
        VStack(spacing: 5) {
            if let iconName = icon {
                HStack(spacing: 4) {
                    Image(iconName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                    Text(value)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(valueColor)
                }
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(valueColor)
                    if let s = suffix {
                        Text(s)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(valueColor.opacity(0.6))
                    }
                }
            }
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(Color("brown").opacity(0.45))
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ProfileInfoRow: View {
    let icon: String
    let label: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color("light brown").opacity(0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(Color("light brown"))
            }
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(Color("brown").opacity(0.75))
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
