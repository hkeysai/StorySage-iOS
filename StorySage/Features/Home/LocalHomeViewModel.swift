//
//  LocalHomeViewModel.swift
//  StorySage
//
//  Created on 2025-08-03.
//
//  Home view model that works with local data instead of server.
//

import Foundation
import Combine

@MainActor
class LocalHomeViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var categories: [Category] = []
    @Published var featuredStory: Story?
    @Published var recentStories: [Story] = []
    @Published var continueListeningStories: [Story] = []
    @Published var selectedGradeLevel: GradeLevel = .preK
    @Published var userStatistics: UserStatistics?
    @Published var isLoading = false
    @Published var error: Error?
    
    // MARK: - Private Properties
    
    private let localDataManager = LocalDataManager.shared
    private let coreDataManager = CoreDataManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var filteredCategories: [Category] {
        return categories.filter { $0.gradeLevel == selectedGradeLevel.rawValue }
    }
    
    var hasRecentProgress: Bool {
        return !continueListeningStories.isEmpty
    }
    
    // MARK: - Initialization
    
    init() {
        setupObservers()
        loadInitialData()
    }
    
    // MARK: - Public Methods
    
    func loadInitialData() {
        Task {
            await loadData()
        }
    }
    
    func refreshData() {
        Task {
            await loadData()
        }
    }
    
    func selectGradeLevel(_ gradeLevel: GradeLevel) {
        selectedGradeLevel = gradeLevel
        
        // Save preference
        coreDataManager.updateUserSettings(preferredGradeLevel: gradeLevel.rawValue)
        
        // Update featured story for the selected grade level
        Task {
            await updateFeaturedStory()
        }
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        // Observe when local data is loaded
        localDataManager.$isDataLoaded
            .filter { $0 }
            .sink { [weak self] _ in
                Task {
                    await self?.loadData()
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadData() async {
        isLoading = true
        error = nil
        
        do {
            // Load categories
            categories = try await localDataManager.getCategories()
            
            // Load all stories
            let allStories = try await localDataManager.getStories()
            
            // Get user progress
            let progressRecords = coreDataManager.getAllProgress()
            let recentProgress = coreDataManager.getRecentlyPlayed(limit: 10)
            
            // Map progress to stories for continue listening
            continueListeningStories = recentProgress.compactMap { progress in
                allStories.first { $0.id == progress.storyId && !progress.isCompleted }
            }
            
            // Get recent stories (newest first)
            recentStories = Array(allStories.prefix(10))
            
            // Update featured story
            await updateFeaturedStory()
            
            // Load user statistics
            userStatistics = coreDataManager.getUserStatistics()
            
            // Load user settings
            let settings = coreDataManager.getUserSettings()
            if let savedGradeLevel = settings.preferredGradeLevel,
               let gradeLevel = GradeLevel(rawValue: savedGradeLevel) {
                selectedGradeLevel = gradeLevel
            }
            
        } catch {
            self.error = error
            print("Failed to load data: \(error)")
        }
        
        isLoading = false
    }
    
    private func updateFeaturedStory() async {
        do {
            // Get stories for selected grade level
            let gradeStories = try await localDataManager.getStories(gradeLevel: selectedGradeLevel.rawValue)
            
            // Try to get an unplayed story first
            let progressRecords = coreDataManager.getAllProgress()
            let playedStoryIds = Set(progressRecords.map { $0.storyId })
            
            if let unplayedStory = gradeStories.first(where: { !playedStoryIds.contains($0.id) }) {
                featuredStory = unplayedStory
            } else {
                // If all stories have been played, pick a random one
                featuredStory = gradeStories.randomElement() ?? gradeStories.first
            }
        } catch {
            print("Failed to update featured story: \(error)")
        }
    }
}

// MARK: - Mock User for Compatibility

private struct LocalUser {
    let id: String
    let name: String
    let email: String
    let createdAt: Date
    let progress: UserProgress
    
    static let sampleUser = LocalUser(
        id: "default-user",
        name: "Default User",
        email: "user@storysage.com",
        createdAt: Date(),
        progress: UserProgress(
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
    )
}