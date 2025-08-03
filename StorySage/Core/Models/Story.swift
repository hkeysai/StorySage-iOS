//
//  Story.swift
//  StorySage
//
//  Created on 2025-08-03.
//

import Foundation

// MARK: - Story Model

struct Story: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
    let category: String
    let gradeLevel: String
    let duration: Int // in seconds
    let audioUrl: String?
    let segments: [StorySegment]
    let tags: [String]
    let keyLessons: [String]
    let createdAt: String
    let status: StoryStatus
    let downloadUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case category
        case gradeLevel = "grade_level"
        case duration
        case audioUrl = "audio_url"
        case segments
        case tags
        case keyLessons = "key_lessons"
        case createdAt = "created_at"
        case status
        case downloadUrl = "download_url"
    }
    
    var formattedDuration: String {
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var isDownloaded: Bool {
        // Check if audio file exists locally
        guard let audioUrl = audioUrl else { return false }
        let cacheManager = AudioCacheManager.shared
        return cacheManager.isFileCached(url: audioUrl)
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
}

// MARK: - Story Segment

struct StorySegment: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let content: String
    let duration: Int // in seconds
    let order: Int
    let audioUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case content
        case duration
        case order
        case audioUrl = "audio_url"
    }
}

// MARK: - Story Status

enum StoryStatus: String, Codable, CaseIterable {
    case draft = "draft"
    case ready = "ready"
    case published = "published"
    case archived = "archived"
    
    var displayName: String {
        switch self {
        case .draft:
            return "Draft"
        case .ready:
            return "Ready"
        case .published:
            return "Published"
        case .archived:
            return "Archived"
        }
    }
}

// MARK: - Sample Data

extension Story {
    static let sampleStory = Story(
        id: "sample-story-1",
        title: "Benny's Big Feeling Day",
        description: "Join Benny the bear as he learns to understand and express his emotions in the magical Firefly Forest.",
        category: "firefly-forest",
        gradeLevel: "grade_prek",
        duration: 420, // 7 minutes
        audioUrl: "https://api.storysage.com/audio/benny-big-feeling-day.mp3",
        segments: [
            StorySegment(
                id: "segment-1",
                title: "Morning in the Forest",
                content: "Once upon a time, in a magical forest where fireflies danced...",
                duration: 60,
                order: 1,
                audioUrl: "https://api.storysage.com/audio/benny-segment-1.mp3"
            ),
            StorySegment(
                id: "segment-2",
                title: "Benny's Big Feeling",
                content: "Benny woke up feeling something big and confusing inside...",
                duration: 60,
                order: 2,
                audioUrl: "https://api.storysage.com/audio/benny-segment-2.mp3"
            )
        ],
        tags: ["emotions", "feelings", "bear", "forest"],
        keyLessons: [
            "It's okay to have big feelings",
            "Talking about feelings helps",
            "Friends care about each other"
        ],
        createdAt: "2025-08-01T10:00:00Z",
        status: .published,
        downloadUrl: "https://api.storysage.com/download/benny-big-feeling-day.mp3"
    )
    
    static let sampleStories = [
        sampleStory,
        Story(
            id: "sample-story-2",
            title: "Luna's Worried Night",
            description: "Luna the owl learns that sharing worries with friends makes them feel smaller.",
            category: "firefly-forest",
            gradeLevel: "grade_prek",
            duration: 380,
            audioUrl: "https://api.storysage.com/audio/luna-worried-night.mp3",
            segments: [],
            tags: ["worry", "friendship", "owl", "night"],
            keyLessons: [
                "Sharing worries helps",
                "Friends support each other",
                "It's okay to feel scared sometimes"
            ],
            createdAt: "2025-08-01T11:00:00Z",
            status: .published,
            downloadUrl: "https://api.storysage.com/download/luna-worried-night.mp3"
        )
    ]
}