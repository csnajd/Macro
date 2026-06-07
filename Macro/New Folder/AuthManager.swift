//
//  AuthManager.swift
//  Macro
//
//  Created by Ghala Alsalem on 04/06/2026.
//


import SwiftUI
import AuthenticationServices
import Observation

// MARK: - Auth Manager
// Tracks whether the user has signed in with Apple. The Apple user ID is
// persisted so sign-in survives app restarts. Guests (who tapped "Get
// started") can browse everything but must sign in to add stocks.
@Observable
@MainActor
final class AuthManager {

    /// The stable Apple user identifier, or nil if browsing as a guest.
    var appleUserID: String? {
        didSet {
            UserDefaults.standard.set(appleUserID, forKey: "appleUserID")
        }
    }

    var isSignedIn: Bool { appleUserID != nil }

    init() {
        self.appleUserID = UserDefaults.standard.string(forKey: "appleUserID")
    }

    /// Called from a successful Sign in with Apple authorization.
    func completeSignIn(_ authorization: ASAuthorization) {
        if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
            appleUserID = credential.user
        }
    }

    func signOut() {
        appleUserID = nil
    }

    #if DEBUG
    /// Development-only stand-in for Sign in with Apple, because the real
    /// capability requires a paid Apple Developer account. Marks the user as
    /// signed in with a fake ID. Excluded from release builds entirely.
    func mockSignInForTesting() {
        appleUserID = "debug-test-user"
    }
    #endif
}

// MARK: - Sign-In Required Sheet
// Shown when a guest tries to add a stock. Explains why, offers the real
// Sign in with Apple button, or lets them back out with "Not now".
struct SignInRequiredSheet: View {
    @Environment(AuthManager.self) private var auth
    @Environment(LanguageManager.self) private var lang
    @Environment(\.dismiss) private var dismiss
    @State private var signInFailed = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.checkmark")
                .font(.system(size: 44))
                .foregroundColor(Color("light brown"))
                .padding(.top, 32)

            Text(lang.t("signin.requiredTitle"))
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color("brown"))
                .multilineTextAlignment(.center)

            Text(lang.t("signin.requiredBody"))
                .font(.system(size: 14))
                .foregroundColor(Color("brown").opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                switch result {
                case .success(let authorization):
                    auth.completeSignIn(authorization)
                    dismiss()
                case .failure(let error):
                    print("❌ Sign in with Apple failed: \(error.localizedDescription)")
                    signInFailed = true
                }
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 54)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 24)

            if signInFailed {
                Text(lang.t("signin.failed"))
                    .font(.system(size: 13))
                    .foregroundColor(Color("burgindy"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            #if DEBUG
            // Dev-only: the real Apple flow needs a paid developer account.
            Button {
                auth.mockSignInForTesting()
                dismiss()
            } label: {
                Text("Sign in (test mode)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color("light brown"))
            }
            #endif

            Button {
                dismiss()
            } label: {
                Text(lang.t("signin.notNow"))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color("brown").opacity(0.6))
            }
            .padding(.bottom, 28)
        }
        .background(Color("baige").ignoresSafeArea())
        .presentationDetents([.medium])
    }
}
