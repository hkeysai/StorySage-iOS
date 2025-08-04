//
//  LocalAudioPlayer.swift
//  StorySage
//
//  Created on 2025-08-03.
//
//  Audio player optimized for playing bundled MP3 files
//  No network dependencies - all audio is embedded in the app

import Foundation
import AVFoundation
import MediaPlayer
import Combine

// MARK: - Local Audio Player

@MainActor
class LocalAudioPlayer: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var currentStory: Story?
    @Published var playbackRate: Float = 1.0
    @Published var isLoading = false
    @Published var error: AudioError?
    
    // MARK: - Private Properties
    
    private var player: AVPlayer?
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }
    
    var formattedCurrentTime: String {
        return formatTime(currentTime)
    }
    
    var formattedDuration: String {
        return formatTime(duration)
    }
    
    var formattedRemainingTime: String {
        let remaining = max(0, duration - currentTime)
        return "-\(formatTime(remaining))"
    }
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupAudioSession()
        setupRemoteCommandCenter()
        setupNotifications()
    }
    
    func cleanup() {
        stopTimeObserver()
        player?.pause()
        player = nil
        try? AVAudioSession.sharedInstance().setActive(false)
    }
    
    // MARK: - Public Methods
    
    func loadStory(_ story: Story) async {
        currentStory = story
        isLoading = true
        error = nil
        
        // Load from app bundle
        guard let audioUrl = story.audioUrl else {
            error = .invalidURL
            isLoading = false
            return
        }
        
        // Remove .mp3 extension if present for bundle lookup
        let resourceName = audioUrl.replacingOccurrences(of: ".mp3", with: "")
        
        // Try different possible paths
        let possiblePaths = [nil, "Audio", "Resources/Audio"]
        var bundleURL: URL? = nil
        
        for path in possiblePaths {
            if let url = Bundle.main.url(forResource: resourceName, withExtension: "mp3", subdirectory: path) {
                bundleURL = url
                print("✅ Found audio file in path: \(path ?? "root bundle")")
                break
            }
        }
        
        guard let audioURL = bundleURL else {
            error = .audioNotFound(audioUrl)
            isLoading = false
            print("❌ Audio file not found in bundle: \(audioUrl)")
            
            // List available MP3 files for debugging
            if let urls = Bundle.main.urls(forResourcesWithExtension: "mp3", subdirectory: nil) {
                print("📁 Available MP3 files in bundle: \(urls.count)")
                for url in urls.prefix(5) {
                    print("  - \(url.lastPathComponent)")
                }
            }
            return
        }
        
        print("✅ Loading audio from bundle: \(audioURL.lastPathComponent)")
        await loadAudio(from: audioURL)
    }
    
    func play() {
        guard let player = player else { return }
        
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            player.play()
            player.rate = playbackRate
            isPlaying = true
            
            // Save last played story
            UserDefaults.standard.set(currentStory?.id, forKey: "lastPlayedStoryId")
        } catch {
            self.error = .playbackFailed(error)
        }
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
        savePlaybackPosition()
    }
    
    func stop() {
        player?.pause()
        player?.seek(to: .zero)
        isPlaying = false
        currentTime = 0
        updateNowPlayingInfo()
        savePlaybackPosition()
    }
    
    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime)
        currentTime = time
        updateNowPlayingInfo()
    }
    
    func seekForward(_ seconds: TimeInterval = 15) {
        let newTime = min(currentTime + seconds, duration)
        seek(to: newTime)
    }
    
    func seekBackward(_ seconds: TimeInterval = 15) {
        let newTime = max(currentTime - seconds, 0)
        seek(to: newTime)
    }
    
    func setPlaybackRate(_ rate: Float) {
        playbackRate = rate
        if isPlaying {
            player?.rate = rate
        }
    }
    
    // MARK: - Private Methods
    
    private func loadAudio(from url: URL) async {
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        // Observe player item status
        playerItem.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self = self else { return }
                
                switch status {
                case .readyToPlay:
                    self.isLoading = false
                    self.duration = playerItem.duration.seconds
                    self.setupTimeObserver()
                    self.updateNowPlayingInfo()
                    
                    // Restore playback position if available
                    if let storyId = self.currentStory?.id,
                       let savedPosition = UserDefaults.standard.object(forKey: "position_\(storyId)") as? Double,
                       savedPosition > 0 && savedPosition < self.duration {
                        self.seek(to: savedPosition)
                    }
                    
                case .failed:
                    self.isLoading = false
                    if let error = playerItem.error {
                        self.error = .playbackFailed(error)
                    }
                    
                case .unknown:
                    break
                    
                @unknown default:
                    break
                }
            }
            .store(in: &cancellables)
        
        // Observe playback end
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handlePlaybackEnd()
            }
            .store(in: &cancellables)
    }
    
    private func setupTimeObserver() {
        stopTimeObserver()
        
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor in
                self?.currentTime = time.seconds
                self?.updateNowPlayingInfo()
                
                // Save position every 5 seconds
                if Int(time.seconds) % 5 == 0 {
                    self?.savePlaybackPosition()
                }
            }
        }
    }
    
    private func stopTimeObserver() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
    }
    
    private func savePlaybackPosition() {
        guard let storyId = currentStory?.id else { return }
        UserDefaults.standard.set(currentTime, forKey: "position_\(storyId)")
    }
    
    private func handlePlaybackEnd() {
        Task { @MainActor in
            isPlaying = false
            currentTime = duration
            updateNowPlayingInfo()
            
            // Mark story as completed
            if let story = currentStory {
                await markStoryCompleted(story)
            }
        }
    }
    
    private func markStoryCompleted(_ story: Story) async {
        // Update local progress
        do {
            try await LocalDataProvider.shared.updateProgress(
                userId: DeviceIdManager.shared.deviceId,
                storyId: story.id,
                playbackPosition: Int(duration),
                isCompleted: true
            )
            
            // Clear saved position
            UserDefaults.standard.removeObject(forKey: "position_\(story.id)")
            
            // Show achievement notification
            await NotificationManager.shared.scheduleAchievementNotification(
                title: "Story Completed! 🎉",
                body: "Great job finishing \(story.title)!",
                achievementId: "story_completed_\(story.id)"
            )
        } catch {
            print("Failed to save progress: \(error)")
        }
    }
    
    // MARK: - Audio Session Setup
    
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
    
    // MARK: - Remote Command Center
    
    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Play command
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }
        
        // Pause command
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }
        
        // Skip forward command
        commandCenter.skipForwardCommand.preferredIntervals = [15]
        commandCenter.skipForwardCommand.addTarget { [weak self] event in
            if let skipEvent = event as? MPSkipIntervalCommandEvent {
                self?.seekForward(skipEvent.interval)
            } else {
                self?.seekForward()
            }
            return .success
        }
        
        // Skip backward command
        commandCenter.skipBackwardCommand.preferredIntervals = [15]
        commandCenter.skipBackwardCommand.addTarget { [weak self] event in
            if let skipEvent = event as? MPSkipIntervalCommandEvent {
                self?.seekBackward(skipEvent.interval)
            } else {
                self?.seekBackward()
            }
            return .success
        }
        
        // Change playback position command
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            if let positionEvent = event as? MPChangePlaybackPositionCommandEvent {
                self?.seek(to: positionEvent.positionTime)
            }
            return .success
        }
    }
    
    // MARK: - Now Playing Info
    
    private func updateNowPlayingInfo() {
        guard let story = currentStory else { return }
        
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = story.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = "StorySage"
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = getCategoryName(for: story.category)
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? playbackRate : 0.0
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    private func getCategoryName(for categoryId: String) -> String {
        switch categoryId {
        case "firefly-forest": return "Firefly Forest"
        case "rainbow-rapids": return "Rainbow Rapids"
        case "thunder-mountain": return "Thunder Mountain"
        case "starlight-meadow": return "Starlight Meadow"
        case "compass-cliff": return "Compass Cliff"
        default: return "StorySage"
        }
    }
    
    // MARK: - Notifications
    
    private func setupNotifications() {
        NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleAudioInterruption(notification)
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: AVAudioSession.routeChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleRouteChange(notification)
            }
            .store(in: &cancellables)
    }
    
    private func handleAudioInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            pause()
            
        case .ended:
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                play()
            }
            
        @unknown default:
            break
        }
    }
    
    private func handleRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        switch reason {
        case .oldDeviceUnavailable:
            // Headphones were unplugged
            pause()
            
        default:
            break
        }
    }
    
    // MARK: - Utility Methods
    
    private func formatTime(_ time: TimeInterval) -> String {
        guard time.isFinite && !time.isNaN else { return "0:00" }
        
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Audio Error

enum AudioError: Error, LocalizedError {
    case invalidURL
    case audioNotFound(String)
    case playbackFailed(Error)
    case fileNotFound
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid audio URL"
        case .audioNotFound(let fileName):
            return "Audio file not found: \(fileName)"
        case .playbackFailed(let error):
            return "Playback failed: \(error.localizedDescription)"
        case .fileNotFound:
            return "Audio file not found in bundle"
        }
    }
}
