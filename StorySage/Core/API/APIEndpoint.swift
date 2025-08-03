//
//  APIEndpoint.swift
//  StorySage
//
//  Created on 2025-08-03.
//

import Foundation

// MARK: - API Endpoint

enum APIEndpoint {
    case categories
    case stories(categoryId: String? = nil, gradeLevel: String? = nil)
    case story(id: String)
    case userProgress(userId: String)
    case updateProgress(userId: String, storyId: String)
    case healthCheck
    case audioHealth
    
    var path: String {
        switch self {
        case .categories:
            return "/api/categories"
        case .stories(let categoryId, let gradeLevel):
            var path = "/api/stories"
            var queryItems: [String] = []
            
            if let categoryId = categoryId {
                queryItems.append("category=\(categoryId)")
            }
            if let gradeLevel = gradeLevel {
                queryItems.append("grade_level=\(gradeLevel)")
            }
            
            if !queryItems.isEmpty {
                path += "?" + queryItems.joined(separator: "&")
            }
            
            return path
        case .story(let id):
            return "/api/stories/\(id)"
        case .userProgress(let userId):
            return "/api/progress/\(userId)"
        case .updateProgress(let userId, let storyId):
            return "/api/progress/\(userId)/\(storyId)"
        case .healthCheck:
            return "/api/health"
        case .audioHealth:
            return "/api/health/audio"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .categories, .stories, .story, .userProgress, .healthCheck, .audioHealth:
            return .GET
        case .updateProgress:
            return .POST
        }
    }
    
    var headers: [String: String] {
        var headers = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
        
        // Add any authentication headers if needed
        // headers["Authorization"] = "Bearer \(token)"
        
        return headers
    }
}

// MARK: - HTTP Method

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

// MARK: - API Response

struct APIResponse<T: Codable>: Codable {
    let status: String
    let data: T?
    let message: String?
    let error: APIError?
    
    var isSuccess: Bool {
        return status == "success"
    }
}

// MARK: - API Error

struct APIError: Codable, Error {
    let code: String
    let message: String
    let details: [String: String]?
    
    var localizedDescription: String {
        return message
    }
}

// MARK: - Network Error

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case encodingError(Error)
    case serverError(Int, String?)
    case networkError(Error)
    case apiError(APIError)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        case .serverError(let code, let message):
            return "Server error \(code): \(message ?? "Unknown error")"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .apiError(let apiError):
            return apiError.localizedDescription
        }
    }
}

// MARK: - Progress Update Request

struct ProgressUpdateRequest: Codable {
    let playbackPosition: Int
    let isCompleted: Bool
    let timestamp: String
    
    enum CodingKeys: String, CodingKey {
        case playbackPosition = "playback_position"
        case isCompleted = "is_completed"
        case timestamp
    }
    
    init(playbackPosition: Int, isCompleted: Bool) {
        self.playbackPosition = playbackPosition
        self.isCompleted = isCompleted
        self.timestamp = ISO8601DateFormatter().string(from: Date())
    }
}