//
//  WelcomView.swift
//  Macro
//
//  Created by Ghida Abdullah al-Mughamer on 25/05/2026.
//

import SwiftUI

public struct WelcomView: View {
    @Binding var hasStartedApp: Bool
    @State private var animateSlogan = false
    
    public init(hasStartedApp: Binding<Bool>) {
        self._hasStartedApp = hasStartedApp
    }
    
    public var body: some View {
        ZStack {
            Color.rassahBaige
                .ignoresSafeArea()
            
            VStack {
                // MARK: - Language Context Top Selection Bar
                HStack {
                    Spacer()
                    HStack(spacing: RassahTokens.paddingXS) {
                        Text("En")
                            .font(.rassahSans(size: 20, weight: .medium))
                            .foregroundColor(.rassahBrown)
                        Text("/")
                            .font(.rassahSans(size: 18))
                            .foregroundColor(.rassahBrown.opacity(0.3))
                        Text("ع")
                            .font(.rassahSans(size: 20, weight: .regular))
                            .foregroundColor(.rassahBrown.opacity(0.5))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.rassahWhite.opacity(0.5))
                    .cornerRadius(RassahTokens.radiusCapsule)
                }
                .padding(.horizontal, RassahTokens.paddingLarge)
                .padding(.top, 16)
                
                Spacer()
                
                // MARK: - Center Branding Composition
                VStack(spacing: RassahTokens.paddingLarge) {
                    Image("brick")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .shadow(color: Color.rassahBrown.opacity(0.1), radius: 10, x: 0, y: 5)
                    
                    Text("Rassah")
                        .font(.rassahSerif(size: 50).bold())
                        .foregroundColor(.rassahLightBrown)
                        .padding(.top, 8)
                    
                    Text("Your journey starts\nwith a brick.")
                        .font(.rassahSans(size: 27, weight: .medium))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.rassahLightBrown)
                        .lineSpacing(6)
                        .opacity(animateSlogan ? 1.0 : 0.0)
                        .offset(y: animateSlogan ? 0 : 8)
                }
                
                // CHANGED: Added a minor flexible spacer here to push down slightly from the top,
                // allowing the bottom padding expansion to float the buttons upwards elegantly.
                Spacer(minLength: 20)
                
                // MARK: - Bottom Functional Authentication Arrays
                VStack(spacing: 16) {
                    Button(action: {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                            hasStartedApp = true
                        }
                    }) {
                        Text("Get started")
                            .font(.rassahSans(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.rassahLightBrown)
                            .cornerRadius(12)
                            .shadow(color: Color.rassahBrown.opacity(0.18), radius: 8, x: 0, y: 4)
                    }
                    
                    Button(action: {}) {
                        HStack(spacing: 8) {
                            Image(systemName: "apple.logo")
                                .font(.system(size: 24))
                            Text("Sign in with Apple")
                                .font(.rassahSans(size: 24, weight: .medium))
                        }
                        .foregroundColor(.rassahBrown)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.rassahWhite)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.rassahBrown.opacity(0.12), lineWidth: 1)
                        )
                        .shadow(color: Color.rassahBrown.opacity(0.08), radius: 8, x: 0, y: 4)
                    }
                }
                .padding(.horizontal, RassahTokens.paddingLarge)
                // CHANGED: Increased from 36 to 75 to elevate the entire block safely above the home indicator region.
                .padding(.bottom, 75)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.7).delay(0.1)) {
                animateSlogan = true
            }
        }
    }
}

#Preview {
    WelcomView(hasStartedApp: .constant(false))
}
