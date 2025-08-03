//
//  MigrationHelper.swift
//  StorySage
//
//  Created on 2025-08-03.
//
//  Helps transition the app from server-based to local resources.
//

import Foundation

// MARK: - Migration Helper

class MigrationHelper {
    
    // MARK: - Configuration
    
    /// Set this to true to use local resources, false to use server
    static let useLocalResources = true
    
    // MARK: - Type Aliases
    
    /// Use these type aliases to easily switch between implementations
    typealias DataManager = LocalDataManager  // or NetworkManager
    typealias AudioPlayerType = LocalAudioPlayer  // or AudioPlayer
    typealias HomeViewModelType = LocalHomeViewModel  // or HomeViewModel
    
    // MARK: - Shared Instances
    
    static var sharedDataManager: Any {
        if useLocalResources {
            return LocalDataManager.shared
        } else {
            return NetworkManager.shared
        }
    }
    
    static var sharedAudioPlayer: Any {
        if useLocalResources {
            return LocalAudioPlayer()
        } else {
            return AudioPlayer()
        }
    }
    
    // MARK: - API Compatibility Layer
    
    /// Provides a unified interface for data operations
    class DataService {
        
        static let shared = DataService()
        
        private init() {}
        
        func getCategories() async throws -> [Category] {
            if MigrationHelper.useLocalResources {
                return try await LocalDataManager.shared.getCategories()
            } else {
                return try await NetworkManager.shared.getCategories()
            }
        }
        
        func getStories(categoryId: String? = nil, gradeLevel: String? = nil) async throws -> [Story] {
            if MigrationHelper.useLocalResources {
                return try await LocalDataManager.shared.getStories(categoryId: categoryId, gradeLevel: gradeLevel)
            } else {
                return try await NetworkManager.shared.getStories(categoryId: categoryId, gradeLevel: gradeLevel)
            }
        }
        
        func getStory(id: String) async throws -> Story {
            if MigrationHelper.useLocalResources {
                return try await LocalDataManager.shared.getStory(id: id)
            } else {
                return try await NetworkManager.shared.getStory(id: id)
            }
        }
        
        func getUserProgress(userId: String) async throws -> UserProgress {
            if MigrationHelper.useLocalResources {
                // Convert local progress to UserProgress format
                let stats = CoreDataManager.shared.getUserStatistics(userId: userId)
                let progressRecords = CoreDataManager.shared.getAllProgress(userId: userId)
                
                return UserProgress(
                    totalStoriesListened: stats.totalStoriesListened,
                    totalListeningTime: stats.totalListeningTime,
                    completedStories: progressRecords.filter { $0.isCompleted }.map { $0.storyId },
                    favoriteStories: progressRecords.filter { $0.isFavorite }.map { $0.storyId },
                    currentStreak: stats.currentStreak,
                    longestStreak: stats.currentStreak, // TODO: Track longest streak
                    achievements: CoreDataManager.shared.getAchievements(userId: userId).map { $0.achievementId },
                    lastStoryId: progressRecords.first?.storyId,
                    lastPlaybackPosition: progressRecords.first.map { Int($0.playbackPosition) }
                )
            } else {
                return try await NetworkManager.shared.getUserProgress(userId: userId)
            }
        }
        
        func updateProgress(
            userId: String,
            storyId: String,
            playbackPosition: Int,
            isCompleted: Bool
        ) async throws {
            if MigrationHelper.useLocalResources {
                _ = CoreDataManager.shared.createOrUpdateProgress(
                    storyId: storyId,
                    playbackPosition: playbackPosition,
                    isCompleted: isCompleted,
                    userId: userId
                )
            } else {
                try await NetworkManager.shared.updateProgress(
                    userId: userId,
                    storyId: storyId,
                    playbackPosition: playbackPosition,
                    isCompleted: isCompleted
                )
            }
        }
    }
    
    // MARK: - Migration Methods
    
    /// Check if migration to local resources is needed
    static func checkMigrationStatus() -> MigrationStatus {
        // Check if local data exists
        let hasLocalData = Bundle.main.url(forResource: "stories", withExtension: "json", subdirectory: "Data") != nil
        let hasAudioFiles = Bundle.main.url(forResource: "sample_audio", withExtension: "mp3", subdirectory: "Audio") != nil ||
                           !Bundle.main.urls(forResourcesWithExtension: "mp3", subdirectory: "Audio")?.isEmpty ?? true
        
        if hasLocalData && hasAudioFiles {
            return .ready
        } else if hasLocalData {
            return .partiallyReady
        } else {
            return .notReady
        }
    }
    
    /// Migrate cached audio files to bundle format
    static func migrateCachedAudio() {
        // This would be used during development to help identify which audio files
        // correspond to which stories
        
        let cacheManager = AudioCacheManager.shared
        let cachedFiles = cacheManager.getCachedFiles()
        
        var audioMapping: [String: String] = [:]
        
        for file in cachedFiles {
            // Extract story ID from filename if possible
            let filename = file.fileName
            
            // You would need to implement logic to map cached files to story IDs
            // This is a placeholder
            audioMapping[filename] = file.url.path
        }
        
        // Save mapping for reference
        if let mappingData = try? JSONEncoder().encode(audioMapping) {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let mappingURL = documentsPath.appendingPathComponent("audio_mapping.json")
            try? mappingData.write(to: mappingURL)
        }
    }
}

// MARK: - Migration Status

enum MigrationStatus {
    case ready          // All local resources are available
    case partiallyReady // Some resources are missing
    case notReady       // No local resources found
    
    var description: String {
        switch self {
        case .ready:
            return "App is ready to work offline"
        case .partiallyReady:
            return "Some resources are missing"
        case .notReady:
            return "Local resources not found"
        }
    }
}