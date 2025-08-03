//
//  NotificationManager.swift
//  StorySage
//
//  Created on 2025-08-03.
//

import Foundation
import UserNotifications

// MARK: - Notification Manager

class NotificationManager {
    static let shared = NotificationManager()
    
    private let center = UNUserNotificationCenter.current()
    
    private init() {}
    
    // MARK: - Setup
    
    func setupNotificationCategories() {
        // Achievement notification category
        let achievementAction = UNNotificationAction(
            identifier: "VIEW_ACHIEVEMENT",
            title: "View Achievement",
            options: [.foreground]
        )
        
        let achievementCategory = UNNotificationCategory(
            identifier: "ACHIEVEMENT",
            actions: [achievementAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Story recommendation category
        let listenAction = UNNotificationAction(
            identifier: "LISTEN_STORY",
            title: "Listen Now",
            options: [.foreground]
        )
        
        let recommendationCategory = UNNotificationCategory(
            identifier: "STORY_RECOMMENDATION",
            actions: [listenAction],
            intentIdentifiers: [],
            options: []
        )
        
        center.setNotificationCategories([achievementCategory, recommendationCategory])
    }
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("Failed to request notification authorization: \(error)")
            return false
        }
    }
    
    // MARK: - Achievement Notifications
    
    func scheduleAchievementNotification(
        title: String,
        body: String,
        achievementId: String
    ) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "ACHIEVEMENT"
        content.userInfo = [
            "type": "achievement",
            "achievementId": achievementId
        ]
        
        // Schedule immediately
        let request = UNNotificationRequest(
            identifier: "achievement_\(achievementId)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        do {
            try await center.add(request)
        } catch {
            print("Failed to schedule achievement notification: \(error)")
        }
    }
    
    // MARK: - Story Recommendations
    
    func scheduleStoryRecommendation(
        story: Story,
        delay: TimeInterval = 0
    ) async {
        let content = UNMutableNotificationContent()
        content.title = "New Story Available!"
        content.body = "Check out \"\(story.title)\" - perfect for your child's learning journey."
        content.sound = .default
        content.categoryIdentifier = "STORY_RECOMMENDATION"
        content.userInfo = [
            "type": "story_recommendation",
            "storyId": story.id
        ]
        
        let trigger = delay > 0 ? UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false) : nil
        
        let request = UNNotificationRequest(
            identifier: "story_recommendation_\(story.id)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
        } catch {
            print("Failed to schedule story recommendation: \(error)")
        }
    }
    
    // MARK: - Daily Reminders
    
    func scheduleDailyReminder(hour: Int = 19, minute: Int = 0) async {
        let content = UNMutableNotificationContent()
        content.title = "Story Time!"
        content.body = "It's time for your daily story adventure. What will you discover today?"
        content.sound = .default
        content.userInfo = [
            "type": "daily_reminder"
        ]
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "daily_reminder",
            content: content,
            trigger: trigger
        )
        
        do {
            // Remove any existing daily reminder
            center.removePendingNotificationRequests(withIdentifiers: ["daily_reminder"])
            try await center.add(request)
        } catch {
            print("Failed to schedule daily reminder: \(error)")
        }
    }
    
    // MARK: - Streak Notifications
    
    func scheduleStreakCelebration(streakCount: Int) async {
        guard streakCount > 1 else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "🔥 Amazing Streak!"
        content.body = "You've listened to stories for \(streakCount) days in a row! Keep it up!"
        content.sound = .default
        content.userInfo = [
            "type": "streak_celebration",
            "streakCount": streakCount
        ]
        
        let request = UNNotificationRequest(
            identifier: "streak_\(streakCount)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        do {
            try await center.add(request)
        } catch {
            print("Failed to schedule streak notification: \(error)")
        }
    }
    
    // MARK: - Download Completion
    
    func scheduleDownloadCompletionNotification(storyTitle: String) async {
        let content = UNMutableNotificationContent()
        content.title = "Download Complete"
        content.body = "\"\(storyTitle)\" is now available for offline listening!"
        content.sound = .default
        content.userInfo = [
            "type": "download_complete"
        ]
        
        let request = UNNotificationRequest(
            identifier: "download_complete_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        do {
            try await center.add(request)
        } catch {
            print("Failed to schedule download notification: \(error)")
        }
    }
    
    // MARK: - Utility Methods
    
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }
    
    func cancelNotifications(withIdentifiers identifiers: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }
    
    func getAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }
    
    func getPendingNotificationCount() async -> Int {
        let requests = await center.pendingNotificationRequests()
        return requests.count
    }
}