//
//  WelcomView.swift
//  Macro
//

import SwiftUI
import AuthenticationServices

public struct WelcomView: View {
    let onFinish: () -> Void

    @Environment(AppStore.self) private var store
    @Environment(LanguageManager.self) private var lang

    @State private var animateSlogan = false
    @State private var signInError = false

    public var body: some View {
        ZStack {
            Color("baige").ignoresSafeArea()

            VStack {
                // Language selector
                HStack {
                    Spacer()
                    HStack(spacing: 4) {
                        Button { lang.current = .english } label: {
                            Text("En")
                                .font(.system(size: 18, weight: lang.current == .english ? .bold : .medium))
                                .foregroundColor(Color("brown").opacity(lang.current == .english ? 1.0 : 0.5))
                        }
                        Text("/")
                            .font(.system(size: 16))
                            .foregroundColor(Color("brown").opacity(0.3))
                        Button { lang.current = .arabic } label: {
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

                VStack(spacing: 14) {
                    Button {
                        onFinish()
                    } label: {
                        Text(lang.t("welcome.getStarted"))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color("light brown"))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: Color("brown").opacity(0.18), radius: 8, x: 0, y: 4)
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
                            onFinish()
                        case .failure:
                            signInError = true
                        }
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 54)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    if signInError {
                        Text(lang.t("signin.failed"))
                            .font(.system(size: 12))
                            .foregroundColor(Color("burgindy"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 75)
            }
        }
        .onAppear { animateSlogan = true }
    }
}
