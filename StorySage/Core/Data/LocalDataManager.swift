//
//  LocalDataManager.swift
//  StorySage
//
//  Created on 2025-08-03.
//  
//  This manager replaces NetworkManager for offline functionality.
//  All data is loaded from bundled JSON files and audio files.
//

import Foundation
import Combine

// MARK: - Local Data Manager

@MainActor
class LocalDataManager: ObservableObject {
    static let shared = LocalDataManager()
    
    // MARK: - Published Properties
    
    @Published var isDataLoaded = false
    @Published var lastError: LocalDataError?
    
    // MARK: - Private Properties
    
    private var stories: [Story] = []
    private var categories: [Category] = []
    private var storiesByCategory: [String: [Story]] = [:]
    private var storiesByGrade: [String: [Story]] = [:]
    
    // MARK: - Initialization
    
    private init() {
        loadBundledData()
    }
    
    // MARK: - Public Methods
    
    func getCategories() async throws -> [Category] {
        guard isDataLoaded else {
            throw LocalDataError.dataNotLoaded
        }
        return categories
    }
    
    func getStories(categoryId: String? = nil, gradeLevel: String? = nil) async throws -> [Story] {
        guard isDataLoaded else {
            throw LocalDataError.dataNotLoaded
        }
        
        var filteredStories = stories
        
        // Filter by category if specified
        if let categoryId = categoryId {
            filteredStories = storiesByCategory[categoryId] ?? []
        }
        
        // Filter by grade level if specified
        if let gradeLevel = gradeLevel {
            if categoryId != nil {
                // Already filtered by category, filter that subset by grade
                filteredStories = filteredStories.filter { $0.gradeLevel == gradeLevel }
            } else {
                // Use pre-grouped stories by grade
                filteredStories = storiesByGrade[gradeLevel] ?? []
            }
        }
        
        return filteredStories
    }
    
    func getStory(id: String) async throws -> Story {
        guard isDataLoaded else {
            throw LocalDataError.dataNotLoaded
        }
        
        guard let story = stories.first(where: { $0.id == id }) else {
            throw LocalDataError.storyNotFound(id)
        }
        
        return story
    }
    
    func getLocalAudioURL(for story: Story) -> URL? {
        // Try multiple approaches to find the audio file
        
        // 1. If story has local_audio_file field
        if let localFile = story.audioUrl {
            let fileName = localFile.replacingOccurrences(of: ".mp3", with: "")
            if let url = Bundle.main.url(forResource: fileName, withExtension: "mp3", subdirectory: "Audio") {
                return url
            }
            
            // Try without subdirectory
            if let url = Bundle.main.url(forResource: fileName, withExtension: "mp3") {
                return url
            }
        }
        
        // 2. Try using story ID as filename
        if let url = Bundle.main.url(forResource: story.id, withExtension: "mp3", subdirectory: "Audio") {
            return url
        }
        
        // 3. Try without subdirectory
        if let url = Bundle.main.url(forResource: story.id, withExtension: "mp3") {
            return url
        }
        
        return nil
    }
    
    func preloadAudioURLs() {
        // Update all stories with their local audio URLs
        for index in stories.indices {
            if let localURL = getLocalAudioURL(for: stories[index]) {
                // Store the local path in a way that AudioPlayer can use
                stories[index].localAudioPath = localURL.path
            }
        }
        
        // Update grouped collections
        updateGroupedCollections()
    }
    
    // MARK: - Private Methods
    
    private func loadBundledData() {
        do {
            // Load categories
            if let categoriesURL = Bundle.main.url(forResource: "categories", withExtension: "json", subdirectory: "Data"),
               let categoriesData = try? Data(contentsOf: categoriesURL) {
                categories = try JSONDecoder().decode([Category].self, from: categoriesData)
            }
            
            // Load stories
            if let storiesURL = Bundle.main.url(forResource: "stories", withExtension: "json", subdirectory: "Data"),
               let storiesData = try? Data(contentsOf: storiesURL) {
                stories = try JSONDecoder().decode([Story].self, from: storiesData)
                
                // Preload audio URLs
                preloadAudioURLs()
                
                // Group stories for faster filtering
                updateGroupedCollections()
            }
            
            isDataLoaded = true
            lastError = nil
            
        } catch {
            lastError = LocalDataError.loadingFailed(error)
            isDataLoaded = false
            
            // Fall back to sample data
            loadSampleData()
        }
    }
    
    private func updateGroupedCollections() {
        // Group by category
        storiesByCategory = Dictionary(grouping: stories) { $0.category }
        
        // Group by grade level
        storiesByGrade = Dictionary(grouping: stories) { $0.gradeLevel }
    }
    
    private func loadSampleData() {
        // Use the existing sample data as fallback
        categories = Category.sampleCategories
        stories = Story.sampleStories
        
        // Update stories with local sample audio if available
        for index in stories.indices {
            stories[index].audioUrl = "sample_audio.mp3"
            if let localURL = Bundle.main.url(forResource: "sample_audio", withExtension: "mp3") {
                stories[index].localAudioPath = localURL.path
            }
        }
        
        updateGroupedCollections()
        isDataLoaded = true
    }
}

// LocalDataError is defined in LocalDataProvider.swift

// MARK: - Story Extension for Local Audio

extension Story {
    // Add a computed property for local audio path
    var localAudioPath: String? {
        get {
            // This would be stored in a associated object or computed each time
            return UserDefaults.standard.string(forKey: "audio_path_\(id)")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "audio_path_\(id)")
        }
    }
    
    var localAudioURL: URL? {
        if let path = localAudioPath {
            return URL(fileURLWithPath: path)
        }
        return LocalDataManager.shared.getLocalAudioURL(for: self)
    }
}