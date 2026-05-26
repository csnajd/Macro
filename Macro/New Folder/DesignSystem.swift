//
//  DesignSystem.swift
//  Macro
//
//  Created by Ghida Abdullah al-Mughamer on 25/05/2026.
//

import SwiftUI

public enum RassahTokens {
    public static let paddingXS: CGFloat = 4
    public static let paddingSmall: CGFloat = 8
    public static let paddingMedium: CGFloat = 16
    public static let paddingLarge: CGFloat = 24
    public static let paddingXL: CGFloat = 32
    
    public static let radiusSmall: CGFloat = 10
    public static let radiusCard: CGFloat = 24
    public static let radiusCapsule: CGFloat = 100
}

extension Color {
    // Exact Asset Catalog Mapping
    public static let rassahBaige = Color("white")
    public static let rassahBrown = Color("brown")
    public static let rassahBurgundy = Color("burgindy") // Matches your asset "burgindy"
    public static let rassahDarkBaige = Color("dark baige")
    public static let rassahDarkGreen = Color("dark green")
    public static let rassahGreen = Color("green")
    public static let rassahLightBrown = Color("light brown")
    public static let rassahLightGreen = Color("light green")
    public static let rassahLightPurple = Color("light purple")
    public static let rassahPurple = Color("purple")
    public static let rassahWhite = Color("white")
    
    // Aesthetic Semantic Mappings
    public static let rassahLeatherButton = Color("light brown")
    public static let rassahCardSecondary = Color("dark baige")
}

extension Font {
    public static func rassahSerif(size: CGFloat) -> Font {
        return Font.custom("DMSerifDisplay-Regular", size: size)
    }
    
    public static func rassahSans(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return Font.system(size: size, weight: weight, design: .default)
    }
}

// MARK: - Premium Tactile Shadows
struct TactileShadowModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: Color.rassahBrown.opacity(0.12), radius: 15, x: 0, y: 10)
            .shadow(color: Color.rassahBrown.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

extension View {
    public func tactileShadow() -> some View {
        self.modifier(TactileShadowModifier())
    }
}

// MARK: - Premium Button Style Definition
public struct RassahPrimaryButtonStyle: ButtonStyle {
    // Explicit public initialization clears across target scopes
    public init() {}
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.rassahSans(size: 16, weight: .semibold))
        
            .foregroundColor(.white)
        
            .padding(.vertical, 14)
        
            .padding(.horizontal, RassahTokens.paddingLarge)
        
            .frame(maxWidth: .infinity)
        
            .background(Color.rassahLightBrown)
        
            .cornerRadius(RassahTokens.radiusCapsule)
        
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
        
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == RassahPrimaryButtonStyle {
    public static var rassahPrimary: RassahPrimaryButtonStyle { RassahPrimaryButtonStyle() }
}
