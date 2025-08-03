//
//  MiniPlayerView.swift
//  StorySage
//
//  Created on 2025-08-03.
//

import SwiftUI

struct MiniPlayerView: View {
    @EnvironmentObject var audioPlayer: AudioPlayer
    @EnvironmentObject var router: NavigationRouter
    @State private var isExpanded = false
    
    var body: some View {
        if let story = audioPlayer.currentStory {
            VStack(spacing: 0) {
                // Mini Player Bar
                HStack(spacing: 12) {
                    // Story Artwork
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient(
                            colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "book.fill")
                                .font(.caption)
                                .foregroundColor(.white)
                        )
                    
                    // Story Info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(story.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1)
                        
                        Text(audioPlayer.formattedCurrentTime + " / " + audioPlayer.formattedDuration)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Play/Pause Button
                    Button(action: {
                        if audioPlayer.isPlaying {
                            audioPlayer.pause()
                        } else {
                            audioPlayer.play()
                        }
                    }) {
                        Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title3)
                            .foregroundColor(.primary)
                    }
                    
                    // Expand Button
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                .onTapGesture {
                    router.navigate(to: .storyDetail(story))
                }
                
                // Expanded Controls
                if isExpanded {
                    VStack(spacing: 16) {
                        // Progress Bar
                        VStack(spacing: 8) {
                            ProgressView(value: audioPlayer.progress)
                                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            
                            HStack {
                                Text(audioPlayer.formattedCurrentTime)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text(audioPlayer.formattedRemainingTime)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        // Playback Controls
                        HStack(spacing: 24) {
                            // Skip Backward
                            Button(action: {
                                audioPlayer.seekBackward()
                            }) {
                                Image(systemName: "gobackward.15")
                                    .font(.title2)
                                    .foregroundColor(.primary)
                            }
                            
                            Spacer()
                            
                            // Play/Pause
                            Button(action: {
                                if audioPlayer.isPlaying {
                                    audioPlayer.pause()
                                } else {
                                    audioPlayer.play()
                                }
                            }) {
                                Image(systemName: audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                    .font(.system(size: 44))
                                    .foregroundColor(.blue)
                            }
                            
                            Spacer()
                            
                            // Skip Forward
                            Button(action: {
                                audioPlayer.seekForward()
                            }) {
                                Image(systemName: "goforward.15")
                                    .font(.title2)
                                    .foregroundColor(.primary)
                            }
                        }
                        .padding(.horizontal, 32)
                        
                        // Playback Speed Control
                        HStack {
                            Text("Speed:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            HStack(spacing: 8) {
                                ForEach([0.75, 1.0, 1.25, 1.5], id: \.self) { speed in
                                    Button(action: {
                                        audioPlayer.setPlaybackRate(Float(speed))
                                    }) {
                                        Text("\(speed, specifier: "%.2g")×")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(audioPlayer.playbackRate == Float(speed) ? Color.blue : Color.gray.opacity(0.2))
                                            .foregroundColor(audioPlayer.playbackRate == Float(speed) ? .white : .primary)
                                            .cornerRadius(6)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        // Actions
                        HStack(spacing: 24) {
                            Button(action: {
                                router.navigate(to: .storyDetail(story))
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: "info.circle")
                                        .font(.title3)
                                    Text("Details")
                                        .font(.caption2)
                                }
                                .foregroundColor(.primary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                // TODO: Toggle favorite
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: "heart")
                                        .font(.title3)
                                    Text("Favorite")
                                        .font(.caption2)
                                }
                                .foregroundColor(.primary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                audioPlayer.stop()
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: "xmark.circle")
                                        .font(.title3)
                                    Text("Close")
                                        .font(.caption2)
                                }
                                .foregroundColor(.red)
                            }
                        }
                        .padding(.horizontal, 32)
                        .padding(.bottom, 16)
                    }
                    .background(Color(.systemBackground))
                }
            }
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: -2)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

#Preview {
    VStack {
        Spacer()
        MiniPlayerView()
            .environmentObject({
                let player = AudioPlayer()
                Task {
                    await player.loadStory(Story.sampleStory)
                }
                return player
            }())
            .environmentObject(NavigationRouter())
            .padding()
    }
}