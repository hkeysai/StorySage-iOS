//
//  Responses.swift
//  StorySage
//
//  Created on 2025-08-03.
//

import Foundation

// MARK: - Categories Response

struct CategoriesResponse: Codable {
    let status: String
    let categories: [Category]
}

// MARK: - Stories Response

struct StoriesResponse: Codable {
    let status: String
    let stories: [Story]
    let total: Int?
    let page: Int?
    let perPage: Int?
    
    enum CodingKeys: String, CodingKey {
        case status
        case stories
        case total
        case page
        case perPage = "per_page"
    }
}

// MARK: - Story Response

struct StoryResponse: Codable {
    let status: String
    let story: Story
}

// MARK: - Progress Response

struct ProgressResponse: Codable {
    let status: String
    let progress: UserProgress
    let message: String?
}

// MARK: - Health Check Response

struct HealthCheckResponse: Codable {
    let status: String
    let service: String
    let version: String
    let timestamp: String
    let checks: [String: Bool]?
}

// MARK: - Audio Health Response

struct AudioHealthResponse: Codable {
    let status: String
    let audioSystemHealthy: Bool
    let totalAudioFiles: Int
    let missingFiles: [String]?
    
    enum CodingKeys: String, CodingKey {
        case status
        case audioSystemHealthy = "audio_system_healthy"
        case totalAudioFiles = "total_audio_files"
        case missingFiles = "missing_files"
    }
}