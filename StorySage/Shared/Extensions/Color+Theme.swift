//
//  Color+Theme.swift
//  StorySage
//
//  Created on 2025-08-03.
//

import SwiftUI

extension Color {
    // MARK: - Brand Colors
    
    static let storySagePrimary = Color(red: 0.007, green: 0.478, blue: 0.996)
    static let storySageSecondary = Color(red: 0.569, green: 0.318, blue: 0.871)
    
    // MARK: - Category Colors
    
    static let fireflyForest = Color.green
    static let rainbowRapids = Color.blue
    static let thunderMountain = Color.purple
    static let starlightMeadow = Color.yellow
    static let compassCliff = Color.orange
    
    // MARK: - Semantic Colors
    
    static let successGreen = Color(red: 0.22, green: 0.80, blue: 0.29)
    static let warningOrange = Color(red: 1.0, green: 0.62, blue: 0.0)
    static let errorRed = Color(red: 0.98, green: 0.22, blue: 0.29)
    
    // MARK: - Background Colors
    
    static let cardBackground = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    
    // MARK: - Text Colors
    
    static let primaryText = Color(.label)
    static let secondaryText = Color(.secondaryLabel)
    static let tertiaryText = Color(.tertiaryLabel)
    
    // MARK: - Grade Level Colors
    
    static func gradeColor(for level: String) -> Color {
        switch level {
        case "grade_prek":
            return .pink
        case "grade_k":
            return .blue
        case "grade_1":
            return .green
        case "grade_2":
            return .purple
        default:
            return .primary
        }
    }
}