//
//  LocalDataProvider.swift
//  StorySage
//
//  Created on 2025-08-03.
//
//  Local data provider that loads stories and categories from bundled JSON files
//  This replaces NetworkManager for a completely offline experience

import Foundation
import Combine

// MARK: - Local Data Provider

@MainActor
class LocalDataProvider: ObservableObject {
    static let shared = LocalDataProvider()
    
    @Published var isLoading = false
    @Published var lastError: LocalDataError?
    
    private var stories: [Story] = []
    private var categories: [Category] = []
    private var metadata: AppMetadata?
    
    private init() {
        loadBundledData()
    }
    
    // MARK: - Data Loading
    
    private func loadBundledData() {
        // First, let's check what's in the bundle
        if let resourcePath = Bundle.main.resourcePath {
            print("Bundle resource path: \(resourcePath)")
        }
        
        do {
            
            // Try different paths for the resources
            let possiblePaths = [
                "Resources/Data", // Full path with Resources
                "Data",           // Just Data folder
                ""                // Root bundle
            ]
            
            var foundPath: String? = nil
            
            for path in possiblePaths {
                if let testURL = Bundle.main.url(forResource: "categories", withExtension: "json", subdirectory: path) {
                    foundPath = path
                    print("Found resources in subdirectory: '\(path)'")
                    break
                }
            }
            
            let subdirectory = foundPath ?? ""
            
            // Load categories
            if let categoriesURL = Bundle.main.url(forResource: "categories", withExtension: "json", subdirectory: subdirectory) {
                print("Found categories.json at: \(categoriesURL.path)")
                do {
                    let categoriesData = try Data(contentsOf: categoriesURL)
                    print("Loaded data, size: \(categoriesData.count) bytes")
                    let categoriesResponse = try JSONDecoder().decode(CategoriesFile.self, from: categoriesData)
                    self.categories = categoriesResponse.categories.map { $0.toCategory() }
                    print("✅ Loaded \(categories.count) categories from \(categoriesURL.path)")
                } catch {
                    print("❌ Failed to decode categories.json: \(error)")
                }
            } else {
                print("❌ Failed to find categories.json in subdirectory: \(subdirectory)")
                // List all JSON files in bundle to debug
                if let urls = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: nil) {
                    print("JSON files in bundle: \(urls.map { $0.lastPathComponent })")
                }
            }
            
            // Load stories
            if let storiesURL = Bundle.main.url(forResource: "stories", withExtension: "json", subdirectory: subdirectory),
               let storiesData = try? Data(contentsOf: storiesURL) {
                let storiesResponse = try JSONDecoder().decode(StoriesFile.self, from: storiesData)
                self.stories = storiesResponse.stories.map { $0.toStory() }
                print("Loaded \(stories.count) stories from \(storiesURL.path)")
            } else {
                print("❌ Failed to load stories.json from subdirectory: \(subdirectory)")
            }
            
            // Load metadata
            if let metadataURL = Bundle.main.url(forResource: "metadata", withExtension: "json", subdirectory: subdirectory),
               let metadataData = try? Data(contentsOf: metadataURL) {
                self.metadata = try JSONDecoder().decode(AppMetadata.self, from: metadataData)
            }
            
            print("✅ LocalDataProvider: Loaded \(stories.count) stories and \(categories.count) categories")
            
        } catch {
            lastError = .loadingFailed(error)
            print("❌ LocalDataProvider: Failed to load bundled data: \(error)")
        }
    }
    
    // MARK: - Public API (Matching NetworkManager interface)
    
    func getCategories() async throws -> [Category] {
        // Simulate network delay for smooth UI transition
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        guard !categories.isEmpty else {
            throw LocalDataError.noData
        }
        
        return categories
    }
    
    func getStories(categoryId: String? = nil, gradeLevel: String? = nil) async throws -> [Story] {
        // Simulate network delay for smooth UI transition
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        var filteredStories = stories
        
        if let categoryId = categoryId {
            filteredStories = filteredStories.filter { $0.category == categoryId }
        }
        
        if let gradeLevel = gradeLevel {
            filteredStories = filteredStories.filter { $0.gradeLevel == gradeLevel }
        }
        
        return filteredStories
    }
    
    func getStory(id: String) async throws -> Story {
        // Simulate network delay for smooth UI transition
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        
        guard let story = stories.first(where: { $0.id == id }) else {
            throw LocalDataError.storyNotFound(id)
        }
        
        return story
    }
    
    func getUserProgress(userId: String) async throws -> UserProgress {
        // Return mock progress for now - in real app, this would come from UserDefaults or Core Data
        return UserProgress(
            totalStoriesListened: UserDefaults.standard.integer(forKey: "totalStoriesListened"),
            totalListeningTime: UserDefaults.standard.integer(forKey: "totalListeningTime"),
            completedStories: UserDefaults.standard.stringArray(forKey: "completedStories") ?? [],
            favoriteStories: UserDefaults.standard.stringArray(forKey: "favoriteStories") ?? [],
            currentStreak: UserDefaults.standard.integer(forKey: "currentStreak"),
            longestStreak: UserDefaults.standard.integer(forKey: "longestStreak"),
            achievements: [], // For now, return empty array - implement proper achievement loading later
            lastStoryId: UserDefaults.standard.string(forKey: "lastStoryId"),
            lastPlaybackPosition: UserDefaults.standard.object(forKey: "lastPlaybackPosition") as? Int
        )
    }
    
    func updateProgress(
        userId: String,
        storyId: String,
        playbackPosition: Int,
        isCompleted: Bool
    ) async throws {
        // Save progress to UserDefaults - in real app, use Core Data
        if isCompleted {
            var completedStories = UserDefaults.standard.stringArray(forKey: "completedStories") ?? []
            if !completedStories.contains(storyId) {
                completedStories.append(storyId)
                UserDefaults.standard.set(completedStories, forKey: "completedStories")
                
                // Update total stories listened
                let total = UserDefaults.standard.integer(forKey: "totalStoriesListened")
                UserDefaults.standard.set(total + 1, forKey: "totalStoriesListened")
            }
        }
        
        // Save last played info
        UserDefaults.standard.set(storyId, forKey: "lastStoryId")
        UserDefaults.standard.set(playbackPosition, forKey: "lastPlaybackPosition")
        
        // Update listening time
        if let story = stories.first(where: { $0.id == storyId }) {
            let currentTime = UserDefaults.standard.integer(forKey: "totalListeningTime")
            let percentComplete = Double(playbackPosition) / Double(story.duration)
            let timeToAdd = Int(Double(story.duration) * percentComplete)
            UserDefaults.standard.set(currentTime + timeToAdd, forKey: "totalListeningTime")
        }
    }
    
    func healthCheck() async throws -> Bool {
        // Always return true for local data
        return true
    }
    
    func audioHealthCheck() async throws -> Bool {
        // Check if all audio files exist in bundle
        let audioFiles = stories.compactMap { story -> String? in
            guard let audioUrl = story.audioUrl else { return nil }
            return audioUrl
        }
        
        for audioFile in audioFiles {
            if Bundle.main.url(forResource: audioFile.replacingOccurrences(of: ".mp3", with: ""), 
                              withExtension: "mp3", 
                              subdirectory: "Audio") == nil {
                return false
            }
        }
        
        return true
    }
}

// MARK: - Local Data Models (Matching JSON structure)

private struct StoriesFile: Codable {
    let stories: [LocalStory]
}

private struct LocalStory: Codable {
    let id: String
    let title: String
    let description: String
    let category: String
    let gradeLevel: String
    let duration: Int
    let audioFile: String
    let keyLessons: [String]
    let tags: [String]
    
    func toStory() -> Story {
        return Story(
            id: id,
            title: title,
            description: description,
            category: category,
            gradeLevel: gradeLevel,
            duration: duration,
            audioUrl: audioFile, // Will be loaded from bundle
            segments: [], // Not used in local version
            tags: tags,
            keyLessons: keyLessons,
            createdAt: Date().description,
            status: .published,
            downloadUrl: nil // Not needed for local files
        )
    }
}

private struct CategoriesFile: Codable {
    let categories: [LocalCategory]
}

private struct LocalCategory: Codable {
    let id: String
    let name: String
    let description: String
    let color: String
    let icon: String
    let gradeLevels: [String]
    
    func toCategory() -> Category {
        return Category(
            id: id,
            name: name,
            description: description,
            icon: icon,
            color: color,
            gradeLevel: gradeLevels.first ?? "grade_prek", // Default to pre-k
            storyCount: 0, // Will be calculated dynamically
            isActive: true // All categories are active by default
        )
    }
}

private struct AppMetadata: Codable {
    let version: String
    let totalStories: Int
    let totalCategories: Int
    let gradeLevels: [String]
    let totalDuration: Int
    let lastUpdated: String
}

// MARK: - Local Data Error

enum LocalDataError: Error, LocalizedError {
    case noData
    case dataNotLoaded
    case loadingFailed(Error)
    case storyNotFound(String)
    case audioNotFound(String)
    
    var errorDescription: String? {
        switch self {
        case .noData:
            return "No data available"
        case .dataNotLoaded:
            return "Data has not been loaded yet"
        case .loadingFailed(let error):
            return "Failed to load data: \(error.localizedDescription)"
        case .storyNotFound(let id):
            return "Story not found: \(id)"
        case .audioNotFound(let file):
            return "Audio file not found: \(file)"
        }
    }
}