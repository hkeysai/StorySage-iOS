//
//  HomeView.swift
//  StorySage
//
//  Created on 2025-08-03.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = LocalHomeViewModel()
    @EnvironmentObject var router: NavigationRouter
    @EnvironmentObject var audioPlayer: LocalAudioPlayer
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection
                
                // Grade Level Selection
                gradeLevelSection
                
                // Featured Story (if available)
                if let featuredStory = viewModel.featuredStory {
                    featuredStorySection(featuredStory)
                }
                
                // Categories
                categoriesSection
                
                // Continue Listening (if available)
                if let lastStory = viewModel.lastPlayedStory {
                    continueListeningSection(lastStory)
                }
                
                // Recent Stories
                if !viewModel.recentStories.isEmpty {
                    recentStoriesSection
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100) // Space for mini player
        }
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationTitle("StorySage")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            await viewModel.refreshData()
        }
        .task {
            await viewModel.loadInitialData()
        }
        .overlay(alignment: .bottom) {
            if audioPlayer.currentStory != nil {
                MiniPlayerView()
                    .padding(.horizontal, 16)
                    .padding(.bottom, 34)
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Good \(timeOfDayGreeting)!")
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    Text("Ready for an adventure?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    router.navigate(to: .profile)
                }) {
                    Image(systemName: "person.circle.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                }
            }
            
            // Quick stats
            if viewModel.userProgress.totalStoriesListened > 0 {
                HStack(spacing: 20) {
                    StatView(
                        icon: "book.fill",
                        value: "\(viewModel.userProgress.totalStoriesListened)",
                        label: "Stories"
                    )
                    
                    StatView(
                        icon: "clock.fill",
                        value: viewModel.userProgress.formattedTotalListeningTime,
                        label: "Listening"
                    )
                    
                    StatView(
                        icon: "flame.fill",
                        value: "\(viewModel.userProgress.currentStreak)",
                        label: "Day Streak"
                    )
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
        }
    }
    
    // MARK: - Grade Level Section
    
    private var gradeLevelSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose Your Grade")
                .font(.headline)
                .fontWeight(.semibold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(GradeLevel.allCases, id: \.self) { grade in
                        GradeLevelCard(
                            grade: grade,
                            isSelected: viewModel.selectedGradeLevel == grade
                        ) {
                            viewModel.selectGradeLevel(grade)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.horizontal, -20)
        }
    }
    
    // MARK: - Featured Story Section
    
    private func featuredStorySection(_ story: Story) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Featured Story")
                .font(.headline)
                .fontWeight(.semibold)
            
            FeaturedStoryCard(story: story) {
                router.navigate(to: .storyDetail(story))
            }
        }
    }
    
    // MARK: - Categories Section
    
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Adventure Areas")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(viewModel.filteredCategories) { category in
                    CategoryCard(category: category) {
                        router.navigate(to: .categoryStories(category))
                    }
                }
            }
        }
    }
    
    // MARK: - Continue Listening Section
    
    private func continueListeningSection(_ story: Story) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Continue Listening")
                .font(.headline)
                .fontWeight(.semibold)
            
            ContinueListeningCard(story: story) {
                router.navigate(to: .storyDetail(story))
            }
        }
    }
    
    // MARK: - Recent Stories Section
    
    private var recentStoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recently Played")
                .font(.headline)
                .fontWeight(.semibold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.recentStories) { story in
                        StoryCard(story: story) {
                            router.navigate(to: .storyDetail(story))
                        }
                        .frame(width: 160)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.horizontal, -20)
        }
    }
    
    // MARK: - Helper Properties
    
    private var timeOfDayGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "morning"
        case 12..<17:
            return "afternoon"
        case 17..<22:
            return "evening"
        default:
            return "night"
        }
    }
}

// MARK: - Supporting Views

struct StatView: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct GradeLevelCard: View {
    let grade: GradeLevel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: grade.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : grade.color)
                
                Text(grade.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(grade.ageRange)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .frame(width: 100, height: 100)
            .background(isSelected ? grade.color : Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .environmentObject(NavigationRouter())
            .environmentObject(LocalAudioPlayer())
    }
}