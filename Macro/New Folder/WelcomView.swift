//
//   WelcomView.swift
//   Macro
//
//   Created by Ghida Abdullah al-Mughamer on 25/05/2026.
//


import SwiftUI
import AuthenticationServices

public struct WelcomView: View {
    @Binding var hasStartedApp: Bool
    @Environment(LanguageManager.self) private var lang
    @Environment(AuthManager.self) private var auth
    @State private var signInFailed = false
    // PDPL consent: shown once before first entry, persisted across launches.
    @AppStorage("privacyAccepted") private var privacyAccepted = false
    @State private var showConsent = false
    @State private var animateSlogan = false

    public init(hasStartedApp: Binding<Bool>) {
        self._hasStartedApp = hasStartedApp
    }

    public var body: some View {
        ZStack {
            Color("baige").ignoresSafeArea()

            VStack {
                // Language selector — now functional. Tapping a side switches
                // the app language instantly; the active one is emphasized.
                HStack {
                    Spacer()
                    HStack(spacing: 4) {
                        Button {
                            lang.current = .english
                        } label: {
                            Text("En")
                                .font(.system(size: 18, weight: lang.current == .english ? .bold : .medium))
                                .foregroundColor(Color("brown").opacity(lang.current == .english ? 1.0 : 0.5))
                        }
                        Text("/")
                            .font(.system(size: 16))
                            .foregroundColor(Color("brown").opacity(0.3))
                        Button {
                            lang.current = .arabic
                        } label: {
                            Text("ع")
                                .font(.system(size: 18, weight: lang.current == .arabic ? .bold : .regular))
                                .foregroundColor(Color("brown").opacity(lang.current == .arabic ? 1.0 : 0.5))
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color("white").opacity(0.5))
                    .clipShape(Capsule())
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Spacer()

                // Brand block
                VStack(spacing: 24) {
                    Image("brick")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180, height: 180)
                        .shadow(color: Color("brown").opacity(0.1), radius: 10, x: 0, y: 5)

                    Text("Rassah")
                        .font(.system(size: 50, weight: .bold, design: .serif))
                        .foregroundColor(Color("light brown"))
                        .padding(.top, 8)

                    Text(lang.t("welcome.tagline"))
                        .font(.system(size: 24, weight: .medium))
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color("light brown"))
                        .lineSpacing(6)
                        .opacity(animateSlogan ? 1.0 : 0.0)
                        .offset(y: animateSlogan ? 0 : 8)
                        .animation(.easeOut(duration: 0.7).delay(0.1), value: animateSlogan)
                }

                Spacer(minLength: 20)

                // Auth buttons
                VStack(spacing: 16) {
                    Button(action: {
                        if privacyAccepted { hasStartedApp = true } else { showConsent = true }
                    }) {
                        Text(lang.t("welcome.getStarted"))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color("light brown"))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: Color("brown").opacity(0.18), radius: 8, x: 0, y: 4)
                    }

                    // Real Sign in with Apple. On success the user lands in the
                    // app fully signed in (no add-stock gate).
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        switch result {
                        case .success(let authorization):
                            auth.completeSignIn(authorization)
                            if privacyAccepted { hasStartedApp = true } else { showConsent = true }
                        case .failure(let error):
                            print("❌ Sign in with Apple failed: \(error.localizedDescription)")
                            signInFailed = true
                        }
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 58)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: Color("brown").opacity(0.08), radius: 8, x: 0, y: 4)

                    if signInFailed {
                        Text(lang.t("signin.failed"))
                            .font(.system(size: 13))
                            .foregroundColor(Color("burgindy"))
                            .multilineTextAlignment(.center)
                    }

                    #if DEBUG
                    // Dev-only: the real Apple flow needs a paid developer account.
                    Button {
                        auth.mockSignInForTesting()
                        if privacyAccepted { hasStartedApp = true } else { showConsent = true }
                    } label: {
                        Text("Sign in (test mode)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color("brown").opacity(0.55))
                    }
                    #endif
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 75)
            }
        }
        .onAppear { animateSlogan = true }
    }
}

#Preview {
    WelcomView(hasStartedApp: .constant(false))
        .environment(AppStore())
        .environment(LanguageManager())
        .environment(AuthManager())
}
