//
//  User.swift
//  StorySage
//
//  Created on 2025-08-03.
//

import Foundation

// MARK: - User Model

struct User: Codable, Identifiable {
    let id: String
    let name: String
    let age: Int?
    let gradeLevel: String?
    let preferences: UserPreferences
    let progress: UserProgress
    let createdAt: String
    let lastActiveAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case age
        case gradeLevel = "grade_level"
        case preferences
        case progress
        case createdAt = "created_at"
        case lastActiveAt = "last_active_at"
    }
    
    var gradeLevelDisplayName: String? {
        guard let gradeLevel = gradeLevel else { return nil }
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
}

// MARK: - User Preferences

struct UserPreferences: Codable {
    let autoPlay: Bool
    let downloadOverWiFi: Bool
    let playbackSpeed: PlaybackSpeed
    let notificationsEnabled: Bool
    let favoriteCategories: [String]
    
    enum CodingKeys: String, CodingKey {
        case autoPlay = "auto_play"
        case downloadOverWiFi = "download_over_wifi"
        case playbackSpeed = "playback_speed"
        case notificationsEnabled = "notifications_enabled"
        case favoriteCategories = "favorite_categories"
    }
}

// MARK: - Playback Speed

enum PlaybackSpeed: String, Codable, CaseIterable {
    case slow = "0.75"
    case normal = "1.0"
    case fast = "1.25"
    case faster = "1.5"
    
    var displayName: String {
        switch self {
        case .slow:
            return "Slow (0.75x)"
        case .normal:
            return "Normal (1x)"
        case .fast:
            return "Fast (1.25x)"
        case .faster:
            return "Faster (1.5x)"
        }
    }
    
    var value: Float {
        return Float(self.rawValue) ?? 1.0
    }
}

// MARK: - User Progress

struct UserProgress: Codable {
    let totalStoriesListened: Int
    let totalListeningTime: Int // in seconds
    let completedStories: [String] // story IDs
    let favoriteStories: [String] // story IDs
    let currentStreak: Int // days
    let longestStreak: Int // days
    let achievements: [Achievement]
    let lastStoryId: String?
    let lastPlaybackPosition: Int? // in seconds
    
    enum CodingKeys: String, CodingKey {
        case totalStoriesListened = "total_stories_listened"
        case totalListeningTime = "total_listening_time"
        case completedStories = "completed_stories"
        case favoriteStories = "favorite_stories"
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
        case achievements
        case lastStoryId = "last_story_id"
        case lastPlaybackPosition = "last_playback_position"
    }
    
    var formattedTotalListeningTime: String {
        let hours = totalListeningTime / 3600
        let minutes = (totalListeningTime % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Achievement

struct Achievement: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let unlockedAt: String?
    let isUnlocked: Bool
    let progress: Int // 0-100
    let requirement: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case icon
        case unlockedAt = "unlocked_at"
        case isUnlocked = "is_unlocked"
        case progress
        case requirement
    }
    
    var progressPercentage: Double {
        return Double(progress) / Double(requirement) * 100.0
    }
}

// MARK: - Story Progress

struct StoryProgress: Codable, Identifiable {
    let id: String
    let storyId: String
    let userId: String
    let playbackPosition: Int // in seconds
    let isCompleted: Bool
    let completedAt: String?
    let lastPlayedAt: String
    let playCount: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case storyId = "story_id"
        case userId = "user_id"
        case playbackPosition = "playback_position"
        case isCompleted = "is_completed"
        case completedAt = "completed_at"
        case lastPlayedAt = "last_played_at"
        case playCount = "play_count"
    }
}

// MARK: - Sample Data

extension User {
    static let sampleUser = User(
        id: "sample-user-1",
        name: "Emma",
        age: 5,
        gradeLevel: "grade_prek",
        preferences: UserPreferences(
            autoPlay: true,
            downloadOverWiFi: true,
            playbackSpeed: .normal,
            notificationsEnabled: true,
            favoriteCategories: ["firefly-forest", "starlight-meadow"]
        ),
        progress: UserProgress(
            totalStoriesListened: 15,
            totalListeningTime: 6300, // 1 hour 45 minutes
            completedStories: ["story-1", "story-2", "story-3"],
            favoriteStories: ["story-1", "story-5"],
            currentStreak: 7,
            longestStreak: 12,
            achievements: [
                Achievement(
                    id: "first-story",
                    title: "First Story",
                    description: "Listen to your first story",
                    icon: "star.fill",
                    unlockedAt: "2025-07-25T10:00:00Z",
                    isUnlocked: true,
                    progress: 1,
                    requirement: 1
                ),
                Achievement(
                    id: "story-collector",
                    title: "Story Collector",
                    description: "Listen to 10 different stories",
                    icon: "books.vertical.fill",
                    unlockedAt: nil,
                    isUnlocked: false,
                    progress: 8,
                    requirement: 10
                )
            ],
            lastStoryId: "story-3",
            lastPlaybackPosition: 180
        ),
        createdAt: "2025-07-20T10:00:00Z",
        lastActiveAt: "2025-08-03T14:30:00Z"
    )
}