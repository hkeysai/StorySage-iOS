//
//  StorySageApp.swift
//  StorySage
//
//  Created on 2025-08-03.
//

import SwiftUI
import AVFoundation

@main
struct StorySageApp: App {
    @StateObject private var router = NavigationRouter()
    @StateObject private var audioPlayer = LocalAudioPlayer()
    
    init() {
        setupAudioSession()
        setupAppearance()
        NotificationManager.shared.setupNotificationCategories()
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $router.path) {
                HomeView()
                    .withNavigationDestinations()
            }
            .environmentObject(router)
            .environmentObject(audioPlayer)
            .onAppear {
                Task {
                    await NotificationManager.shared.requestAuthorization()
                }
            }
        }
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .spokenAudio,
                options: [.allowAirPlay, .allowBluetooth, .allowBluetoothA2DP]
            )
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func setupAppearance() {
        // Navigation bar appearance
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor.systemBackground
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        
        // Tab bar appearance (for future use)
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithDefaultBackground()
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    }
}