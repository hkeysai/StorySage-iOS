//
//  AudioPlayer.swift
//  StorySage
//
//  Created on 2025-08-03.
//

import Foundation
import AVFoundation
import MediaPlayer
import Combine

// MARK: - Audio Player

@MainActor
class AudioPlayer: NSObject, ObservableObject {
    
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
        
        // First try to load from cache
        if let audioUrl = story.audioUrl,
           let cachedURL = AudioCacheManager.shared.getCachedFileURL(for: audioUrl) {
            await loadAudio(from: cachedURL)
        } else if let audioUrl = story.audioUrl,
                  let url = URL(string: audioUrl) {
            // Load from remote URL
            await loadAudio(from: url)
        } else {
            error = .invalidURL
            isLoading = false
        }
    }
    
    func play() {
        guard let player = player else { return }
        
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            player.play()
            player.rate = playbackRate
            isPlaying = true
        } catch {
            self.error = .playbackFailed(error)
        }
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
    }
    
    func stop() {
        player?.pause()
        player?.seek(to: .zero)
        isPlaying = false
        currentTime = 0
        updateNowPlayingInfo()
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
            }
        }
    }
    
    private func stopTimeObserver() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
    }
    
    private func handlePlaybackEnd() {
        Task { @MainActor in
            isPlaying = false
            currentTime = duration
            updateNowPlayingInfo()
            
            // Mark story as completed if we have a current story
            if let story = currentStory {
                await savePlaybackProgress(for: story, isCompleted: true)
            }
        }
    }
    
    private func savePlaybackProgress(for story: Story, isCompleted: Bool) async {
        // TODO: Implement progress saving with user ID
        // This would typically save to Core Data and sync with the server
        do {
            try await NetworkManager.shared.updateProgress(
                userId: "current-user", // TODO: Get actual user ID
                storyId: story.id,
                playbackPosition: Int(currentTime),
                isCompleted: isCompleted
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
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = story.category.capitalized
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? playbackRate : 0.0
        
        // Add artwork if available
        // TODO: Load story artwork/thumbnail
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
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
    case playbackFailed(Error)
    case downloadFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid audio URL"
        case .playbackFailed(let error):
            return "Playback failed: \(error.localizedDescription)"
        case .downloadFailed(let error):
            return "Download failed: \(error.localizedDescription)"
        }
    }
}