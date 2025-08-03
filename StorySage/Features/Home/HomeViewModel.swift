//
//  HomeViewModel.swift
//  StorySage
//
//  Created on 2025-08-03.
//

import Foundation
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var categories: [Category] = []
    @Published var featuredStory: Story?
    @Published var recentStories: [Story] = []
    @Published var lastPlayedStory: Story?
    @Published var selectedGradeLevel: GradeLevel = .preK
    @Published var userProgress: UserProgress = UserProgress(
        totalStoriesListened: 0,
        totalListeningTime: 0,
        completedStories: [],
        favoriteStories: [],
        currentStreak: 0,
        longestStreak: 0,
        achievements: [],
        lastStoryId: nil,
        lastPlaybackPosition: nil
    )
    @Published var isLoading = false
    @Published var error: Error?
    
    // MARK: - Private Properties
    
    private let networkManager = NetworkManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var filteredCategories: [Category] {
        return categories.filter { $0.gradeLevel == selectedGradeLevel.rawValue }
    }
    
    // MARK: - Initialization
    
    init() {
        // Load sample data initially
        loadSampleData()
    }
    
    // MARK: - Public Methods
    
    func loadInitialData() async {
        isLoading = true
        error = nil
        
        do {
            async let categoriesTask = loadCategories()
            async let recentStoriesTask = loadRecentStories()
            async let userProgressTask = loadUserProgress()
            
            let (categories, recentStories, userProgress) = await (
                try categoriesTask,
                try recentStoriesTask,
                try userProgressTask
            )
            
            self.categories = categories
            self.recentStories = recentStories
            self.userProgress = userProgress
            
            // Set featured story from recent stories
            self.featuredStory = recentStories.first
            
            // Set last played story
            if let lastStoryId = userProgress.lastStoryId {
                self.lastPlayedStory = recentStories.first { $0.id == lastStoryId }
            }
            
        } catch {
            self.error = error
            print("Failed to load initial data: \(error)")
            
            // Fallback to sample data
            loadSampleData()
        }
        
        isLoading = false
    }
    
    func refreshData() async {
        await loadInitialData()
    }
    
    func selectGradeLevel(_ gradeLevel: GradeLevel) {
        selectedGradeLevel = gradeLevel
        
        // Reload featured story for the selected grade level
        Task {
            await loadFeaturedStoryForGrade(gradeLevel)
        }
    }
    
    // MARK: - Private Methods
    
    private func loadCategories() async throws -> [Category] {
        return try await networkManager.getCategories()
    }
    
    private func loadRecentStories() async throws -> [Story] {
        return try await networkManager.getStories()
    }
    
    private func loadUserProgress() async throws -> UserProgress {
        // TODO: Get actual user ID from user defaults or authentication
        let userId = "current-user"
        return try await networkManager.getUserProgress(userId: userId)
    }
    
    private func loadFeaturedStoryForGrade(_ gradeLevel: GradeLevel) async {
        do {
            let stories = try await networkManager.getStories(gradeLevel: gradeLevel.rawValue)
            featuredStory = stories.randomElement()
        } catch {
            print("Failed to load featured story for grade \(gradeLevel): \(error)")
        }
    }
    
    private func loadSampleData() {
        categories = Category.sampleCategories
        recentStories = Story.sampleStories
        featuredStory = Story.sampleStory
        userProgress = User.sampleUser.progress
        
        // Filter categories for current grade level
        if let firstCategory = categories.first(where: { $0.gradeLevel == selectedGradeLevel.rawValue }) {
            featuredStory = recentStories.first { $0.category == firstCategory.id }
        }
    }
}