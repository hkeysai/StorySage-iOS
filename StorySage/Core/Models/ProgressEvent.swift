//
//  ProgressEvent.swift
//  StorySage
//
//  Created on 2025-08-03.
//

import Foundation

// MARK: - Progress Event

struct ProgressEvent: Codable {
    let id: String
    let userId: String
    let storyId: String
    let eventType: EventType
    let timestamp: String
    let metadata: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case storyId = "story_id"
        case eventType = "event_type"
        case timestamp
        case metadata
    }
}

// MARK: - Event Type

enum EventType: String, Codable {
    case storyStarted = "story_started"
    case storyPaused = "story_paused"
    case storyResumed = "story_resumed"
    case storyCompleted = "story_completed"
    case storySkipped = "story_skipped"
    case storyFavorited = "story_favorited"
    case storyUnfavorited = "story_unfavorited"
    case storyDownloaded = "story_downloaded"
    case achievementUnlocked = "achievement_unlocked"
    case sessionStarted = "session_started"
    case sessionEnded = "session_ended"
}