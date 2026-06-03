//
//   WelcomView.swift
//   Macro
//
//   Created by Ghida Abdullah al-Mughamer on 25/05/2026.
//
import SwiftUI

public struct WelcomView: View {
    @Binding var hasStartedApp: Bool
    @Environment(LanguageManager.self) private var lang
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
                        hasStartedApp = true
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

                    Button(action: {}) {
                        HStack(spacing: 8) {
                            Image(systemName: "apple.logo")
                                .font(.system(size: 20))
                            Text(lang.t("welcome.signInApple"))
                                .font(.system(size: 18, weight: .medium))
                        }
                        .foregroundColor(Color("brown"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color("white"))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color("brown").opacity(0.12), lineWidth: 1)
                        )
                        .shadow(color: Color("brown").opacity(0.08), radius: 8, x: 0, y: 4)
                    }
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
}
