//
//  Category.swift
//  StorySage
//
//  Created on 2025-08-03.
//

import Foundation
import SwiftUI

// MARK: - Category Model

struct Category: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let color: String
    let gradeLevel: String
    let storyCount: Int
    let isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case icon
        case color
        case gradeLevel = "grade_level"
        case storyCount = "story_count"
        case isActive = "is_active"
    }
    
    var themeColor: Color {
        switch id {
        case "firefly-forest":
            return .green
        case "rainbow-rapids":
            return .blue
        case "thunder-mountain":
            return .purple
        case "starlight-meadow":
            return .yellow
        case "compass-cliff":
            return .orange
        default:
            return .primary
        }
    }
    
    var gradeLevelDisplayName: String {
        switch gradeLevel {
        case "grade_prek":
            return "Pre-K"
        case "grade_k":
            return "Kindergarten"
        case "grade_1":
            return "1st Grade"
        case "grade_2":
            return "2nd Grade"
        default:
            return gradeLevel.capitalized
        }
    }
    
    var systemImageName: String {
        switch id {
        case "firefly-forest":
            return "leaf.fill"
        case "rainbow-rapids":
            return "drop.fill"
        case "thunder-mountain":
            return "mountain.2.fill"
        case "starlight-meadow":
            return "star.fill"
        case "compass-cliff":
            return "location.fill"
        default:
            return "book.fill"
        }
    }
}

// MARK: - Grade Level

enum GradeLevel: String, CaseIterable, Codable {
    case preK = "grade_prek"
    case kindergarten = "grade_k"
    case first = "grade_1"
    case second = "grade_2"
    
    var displayName: String {
        switch self {
        case .preK:
            return "Pre-K"
        case .kindergarten:
            return "Kindergarten"
        case .first:
            return "1st Grade"
        case .second:
            return "2nd Grade"
        }
    }
    
    var ageRange: String {
        switch self {
        case .preK:
            return "Ages 3-5"
        case .kindergarten:
            return "Ages 5-6"
        case .first:
            return "Ages 6-7"
        case .second:
            return "Ages 7-8"
        }
    }
    
    var color: Color {
        switch self {
        case .preK:
            return .pink
        case .kindergarten:
            return .blue
        case .first:
            return .green
        case .second:
            return .purple
        }
    }
    
    var icon: String {
        switch self {
        case .preK:
            return "heart.fill"
        case .kindergarten:
            return "star.fill"
        case .first:
            return "leaf.fill"
        case .second:
            return "diamond.fill"
        }
    }
}

// MARK: - Sample Data

extension Category {
    static let sampleCategories = [
        Category(
            id: "firefly-forest",
            name: "Firefly Forest",
            description: "A magical forest where emotions come alive through gentle adventures with woodland friends.",
            icon: "leaf.fill",
            color: "green",
            gradeLevel: "grade_prek",
            storyCount: 11,
            isActive: true
        ),
        Category(
            id: "rainbow-rapids",
            name: "Rainbow Rapids",
            description: "Fast-flowing adventures that teach cooperation and friendship through exciting water journeys.",
            icon: "drop.fill",
            color: "blue",
            gradeLevel: "grade_prek",
            storyCount: 8,
            isActive: true
        ),
        Category(
            id: "thunder-mountain",
            name: "Thunder Mountain",
            description: "Bold adventures that build confidence and courage while exploring majestic mountain peaks.",
            icon: "mountain.2.fill",
            color: "purple",
            gradeLevel: "grade_1",
            storyCount: 12,
            isActive: true
        ),
        Category(
            id: "starlight-meadow",
            name: "Starlight Meadow",
            description: "Peaceful meadow tales that nurture kindness and sharing under the gentle glow of stars.",
            icon: "star.fill",
            color: "yellow",
            gradeLevel: "grade_k",
            storyCount: 10,
            isActive: true
        ),
        Category(
            id: "compass-cliff",
            name: "Compass Cliff",
            description: "Problem-solving adventures that develop critical thinking and decision-making skills.",
            icon: "location.fill",
            color: "orange",
            gradeLevel: "grade_2",
            storyCount: 15,
            isActive: true
        )
    ]
}