//
//  CoreDataManager.swift
//  StorySage
//
//  Created on 2025-08-03.
//
//  Manages local storage for user progress and settings using Core Data.
//

import Foundation
import CoreData

// MARK: - Core Data Manager

class CoreDataManager {
    static let shared = CoreDataManager()
    
    // MARK: - Core Data Stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "StorySage")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    private init() {}
    
    // MARK: - Save Context
    
    func save() {
        guard context.hasChanges else { return }
        
        do {
            try context.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
    
    // MARK: - User Progress Methods
    
    func getProgress(for storyId: String, userId: String = "default-user") -> LocalUserProgress? {
        let request: NSFetchRequest<LocalUserProgress> = LocalUserProgress.fetchRequest()
        request.predicate = NSPredicate(format: "storyId == %@ AND userId == %@", storyId, userId)
        request.fetchLimit = 1
        
        do {
            let results = try context.fetch(request)
            return results.first
        } catch {
            print("Failed to fetch progress: \(error)")
            return nil
        }
    }
    
    func createOrUpdateProgress(
        storyId: String,
        playbackPosition: Int,
        isCompleted: Bool,
        userId: String = "default-user"
    ) -> LocalUserProgress {
        let progress = getProgress(for: storyId, userId: userId) ?? LocalUserProgress(context: context)
        
        progress.storyId = storyId
        progress.userId = userId
        progress.playbackPosition = Int32(playbackPosition)
        progress.isCompleted = isCompleted
        progress.lastPlayedAt = Date()
        progress.updatedAt = Date()
        
        if progress.createdAt == nil {
            progress.createdAt = Date()
            progress.id = UUID()
        }
        
        if isCompleted && progress.completedAt == nil {
            progress.completedAt = Date()
        }
        
        progress.playCount += 1
        
        save()
        return progress
    }
    
    func markAsFavorite(storyId: String, isFavorite: Bool, userId: String = "default-user") {
        let progress = getProgress(for: storyId, userId: userId) ?? LocalUserProgress(context: context)
        
        progress.storyId = storyId
        progress.userId = userId
        progress.isFavorite = isFavorite
        progress.updatedAt = Date()
        
        if progress.createdAt == nil {
            progress.createdAt = Date()
            progress.id = UUID()
        }
        
        save()
    }
    
    func getAllProgress(userId: String = "default-user") -> [LocalUserProgress] {
        let request: NSFetchRequest<LocalUserProgress> = LocalUserProgress.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@", userId)
        request.sortDescriptors = [NSSortDescriptor(key: "lastPlayedAt", ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch all progress: \(error)")
            return []
        }
    }
    
    func getRecentlyPlayed(limit: Int = 5, userId: String = "default-user") -> [LocalUserProgress] {
        let request: NSFetchRequest<LocalUserProgress> = LocalUserProgress.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@ AND lastPlayedAt != nil", userId)
        request.sortDescriptors = [NSSortDescriptor(key: "lastPlayedAt", ascending: false)]
        request.fetchLimit = limit
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch recently played: \(error)")
            return []
        }
    }
    
    func getCompletedStories(userId: String = "default-user") -> [LocalUserProgress] {
        let request: NSFetchRequest<LocalUserProgress> = LocalUserProgress.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@ AND isCompleted == true", userId)
        request.sortDescriptors = [NSSortDescriptor(key: "completedAt", ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch completed stories: \(error)")
            return []
        }
    }
    
    func getFavoriteStories(userId: String = "default-user") -> [LocalUserProgress] {
        let request: NSFetchRequest<LocalUserProgress> = LocalUserProgress.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@ AND isFavorite == true", userId)
        request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch favorite stories: \(error)")
            return []
        }
    }
    
    // MARK: - User Settings Methods
    
    func getUserSettings(userId: String = "default-user") -> UserSettings {
        let request: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@", userId)
        request.fetchLimit = 1
        
        do {
            if let settings = try context.fetch(request).first {
                return settings
            }
        } catch {
            print("Failed to fetch user settings: \(error)")
        }
        
        // Create default settings if none exist
        let settings = UserSettings(context: context)
        settings.id = UUID()
        settings.userId = userId
        settings.autoPlay = true
        settings.playbackSpeed = 1.0
        settings.skipSilence = false
        
        save()
        return settings
    }
    
    func updateUserSettings(
        userId: String = "default-user",
        autoPlay: Bool? = nil,
        playbackSpeed: Float? = nil,
        skipSilence: Bool? = nil,
        preferredGradeLevel: String? = nil
    ) {
        let settings = getUserSettings(userId: userId)
        
        if let autoPlay = autoPlay {
            settings.autoPlay = autoPlay
        }
        if let playbackSpeed = playbackSpeed {
            settings.playbackSpeed = playbackSpeed
        }
        if let skipSilence = skipSilence {
            settings.skipSilence = skipSilence
        }
        settings.preferredGradeLevel = preferredGradeLevel
        
        save()
    }
    
    // MARK: - Achievement Methods
    
    func addAchievement(achievementId: String, userId: String = "default-user") {
        // Check if already earned
        let request: NSFetchRequest<UserAchievement> = UserAchievement.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@ AND achievementId == %@", userId, achievementId)
        request.fetchLimit = 1
        
        do {
            if try context.fetch(request).first != nil {
                return // Already earned
            }
        } catch {
            print("Failed to check achievement: \(error)")
        }
        
        let achievement = UserAchievement(context: context)
        achievement.id = UUID()
        achievement.userId = userId
        achievement.achievementId = achievementId
        achievement.dateEarned = Date()
        
        save()
    }
    
    func getAchievements(userId: String = "default-user") -> [UserAchievement] {
        let request: NSFetchRequest<UserAchievement> = UserAchievement.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@", userId)
        request.sortDescriptors = [NSSortDescriptor(key: "dateEarned", ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch achievements: \(error)")
            return []
        }
    }
    
    // MARK: - Statistics
    
    func getUserStatistics(userId: String = "default-user") -> UserStatistics {
        let allProgress = getAllProgress(userId: userId)
        
        let totalStoriesListened = allProgress.count
        let completedStories = allProgress.filter { $0.isCompleted }.count
        let favoriteStories = allProgress.filter { $0.isFavorite }.count
        let totalListeningTime = allProgress.reduce(0) { $0 + Int($1.totalListeningTime) }
        
        // Calculate current streak
        let calendar = Calendar.current
        var currentStreak = 0
        var lastDate: Date? = nil
        
        let sortedProgress = allProgress.sorted { ($0.lastPlayedAt ?? Date.distantPast) > ($1.lastPlayedAt ?? Date.distantPast) }
        
        for progress in sortedProgress {
            guard let playedDate = progress.lastPlayedAt else { continue }
            
            if let lastDate = lastDate {
                let daysBetween = calendar.dateComponents([.day], from: playedDate, to: lastDate).day ?? 0
                
                if daysBetween == 1 {
                    currentStreak += 1
                } else if daysBetween > 1 {
                    break
                }
            } else {
                // First story, check if it's today or yesterday
                let daysFromToday = calendar.dateComponents([.day], from: playedDate, to: Date()).day ?? 0
                if daysFromToday <= 1 {
                    currentStreak = 1
                }
            }
            
            lastDate = playedDate
        }
        
        return UserStatistics(
            totalStoriesListened: totalStoriesListened,
            completedStories: completedStories,
            favoriteStories: favoriteStories,
            totalListeningTime: totalListeningTime,
            currentStreak: currentStreak
        )
    }
}

// MARK: - User Statistics

struct UserStatistics {
    let totalStoriesListened: Int
    let completedStories: Int
    let favoriteStories: Int
    let totalListeningTime: Int // in seconds
    let currentStreak: Int
    
    var formattedListeningTime: String {
        let hours = totalListeningTime / 3600
        let minutes = (totalListeningTime % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Core Data Entities

extension LocalUserProgress {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<LocalUserProgress> {
        return NSFetchRequest<LocalUserProgress>(entityName: "LocalUserProgress")
    }
}

extension UserSettings {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserSettings> {
        return NSFetchRequest<UserSettings>(entityName: "UserSettings")
    }
}

extension UserAchievement {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserAchievement> {
        return NSFetchRequest<UserAchievement>(entityName: "UserAchievement")
    }
}