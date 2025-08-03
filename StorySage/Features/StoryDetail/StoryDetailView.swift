//
//  StoryDetailView.swift
//  StorySage
//
//  Created on 2025-08-03.
//

import SwiftUI

struct StoryDetailView: View {
    let story: Story
    
    @StateObject private var viewModel: StoryDetailViewModel
    @EnvironmentObject var router: NavigationRouter
    @EnvironmentObject var audioPlayer: LocalAudioPlayer
    @State private var showingShareSheet = false
    
    init(story: Story) {
        self.story = story
        self._viewModel = StateObject(wrappedValue: StoryDetailViewModel(story: story))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Story Header
                storyHeader
                
                // Audio Player Controls
                audioPlayerSection
                
                // Story Details
                storyDetailsSection
                
                // Key Lessons
                if !story.keyLessons.isEmpty {
                    keyLessonsSection
                }
                
                // Story Segments
                if !story.segments.isEmpty {
                    segmentsSection
                }
                
                // Actions
                actionsSection
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100) // Space for mini player
        }
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.05), Color.purple.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationTitle(story.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button(action: {
                        viewModel.toggleFavorite()
                    }) {
                        Image(systemName: viewModel.isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(viewModel.isFavorite ? .red : .gray)
                    }
                    
                    Button(action: {
                        showingShareSheet = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .task {
            await viewModel.loadStoryDetails()
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [story.title, story.description])
        }
    }
    
    // MARK: - Story Header
    
    private var storyHeader: some View {
        VStack(spacing: 16) {
            // Story Artwork Placeholder
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(
                    colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 200, height: 200)
                .overlay(
                    Image(systemName: "book.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                )
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            
            VStack(spacing: 8) {
                Text(story.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(story.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                
                HStack(spacing: 16) {
                    Label(story.gradeLevelDisplayName, systemImage: "graduationcap.fill")
                    Label(story.formattedDuration, systemImage: "clock.fill")
                    Label(story.category.capitalized, systemImage: "tag.fill")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Audio Player Section
    
    private var audioPlayerSection: some View {
        VStack(spacing: 16) {
            // Main Play Button
            Button(action: {
                if audioPlayer.currentStory?.id == story.id && audioPlayer.isPlaying {
                    audioPlayer.pause()
                } else {
                    Task {
                        await audioPlayer.loadStory(story)
                        audioPlayer.play()
                    }
                }
            }) {
                HStack {
                    Image(systemName: audioPlayer.currentStory?.id == story.id && audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title2)
                    
                    Text(audioPlayer.currentStory?.id == story.id && audioPlayer.isPlaying ? "Pause" : "Play Story")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(audioPlayer.isLoading)
            
            // Download Button
            if let audioUrl = story.audioUrl {
                Button(action: {
                    Task {
                        await viewModel.downloadStory()
                    }
                }) {
                    HStack {
                        if viewModel.isDownloading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: story.isDownloaded ? "checkmark.circle.fill" : "arrow.down.circle")
                        }
                        
                        Text(story.isDownloaded ? "Downloaded" : "Download for Offline")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(story.isDownloaded ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                    .foregroundColor(story.isDownloaded ? .green : .primary)
                    .cornerRadius(8)
                }
                .disabled(story.isDownloaded || viewModel.isDownloading)
            }
            
            // Progress Bar (if story is playing or has been played)
            if audioPlayer.currentStory?.id == story.id || viewModel.hasProgress {
                VStack(spacing: 8) {
                    ProgressView(value: audioPlayer.currentStory?.id == story.id ? audioPlayer.progress : viewModel.progressPercentage)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    
                    HStack {
                        Text(audioPlayer.currentStory?.id == story.id ? audioPlayer.formattedCurrentTime : viewModel.formattedProgress)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(story.formattedDuration)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Story Details Section
    
    private var storyDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About This Story")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(story.description)
                .font(.body)
                .foregroundColor(.secondary)
            
            // Tags
            if !story.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(story.tags, id: \.self) { tag in
                            Text(tag.capitalized)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(6)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.horizontal, -20)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Key Lessons Section
    
    private var keyLessonsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What Your Child Will Learn")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(story.keyLessons.enumerated()), id: \.offset) { index, lesson in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                            .padding(.top, 2)
                        
                        Text(lesson)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Segments Section
    
    private var segmentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Story Chapters")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ForEach(story.segments.sorted(by: { $0.order < $1.order })) { segment in
                    SegmentRow(segment: segment, isPlaying: false) {
                        // TODO: Implement segment-specific playback
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                viewModel.toggleFavorite()
            }) {
                HStack {
                    Image(systemName: viewModel.isFavorite ? "heart.fill" : "heart")
                    Text(viewModel.isFavorite ? "Remove from Favorites" : "Add to Favorites")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.gray.opacity(0.2))
                .foregroundColor(.primary)
                .cornerRadius(8)
            }
            
            Button(action: {
                showingShareSheet = true
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Story")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.gray.opacity(0.2))
                .foregroundColor(.primary)
                .cornerRadius(8)
            }
        }
    }
}

// MARK: - Segment Row

struct SegmentRow: View {
    let segment: StorySegment
    let isPlaying: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(segment.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("\(segment.duration / 60):\(String(format: "%02d", segment.duration % 60))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title3)
                    .foregroundColor(.blue)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        return UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        StoryDetailView(story: Story.sampleStory)
            .environmentObject(NavigationRouter())
            .environmentObject(LocalAudioPlayer())
    }
}