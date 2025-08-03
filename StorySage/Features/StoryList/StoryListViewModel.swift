//
//  StoryListViewModel.swift
//  StorySage
//
//  Created on 2025-08-03.
//

import Foundation
import Combine

@MainActor
class StoryListViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var stories: [Story] = []
    @Published var searchText = ""
    @Published var selectedFilter: StoryFilter = .all
    @Published var isLoading = false
    @Published var error: Error?
    
    // MARK: - Private Properties
    
    private let category: Category
    private let networkManager = NetworkManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var filteredStories: [Story] {
        let filtered = stories.filter { story in
            // Search filter
            if !searchText.isEmpty {
                let searchLower = searchText.lowercased()
                let matchesTitle = story.title.lowercased().contains(searchLower)
                let matchesDescription = story.description.lowercased().contains(searchLower)
                let matchesTags = story.tags.contains { $0.lowercased().contains(searchLower) }
                
                if !matchesTitle && !matchesDescription && !matchesTags {
                    return false
                }
            }
            
            // Category filter
            guard story.category == category.id else { return false }
            
            // Additional filters
            switch selectedFilter {
            case .all:
                return true
            case .new:
                // Stories created in the last 7 days
                let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
                let storyDate = ISO8601DateFormatter().date(from: story.createdAt) ?? Date.distantPast
                return storyDate > sevenDaysAgo
            case .favorites:
                // TODO: Check user's favorite stories
                return false // Placeholder
            case .downloaded:
                return story.isDownloaded
            case .shortStories:
                return story.duration < 300 // Less than 5 minutes
            case .longStories:
                return story.duration > 600 // More than 10 minutes
            }
        }
        
        // Sort by creation date (newest first)
        return filtered.sorted { story1, story2 in
            let date1 = ISO8601DateFormatter().date(from: story1.createdAt) ?? Date.distantPast
            let date2 = ISO8601DateFormatter().date(from: story2.createdAt) ?? Date.distantPast
            return date1 > date2
        }
    }
    
    // MARK: - Initialization
    
    init(category: Category) {
        self.category = category
        setupSearchDebouncing()
    }
    
    // MARK: - Public Methods
    
    func loadStories() async {
        isLoading = true
        error = nil
        
        do {
            let allStories = try await networkManager.getStories(
                categoryId: category.id,
                gradeLevel: category.gradeLevel
            )
            
            self.stories = allStories
        } catch {
            self.error = error
            print("Failed to load stories for category \(category.name): \(error)")
            
            // Fallback to sample data
            loadSampleData()
        }
        
        isLoading = false
    }
    
    func refreshStories() async {
        await loadStories()
    }
    
    func setFilter(_ filter: StoryFilter) {
        selectedFilter = filter
    }
    
    func resetFilters() {
        selectedFilter = .all
        searchText = ""
    }
    
    // MARK: - Private Methods
    
    private func setupSearchDebouncing() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                // Search filtering is handled in computed property
                // This is just for any additional search-related side effects
            }
            .store(in: &cancellables)
    }
    
    private func loadSampleData() {
        // Filter sample stories for this category
        stories = Story.sampleStories.filter { $0.category == category.id }
    }
}

// MARK: - Story Filter

enum StoryFilter: CaseIterable {
    case all
    case new
    case favorites
    case downloaded
    case shortStories
    case longStories
    
    var displayName: String {
        switch self {
        case .all:
            return "All"
        case .new:
            return "New"
        case .favorites:
            return "Favorites"
        case .downloaded:
            return "Downloaded"
        case .shortStories:
            return "Short Stories"
        case .longStories:
            return "Long Stories"
        }
    }
}