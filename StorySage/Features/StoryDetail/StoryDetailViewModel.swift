//
//  StoryDetailViewModel.swift
//  StorySage
//
//  Created on 2025-08-03.
//

import Foundation

@MainActor
class StoryDetailViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isFavorite = false
    @Published var isDownloading = false
    @Published var downloadProgress: Double = 0.0
    @Published var playbackProgress: Int = 0 // in seconds
    @Published var isCompleted = false
    @Published var error: Error?
    
    // MARK: - Private Properties
    
    private let story: Story
    private let networkManager = NetworkManager.shared
    private let cacheManager = AudioCacheManager.shared
    
    // MARK: - Computed Properties
    
    var hasProgress: Bool {
        return playbackProgress > 0
    }
    
    var progressPercentage: Double {
        guard story.duration > 0 else { return 0 }
        return Double(playbackProgress) / Double(story.duration)
    }
    
    var formattedProgress: String {
        let minutes = playbackProgress / 60
        let seconds = playbackProgress % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - Initialization
    
    init(story: Story) {
        self.story = story
        loadUserProgress()
    }
    
    // MARK: - Public Methods
    
    func loadStoryDetails() async {
        // Load user-specific data for this story
        await loadUserProgress()
    }
    
    func toggleFavorite() {
        isFavorite.toggle()
        
        Task {
            do {
                // TODO: Implement API call to update favorite status
                // For now, just store locally
                UserDefaults.standard.set(isFavorite, forKey: "favorite_\(story.id)")
            } catch {
                // Revert on error
                isFavorite.toggle()
                self.error = error
            }
        }
    }
    
    func downloadStory() async {
        guard let audioUrl = story.audioUrl, !story.isDownloaded else { return }
        
        isDownloading = true
        downloadProgress = 0.0
        error = nil
        
        do {
            let localURL = try await cacheManager.cacheAudioWithProgress(from: audioUrl) { progress in
                Task { @MainActor in
                    self.downloadProgress = progress
                }
            }
            
            // Notify user of successful download
            await NotificationManager.shared.scheduleDownloadCompletionNotification(storyTitle: story.title)
            
        } catch {
            self.error = error
            print("Failed to download story: \(error)")
        }
        
        isDownloading = false
    }
    
    func updateProgress(position: Int, completed: Bool) async {
        playbackProgress = position
        isCompleted = completed
        
        // Save progress locally
        saveProgressLocally()
        
        // Sync with server
        do {
            try await networkManager.updateProgress(
                userId: getCurrentUserId(),
                storyId: story.id,
                playbackPosition: position,
                isCompleted: completed
            )
        } catch {
            print("Failed to sync progress with server: \(error)")
            // Don't show error to user for progress sync failures
        }
    }
    
    // MARK: - Private Methods
    
    private func loadUserProgress() {
        // Load favorite status
        isFavorite = UserDefaults.standard.bool(forKey: "favorite_\(story.id)")
        
        // Load playback progress
        playbackProgress = UserDefaults.standard.integer(forKey: "progress_\(story.id)")
        isCompleted = UserDefaults.standard.bool(forKey: "completed_\(story.id)")
        
        // Load from server in background
        Task {
            await loadUserProgressFromServer()
        }
    }
    
    private func loadUserProgressFromServer() async {
        do {
            let userProgress = try await networkManager.getUserProgress(userId: getCurrentUserId())
            
            // Update local state with server data
            isFavorite = userProgress.favoriteStories.contains(story.id)
            isCompleted = userProgress.completedStories.contains(story.id)
            
            // TODO: Get specific story progress from server
            // For now, use the last playback position if this is the last story
            if userProgress.lastStoryId == story.id,
               let lastPosition = userProgress.lastPlaybackPosition {
                playbackProgress = lastPosition
            }
            
            // Update local storage with server data
            saveProgressLocally()
            
        } catch {
            print("Failed to load user progress from server: \(error)")
            // Keep using local data
        }
    }
    
    private func saveProgressLocally() {
        UserDefaults.standard.set(isFavorite, forKey: "favorite_\(story.id)")
        UserDefaults.standard.set(playbackProgress, forKey: "progress_\(story.id)")
        UserDefaults.standard.set(isCompleted, forKey: "completed_\(story.id)")
    }
    
    private func getCurrentUserId() -> String {
        // TODO: Get actual user ID from authentication system
        return UserDefaults.standard.string(forKey: "current_user_id") ?? "anonymous_user"
    }
}