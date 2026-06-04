//
//  NajdiCanvasView.swift
//  Macro
//
//  Created by Ghida Abdullah al-Mughamer on 03/06/2026.
//

import SwiftUI

struct NajdiCanvasView: View {
    let bricksEarned: Int
    
    private let skyGradient = LinearGradient(
        colors: [Color(red: 177/255, green: 213/255, blue: 247/255), Color(red: 221/255, green: 236/255, blue: 252/255)],
        startPoint: .top, endPoint: .bottom
    )
    private let clayGradient = LinearGradient(
        colors: [Color(red: 222/255, green: 189/255, blue: 139/255), Color(red: 194/255, green: 154/255, blue: 98/255)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    private let sandColor = Color(red: 235/255, green: 212/255, blue: 176/255)
    private let shadowColor = Color(red: 143/255, green: 109/255, blue: 64/255).opacity(0.3)
    
    var body: some View {
        ZStack(alignment: .bottom) {
            skyGradient.ignoresSafeArea()
            
            // Environmental Sun Vector
            Circle()
                .fill(Color(red: 253/255, green: 241/255, blue: 203/255))
                .frame(width: 120, height: 120)
                .offset(x: 70, y: -120)
                .blur(radius: 4)
            
            DuneShape()
                .fill(sandColor.opacity(0.85))
                .frame(height: 140)
            
            HStack {
                VectorPalmTree().scaleEffect(0.75).opacity(0.4)
                Spacer()
                VectorPalmTree().scaleEffect(0.9).opacity(0.5)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 60)
            
            Rectangle()
                .fill(sandColor)
                .frame(height: 70)
            
            // MARK: - REAL-TIME PROCEDURAL BRICK BUILDER
            VStack(spacing: 4) {
                // PHASE 3: Upper Central Gateway Palace Frieze (Bricks >= 150)
                if bricksEarned >= 150 {
                    HStack(alignment: .bottom, spacing: 0) {
                        VStack(spacing: 2) {
                            ForEach(0..<3) { _ in Rectangle().fill(clayGradient).frame(width: 20, height: 8) }
                        }
                        ZStack(alignment: .bottom) {
                            UnevenRoundedRectangle(topLeadingRadius: 14, topTrailingRadius: 14)
                                .fill(clayGradient)
                                .frame(width: 90, height: 65)
                            PointedArchShape()
                                .fill(Color.black.opacity(0.65))
                                .frame(width: 30, height: 40).padding(.bottom, 4)
                        }
                        VStack(spacing: 2) {
                            ForEach(0..<3) { _ in Rectangle().fill(clayGradient).frame(width: 20, height: 8) }
                        }
                    }
                    .transition(.move(edge: .top))
                }
                
                // PHASE 2: Core Traditional Double Archway Main Foundation Walls (Bricks >= 50)
                if bricksEarned >= 50 {
                    HStack(spacing: 16) {
                        ZStack(alignment: .bottom) {
                            Rectangle().fill(clayGradient).frame(width: 100, height: 90)
                            PointedArchShape().fill(Color.black.opacity(0.75)).frame(width: 44, height: 65)
                        }
                        ZStack(alignment: .bottom) {
                            Rectangle().fill(clayGradient).frame(width: 100, height: 90)
                            PointedArchShape().fill(Color.black.opacity(0.75)).frame(width: 44, height: 65)
                        }
                    }
                    .transition(.move(edge: .bottom))
                }
                
                // PHASE 1: Real-Time Base Layer Brick Multiplier Block Accumulator Array
                HStack(spacing: 3) {
                    let blockCount = max(4, min(12, bricksEarned / 4))
                    ForEach(0..<blockCount, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(clayGradient)
                            .frame(width: 20, height: 14)
                            .shadow(color: shadowColor, radius: 2, y: 1)
                    }
                }
                .padding(.bottom, 45)
            }
            .animation(.spring(response: 0.55, dampingFraction: 0.8), value: bricksEarned)
        }
    }
}

// MARK: - Path Outlined Geometric Shapes
struct PointedArchShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.height * 0.45))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.height * 0.15))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.height * 0.45), control: CGPoint(x: rect.maxX, y: rect.height * 0.15))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct DuneShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.height * 0.5))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.height * 0.3), control: CGPoint(x: rect.width * 0.4, y: rect.height * 0.8))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct VectorPalmTree: View {
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Capsule().fill(Color(red: 112/255, green: 143/255, blue: 98/255)).frame(width: 40, height: 12).rotationEffect(.degrees(-20))
                Capsule().fill(Color(red: 99/255, green: 130/255, blue: 86/255)).frame(width: 40, height: 12).rotationEffect(.degrees(20))
                Capsule().fill(Color(red: 112/255, green: 143/255, blue: 98/255)).frame(width: 45, height: 12).rotationEffect(.degrees(-60))
                Capsule().fill(Color(red: 99/255, green: 130/255, blue: 86/255)).frame(width: 45, height: 12).rotationEffect(.degrees(60))
            }
            Rectangle().fill(Color(red: 128/255, green: 101/255, blue: 74/255)).frame(width: 6, height: 70)
        }
    }
}
